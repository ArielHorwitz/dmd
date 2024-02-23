#! /bin/bash
set -e

CONFIG_DIR="$HOME/.config/openassistant"
MODEL_SETTINGS_FILE="$CONFIG_DIR/model_settings"
HISTORY_DIR="$HOME/.local/share/openassistant/history"
KEY_FILE="$CONFIG_DIR/apikey"
SYSTEM_INSTRUCTIONS_FILE="$CONFIG_DIR/system_instructions"
TOTAL_USAGE_FILE="$CONFIG_DIR/usage"

API_URL="https://api.openai.com/v1/chat/completions"
# Token costs are denominated in USD per token
TOKEN_COST_PROMPT=0.00001
TOKEN_COST_RESPONSE=0.00003

DEFAULT_MODEL_SETTINGS='
model: "gpt-4-turbo-preview"
max_tokens: 4096
temperature: 1.0
top_p: 1.0
frequency_penalty: .05
presence_penalty: .01
'

APP_NAME=$(basename "$0")
ABOUT='Query your personal OpenAI assistant.

See configuration folder (--config-dir) for options. For more details see: https://platform.openai.com/docs/api-reference/chat.'
CLI=(
    --prefix "args_"
    -O "historical;Show conversation from history;;H"
    -O "history;History mode: (d)isable, (a)uto, (n)ame ;a;y"
    -f "list;List conversations from history and exit;;l"
    -f "show-usage;Show usage stats and exit;;u"
    -f "config-dir;Show configuration directory path and exit;;c"
    -f "quiet;Only print the response (overrides --verbose);;q"
    -f "verbose;Show debugging details;;v"
    -f "read-stdin;Read from stdin instead of open an editor;;R"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $args_quiet ]] || args_verbose=

case $args_history in
    d | disable  ) history_enabled= ;;
    a | auto     ) history_enabled=1 ;;
    n | name     ) history_enabled="name" ;;
esac

get_query() {
    if [[ -n $args_read_stdin ]]; then
        tcprint "notice]Reading query from stdin..."
        read query_content
    else
        [[ -n $EDITOR ]] || exit_error "No editor configured (use EDITOR environment variable)"
        if [[ -z $args_historical ]]; then
            [[ -z $args_verbose ]] || tcprint "notice]Reading query from editor: \"$EDITOR\""
            [[ -f $query_file ]] || echo 'Enter your prompt here and then close your editor' > $query_file
            `$EDITOR $query_file` &>/dev/null
        fi
        query_content="$(cat $query_file)"
    fi
}

get_model_setting() {
    local stat_name="$1"
    local line=$(grep -E "^${stat_name}: " $MODEL_SETTINGS_FILE) || exit_error "Missing model setting: $stat_name. Delete $MODEL_SETTINGS_FILE to regenerate defaults."
    printf "%s" "${line#${stat_name}: }"
}

generate_call_data() {
    local json_template='{
    messages: [
        {
            role: "system",
            content: $system_instructions
        },
        {
            role: "user",
            content: $query_content
        }
    ],
    model: $model,
    top_p: $top_p,
    max_tokens: $max_tokens,
    temperature: $temperature,
    frequency_penalty: $frequency_penalty,
    presence_penalty: $presence_penalty
}'
    local jq_args=(
        --arg system_instructions "$system_instructions"
        --arg query_content "$query_content"
        --argjson model $(get_model_setting model)
        --argjson max_tokens $(get_model_setting max_tokens)
        --argjson temperature $(get_model_setting temperature)
        --argjson top_p $(get_model_setting top_p)
        --argjson frequency_penalty $(get_model_setting frequency_penalty)
        --argjson presence_penalty $(get_model_setting presence_penalty)
    )
    api_call_data=$(jq -n "${jq_args[@]}" "$json_template")
}

call_api() {
    local curl_args=(
        "$API_URL"
        --silent --show-error
        -o "$response_file"
        -D "$response_headers_file"
        -H "Content-Type: application/json"
        -H "Authorization: Bearer $openai_api_key"
        -d "$api_call_data"
    )
    tcprint "yellow n]Fetching response..."
    curl "${curl_args[@]}" || :
    printf         '\r                    \r'
}

read_response() {
    if jq -e 'has("error")' "$response_file" >/dev/null; then
        tcprint "yellow bu]Error:"
        jq < "$response_file"
        exit_error "$(jq -r '.error.message' "$response_file")"
    elif jq -e 'has("choices")' "$response_file" >/dev/null; then
        [[ -n $args_quiet ]] || tcprint "info bu]OpenAssistant says:"
        jq -r '.choices.[0].message.content' "$response_file" | bat -pp --language markdown
        if [[ -z $args_quiet ]]; then
            local cost=$(get_usage_stat $usage_file cost)
            local tokens=$(get_usage_stat $usage_file tokens)
            local tokens_prompt=$(get_usage_stat $usage_file tokens_prompt)
            local tokens_response=$(get_usage_stat $usage_file tokens_response)
            local cost_prompt=$(get_usage_stat $usage_file cost_prompt)
            local cost_response=$(get_usage_stat $usage_file cost_response)
            tcprint "info n]$tokens tokens (~\$$cost)"
            tcprint "debug] [prompt: $tokens_prompt (~\$$cost_prompt)] [response: $tokens_response (~\$$cost_response)]"
        fi
    else
        jq < "$response_file"
    fi
}

get_usage_stat() {
    local file="$1"
    local stat_name="$2"
    local default=0
    if [[ -n $3 ]]; then
        local default="$3"
    fi
    local line=$(grep -E "^${stat_name}: " $file || echo "$stat_name: $default")
    echo ${line#${stat_name}: }
}

count_usage() {
    local add_totals="$1"
    local tokens=$(jq '.usage.total_tokens' "$response_file")
    local tokens_prompt=$(jq '.usage.prompt_tokens' "$response_file")
    local tokens_response=$(jq '.usage.completion_tokens' "$response_file")
    local cost_prompt=$(echo "scale=4;$tokens_prompt * $TOKEN_COST_PROMPT" | bc)
    local cost_response=$(echo "scale=4;$tokens_response * $TOKEN_COST_RESPONSE" | bc)
    local cost=$(echo "scale=4;$cost_prompt + $cost_response" | bc)
    echo "Single exchange
cost: $cost
tokens: $tokens
tokens_prompt: $tokens_prompt
tokens_response: $tokens_response
cost_prompt: $cost_prompt
cost_response: $cost_response
" > $usage_file
    if [[ -z $args_historical ]]; then
        echo "TOTALS
start: $(get_usage_stat $TOTAL_USAGE_FILE start `date +%y-%m-%d-%H-%M-%S`)
cost: $(echo $cost + `get_usage_stat $TOTAL_USAGE_FILE cost` | bc)
tokens: $(echo $tokens + `get_usage_stat $TOTAL_USAGE_FILE tokens` | bc)
tokens_prompt: $(echo $tokens_prompt + `get_usage_stat $TOTAL_USAGE_FILE tokens_prompt` | bc)
tokens_response: $(echo $tokens_response + `get_usage_stat $TOTAL_USAGE_FILE tokens_response` | bc)
cost_prompt: $(echo $cost_prompt + `get_usage_stat $TOTAL_USAGE_FILE cost_prompt` | bc)
cost_response: $(echo $cost_response + `get_usage_stat $TOTAL_USAGE_FILE cost_response` | bc)
" > $TOTAL_USAGE_FILE
    fi
}

save_history() {
    local current_date=`date +%y-%m-%d-%H-%M-%S`
    local convo_name=$current_date
    local user_given_convo_name
    if [[ $history_enabled = "name" ]]; then
        tcprint "debug] [Leave blank for auto naming or use '.' to skip saving]"
        tcprint "notice n]Conversation name: "
        read user_given_convo_name
        if [[ user_given_convo_name = "." ]]; then
            return 0
        elif [[ -z $user_given_convo_name ]]; then
            local user_given_convo_name=$(echo $user_given_convo_name | sed 's/ /-/g')
            local convo_name="${current_date}__${user_given_convo_name}"
        fi
    fi
    local convo_dir="$HISTORY_DIR/$convo_name"
    local history_files=(
        "$CONFIG_DIR/system_instructions"
        "$data_dir/query"
        "$data_dir/response"
        "$data_dir/headers_response"
        "$data_dir/usage"
    )
    mkdir --parents $convo_dir
    cp -t $convo_dir ${history_files[@]}
}

print_debug_prequery() {
    tcprint "info bu]Environment:"
    tcprint "debug n]    API key: "; echo "${openai_api_key:0:8}..."
    tcprint "debug n] Config dir: "; echo $CONFIG_DIR
    tcprint "debug n]   Data dir: "; echo $data_dir
    tcprint "info bu]System instructions:"
    tcset "yellow d"
    printf "%s\n" "$system_instructions"
    tcreset
}

print_debug_precall() {
    tcprint "info bu]Request data:"
    echo "$api_call_data" | jq
}

print_query() {
    tcprint "info bu]Query:"
    printf "%s\n" "$query_content" | bat -pp --language markdown
}

print_debug() {
    tcprint "info bu]Response headers:"
    bat "$response_headers_file"
}

list_history() {
    if [[ -d "$HISTORY_DIR" ]]; then
        find "$HISTORY_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort -r
    fi
}

# List history (--list)
if [[ -n $args_list ]]; then
    list_history
    exit 0
elif [[ -n $args_config_dir ]]; then
    echo $CONFIG_DIR
    exit 0
elif [[ -n $args_history_dir ]]; then
    echo $HISTORY_DIR
    exit 0
elif [[ -n $args_show_usage ]]; then
    cat $TOTAL_USAGE_FILE
    exit 0
fi

# Resolve data directory and system instructions file locations
data_dir="$HISTORY_DIR/.last"
system_instructions_file=$SYSTEM_INSTRUCTIONS_FILE
if [[ -n $args_historical ]]; then
    convo_name=$(list_history | grep "$args_historical" -m 1)
    [[ -n $args_quiet ]] || tcprint "notice]Using historical conversation: $convo_name"
    data_dir="$HISTORY_DIR/$convo_name"
fi
# Paths for current conversation
system_instructions_file="$data_dir/system_instructions"
query_file="$data_dir/query"
response_file="$data_dir/response"
response_headers_file="$data_dir/headers_response"
usage_file="$data_dir/usage"

# Create defaults
[[ -d $CONFIG_DIR ]] || mkdir --parents $CONFIG_DIR
[[ -d $data_dir ]] || mkdir --parents $data_dir
[[ -f $MODEL_SETTINGS_FILE ]] || echo "$DEFAULT_MODEL_SETTINGS" > $MODEL_SETTINGS_FILE
[[ -f $TOTAL_USAGE_FILE ]] || touch $TOTAL_USAGE_FILE

# System instructions
[[ -f $system_instructions_file ]] || echo 'You are a helpful assistant.' > $system_instructions_file
system_instructions="$(cat $system_instructions_file)"

# API key
[[ -f $KEY_FILE ]] || exit_error "Missing OpenAI API key file: $KEY_FILE"
openai_api_key="$(cat $KEY_FILE)"
[[ -n $openai_api_key ]] || exit_error "Empty OpenAI API key"

# Get query
[[ -z $args_verbose ]] || print_debug_prequery
get_query
[[ -n $query_content ]] || exit_error "Query content is empty"
generate_call_data
[[ -n $args_quiet ]] || print_query

# Call API
[[ -z $args_verbose ]] || print_debug_precall
[[ -n $args_historical ]] || call_api
count_usage
read_response
[[ -z $history_enabled ]] || save_history

# Debugging
[[ -z $args_verbose ]] || print_debug

