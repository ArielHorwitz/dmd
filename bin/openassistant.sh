#! /bin/bash
set -e

CONFIG_DIR="$HOME/.config/openassistant"
HISTORY_DIR="$HOME/.local/share/openassistant/history"
KEY_FILE="$CONFIG_DIR/apikey"
SYSTEM_INSTRUCTIONS_FILE="$CONFIG_DIR/system_instructions"
TOTAL_USAGE_FILE="$CONFIG_DIR/usage"

API_URL="https://api.openai.com/v1/chat/completions"
# Token costs are denominated in USD per token
TOKEN_COST_PROMPT=0.00001
TOKEN_COST_RESPONSE=0.00003

DEFAULT_MODEL="gpt-4-turbo-preview"
DEFAULT_MAX_TOKENS=2048
DEFAULT_TEMPERATURE=1
DEFAULT_TOP_P=1
DEFAULT_FREQUENCY_PENALTY=0.2
DEFAULT_PRESENCE_PENALTY=0.1

APP_NAME=$(basename "$0")
ABOUT='Query your personal OpenAI assistant.

See the model endpoint compatibility table (https://platform.openai.com/docs/models/model-endpoint-compatibility) for details on which models work with the Chat API at "/v1/chat/completions". For more details about model settings, see (https://platform.openai.com/docs/api-reference/chat).
'
CLI=(
    --prefix "args_"
    -O "model;ID of the model to use;$DEFAULT_MODEL;m"
    -O "max-tokens;Maximum tokens including system instructions, prompt, and response;$DEFAULT_MAX_TOKENS;M"
    -O "temperature;0 to 2 (more random);$DEFAULT_TEMPERATURE"
    -O "top-p;0 to 1 (nucleus sampling);$DEFAULT_TOP_P"
    -O "frequency-penalty;-2.0 to 2.0 (less repetition);$DEFAULT_FREQUENCY_PENALTY"
    -O "presence-penalty;-2.0 to 2.0 (more new topics);$DEFAULT_PRESENCE_PENALTY"
    -O "use-history;Use previous conversation from history;;H"
    -f "list-history;List previous conversations from history and exit;;l"
    -f "show-usage;Show usage stats and exit"
    -f "no-history;Don't save the conversation in history"
    -f "no-name;Don't add a name to the conversation in history"
    -f "quiet;Be quiet (overrides --verbose);;q"
    -f "verbose;Be verbose;;v"
    -f "read-stdin;Read from stdin instead of open an editor;;R"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $args_quiet ]] || args_verbose=
[[ -z $args_use_history ]] || args_no_history=1

get_query() {
    if [[ -n $args_read_stdin ]]; then
        tcprint "notice]Reading query from stdin..."
        read query_content
    else
        [[ -n $EDITOR ]] || exit_error "No editor configured (use EDITOR environment variable)"
        if [[ -z $args_use_history ]]; then
            if [[ -n $args_verbose ]]; then
                tcprint "notice]Reading query from editor: \"$EDITOR\""
            fi
            touch $query_file
            `$EDITOR $query_file`
        fi
        query_content="$(cat $query_file)"
    fi
}

generate_call_data() {
    json_template='{
    model: $model,
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
    top_p: $top_p,
    max_tokens: $max_tokens,
    temperature: $temperature,
    frequency_penalty: $frequency_penalty,
    presence_penalty: $presence_penalty
    }'
    jq_args=(
        --arg model "$args_model"
        --arg system_instructions "$system_instructions"
        --arg query_content "$query_content"
        --argjson max_tokens "$args_max_tokens"
        --argjson temperature "$args_temperature"
        --argjson top_p "$args_top_p"
        --argjson frequency_penalty "$args_frequency_penalty"
        --argjson presence_penalty "$args_presence_penalty"
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
        exit_error "$(jq -r '.error.message' "$response_file")"
    elif jq -e 'has("choices")' "$response_file" >/dev/null; then
        [[ -n $args_quiet ]] || tcprint "info bu]OpenAssistant says:"
        jq -r '.choices.[0].message.content' "$response_file" | bat -pp --language markdown
        local cost=$(get_usage_stat $usage_file cost)
        local tokens=$(get_usage_stat $usage_file tokens)
        local tokens_prompt=$(get_usage_stat $usage_file tokens_prompt)
        local tokens_response=$(get_usage_stat $usage_file tokens_response)
        local cost_prompt=$(get_usage_stat $usage_file cost_prompt)
        local cost_response=$(get_usage_stat $usage_file cost_response)
        tcprint "info n]$tokens tokens (~\$$cost)"
        tcprint "debug] [prompt: $tokens_prompt (~\$$cost_prompt)] [response: $tokens_response (~\$$cost_response)]"
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
    if [[ -z $args_use_history ]]; then
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
    if [[ -z $args_no_name ]]; then
        tcprint "notice n]Name conversation: "
        read user_given_convo_name
        user_given_convo_name=$(echo $user_given_convo_name | sed 's/ /-/g')
        [[ -z $user_given_convo_name ]] || convo_name="${current_date}__${user_given_convo_name}"
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

print_sys_instructions() {
    tcprint "info bu]System instructions:"
    tcset "yellow d"
    printf "%s\n" "$system_instructions"
    tcreset
}

print_query() {
    tcprint "info bu]Query:"
    printf "%s\n" "$query_content" | bat -pp --language markdown
}

print_debug() {
    tcprint "info bun]API key: "
    tcprint "debug]${openai_api_key:0:8}..."
    tcprint "info bu]Request data:"
    echo "$api_call_data" | jq
    tcprint "info bu]Response headers:"
    bat "$response_headers_file"
}

list_history() {
    if [[ -d "$HISTORY_DIR" ]]; then
        find "$HISTORY_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n'
    fi
}

# List history
if [[ -n $args_list_history ]]; then
    list_history
    exit 0
fi

# Resolve data directory and system instructions file locations
data_dir="$HISTORY_DIR/.last"
system_instructions_file=$SYSTEM_INSTRUCTIONS_FILE
if [[ -n $args_use_history ]]; then
    convo_name=$(list_history | grep "$args_use_history" -m 1)
    [[ -n $args_quiet ]] || tcprint "notice]Using historical conversation: $convo_name"
    data_dir="$HISTORY_DIR/$convo_name"
fi
# Paths for current conversation
system_instructions_file="$data_dir/system_instructions"
query_file="$data_dir/query"
response_file="$data_dir/response"
response_headers_file="$data_dir/headers_response"
usage_file="$data_dir/usage"

[[ -d $CONFIG_DIR ]] || mkdir --parents $CONFIG_DIR
[[ -d $data_dir ]] || mkdir --parents $data_dir

# API key
[[ -f $KEY_FILE ]] || exit_error "Missing OpenAI API key file: $KEY_FILE"
openai_api_key="$(cat $KEY_FILE)"
[[ -n $openai_api_key ]] || exit_error "Empty OpenAI API key"
# System instructions
[[ -f $system_instructions_file ]] || echo 'You are a helpful assistant.' > $system_instructions_file
system_instructions="$(cat $system_instructions_file)"
[[ -z $args_verbose ]] || print_sys_instructions
# Query
get_query
[[ -n $query_content ]] || exit_error "Query content is empty"
generate_call_data
[[ -n $args_quiet ]] || print_query

# Call
[[ -n $args_use_history ]] || call_api
count_usage
read_response
[[ -n $args_no_history ]] || save_history

# Debugging
[[ -z $args_verbose ]] || print_debug

