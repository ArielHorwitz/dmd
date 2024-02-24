#! /bin/bash
set -e

CONFIG_DIR="$HOME/.config/openassistant"
LOCAL_DIR="$HOME/.local/share/openassistant"
HISTORY_DIR="$LOCAL_DIR/history"
KEY_FILE="$CONFIG_DIR/apikey"
MODEL_SETTINGS_FILE="$CONFIG_DIR/model_settings"
SYSTEM_INSTRUCTIONS_FILE="$CONFIG_DIR/system_instructions"
STATS_FILE="$LOCAL_DIR/stats"
EDITOR_QUERY_BLURB='Enter your prompt here, then save and close your editor. Leave empty to cancel.'

API_URL="https://api.openai.com/v1/chat/completions"
DEFAULT_MODEL_SETTINGS='# For details see: https://platform.openai.com/docs/api-reference/chat
model: "gpt-4-turbo-preview"
max_tokens: 4096
temperature: 1.0
top_p: 1.0
frequency_penalty: .05
presence_penalty: .01'
# Token costs are denominated in USD per token (https://openai.com/pricing)
TOKEN_COST_PROMPT=0.00001
TOKEN_COST_RESPONSE=0.00003

# Create defaults
[[ -d $CONFIG_DIR ]] || mkdir --parents $CONFIG_DIR
[[ -d $HISTORY_DIR ]] || mkdir --parents $HISTORY_DIR
[[ -f $KEY_FILE ]] || echo "sk-YOUR_OPENAI_API_KEY" > $KEY_FILE
[[ -f $MODEL_SETTINGS_FILE ]] || echo "$DEFAULT_MODEL_SETTINGS" > $MODEL_SETTINGS_FILE
[[ -f $SYSTEM_INSTRUCTIONS_FILE ]] || echo 'You are a helpful assistant. Format your responses in markdown.' > $SYSTEM_INSTRUCTIONS_FILE
[[ -f $STATS_FILE ]] || echo "No recorded stats." > $STATS_FILE


APP_NAME=$(basename "$0")
ABOUT='Query your personal OpenAI assistant.

Write your OpenAI API key in the configuration folder (--config-dir).'
CLI=(
    --prefix "args_"
    -O "historical;Print a conversation from history;;L"
    -O "history;Conversation history: (d)isable, (a)uto, (n)ame;name;y"
    -f "list;List conversations from history;;l"
    -f "stats;Print recorded stats;;s"
    -f "config-dir;Print configuration directory path;;c"
    -f "history-dir;Print history directory path;;H"
    -f "quiet;Only print the response (overrides --verbose);;q"
    -f "verbose;Show debugging details;;v"
    -f "clear-data;Delete all recorded data and history;;C"
    -f "clear-config;Delete all configuration data"
    -f "force;Do not ask for confirmation;;f"
    -f "read-stdin;Read from stdin instead of opening an editor;;I"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

if [[ -n $args_quiet ]]; then
    QUIET=1
    VERBOSE=
elif [[ -n $args_verbose ]]; then
    QUIET=
    VERBOSE=1
fi
case $args_history in
    d | disable  ) history_enabled= ;;
    a | auto     ) history_enabled=1 ;;
    n | name     ) history_enabled="name" ;;
esac
[[ -z $args_historical ]] || history_enabled=

get_query() {
    if [[ -n $args_read_stdin ]]; then
        tcprint "notice]Reading query from stdin..." >&2
        read query_content
    else
        [[ -n $EDITOR ]] || exit_error "No editor configured (use EDITOR environment variable)"
        if [[ -z $args_historical ]]; then
            [[ -z $VERBOSE ]] || tcprint "notice]Reading query from editor: \"$EDITOR\"" >&2
            [[ -f $query_file && -n $(< $query_file) ]] || echo $EDITOR_QUERY_BLURB > $query_file
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
    echo "$api_call_data" > $calldata_file
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

print_response() {
    if jq -e 'has("error")' "$response_file" >/dev/null; then
        tcprint "yellow bu]Error:" >&2
        jq --color-output < "$response_file" >&2
        exit_error "$(jq -r '.error.message' "$response_file")"
    elif jq -e 'has("choices")' "$response_file" >/dev/null; then
        [[ -n $QUIET ]] || tcprint "green bu]OpenAssistant says:"
        jq -r '.choices.[0].message.content' "$response_file" | bat -pp --color always --language markdown
        if [[ -z $QUIET ]]; then
            local cost=$(get_stat_current cost)
            local tokens=$(get_stat_current tokens)
            local tokens_prompt=$(get_stat_current tokens_prompt)
            local tokens_response=$(get_stat_current tokens_response)
            local cost_prompt=$(get_stat_current cost_prompt)
            local cost_response=$(get_stat_current cost_response)
            tcprint "cyan bn]$tokens tokens ~\$$cost"
            tcprint "cyan bd] [prompt: $tokens_prompt ~\$$cost_prompt] [response: $tokens_response ~\$$cost_response]"
        fi
    else
        jq --color-output < "$response_file"
    fi
}

get_stat_global() {
    local stat_name="$1"
    local default
    [[ -n $2 ]] && default="$2" || default=0
    local line=$(grep -E "^${stat_name}: " $STATS_FILE || echo "$stat_name: $default")
    echo ${line#${stat_name}: }
}

get_stat_current() {
    local stat_name="$1"
    local default=0
    local line=$(grep -E "^${stat_name}: " $stats_file_current || echo "$stat_name: $default")
    echo ${line#${stat_name}: }
}

tally_stats() {
    local tokens=$(jq '.usage.total_tokens' "$response_file")
    local tokens_prompt=$(jq '.usage.prompt_tokens' "$response_file")
    local tokens_response=$(jq '.usage.completion_tokens' "$response_file")
    local cost_prompt=$(echo "scale=4;$tokens_prompt * $TOKEN_COST_PROMPT" | bc)
    local cost_response=$(echo "scale=4;$tokens_response * $TOKEN_COST_RESPONSE" | bc)
    local cost=$(echo "scale=4;$cost_prompt + $cost_response" | bc)
    echo \
"STATS - QUERY
cost: $cost
tokens: $tokens
tokens_prompt: $tokens_prompt
tokens_response: $tokens_response
cost_prompt: $cost_prompt
cost_response: $cost_response" \
    > $stats_file_current
    if [[ -z $args_historical ]]; then
        echo \
"STATS - TOTALS
start: $(get_stat_global start `date +%y-%m-%d-%H-%M-%S`)
cost: $(echo $cost + `get_stat_global cost` | bc)
tokens: $(echo $tokens + `get_stat_global tokens` | bc)
tokens_prompt: $(echo $tokens_prompt + `get_stat_global tokens_prompt` | bc)
tokens_response: $(echo $tokens_response + `get_stat_global tokens_response` | bc)
cost_prompt: $(echo $cost_prompt + `get_stat_global cost_prompt` | bc)
cost_response: $(echo $cost_response + `get_stat_global cost_response` | bc)" \
        > $STATS_FILE
    fi
}

save_history() {
    local current_date=`date +%y-%m-%d-%H-%M-%S`
    local convo_name=$current_date
    local user_given_convo_name
    if [[ $history_enabled = "name" ]]; then
        tcprint "green d][Enter '.' to skip saving]" >&2
        tcprint "notice n]Conversation name: " >&2
        read user_given_convo_name
        [[ $user_given_convo_name != "." ]] || return 0
        if [[ -n $(xargs <<< $user_given_convo_name) ]]; then
            user_given_convo_name=$(sed 's/ /-/g' <<< $user_given_convo_name)
            convo_name="${current_date}__${user_given_convo_name}"
        fi
    fi
    local convo_dir="$HISTORY_DIR/$convo_name"
    local history_files=(
        $system_instructions_file
        $query_file
        $calldata_file
        $response_file
        $response_headers_file
        $stats_file_current
    )
    mkdir --parents $convo_dir
    cp -t $convo_dir ${history_files[@]}
}

remove_last_query_data() {
    rm -rf $HISTORY_DIR/.last
}

print_debug_prequery() {
    tcprint "green bu]Environment:"
    tcprint "green dn]    API key: "; echo "${openai_api_key:0:8}..."
    tcprint "green dn] Config dir: "; echo $CONFIG_DIR
    tcprint "green dn]   Data dir: "; echo $data_dir
    tcprint "green bu]System instructions:"
    tcset "yellow d"
    printf "%s\n" "$system_instructions"
    tcreset
}

print_debug_precall() {
    tcprint "green bu]Request data:"
    jq --color-output <<< $api_call_data
}

print_query() {
    tcprint "green bu]Query:"
    printf "%s\n" "$query_content" | bat -pp --color always --language markdown
}

print_debug() {
    tcprint "green bu]Response headers:"
    bat -pp --color always "$response_headers_file"
}

list_history() {
    if [[ -d "$HISTORY_DIR" ]]; then
        find "$HISTORY_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort -r
    fi
}

# Simple short operations
if [[ -n $args_version ]]; then
    echo $DATA_VERSION
    exit 0
elif [[ -n $args_list ]]; then
    list_history
    exit 0
elif [[ -n $args_config_dir ]]; then
    echo $CONFIG_DIR
    exit 0
elif [[ -n $args_history_dir ]]; then
    echo $HISTORY_DIR
    exit 0
elif [[ -n $args_stats ]]; then
    cat $STATS_FILE
    exit 0
elif [[ -n $args_clear_data ]]; then
    if [[ -z $args_force ]]; then
        promptconfirm -d "Clear all recorded stats and history?" || exit_error "Aborted."
    fi
    rm -rf $HISTORY_DIR
    rm -f $STATS_FILE
    exit 0
elif [[ -n $args_clear_config ]]; then
    if [[ -z $args_force ]]; then
        promptconfirm -d "Clear all configuration data?" || exit_error "Aborted."
    fi
    rm -rf $CONFIG_DIR
    exit 0
fi

# Resolve data directory and system instructions file locations
data_dir="$HISTORY_DIR/.last"
if [[ -n $args_historical ]]; then
    convo_name=$(list_history | grep "$args_historical" -m 1) || exit_error "No conversations found: '$args_historical'"
    [[ -n $QUIET ]] || tcprint "notice]Using historical conversation: $convo_name"
    data_dir="$HISTORY_DIR/$convo_name"
fi
[[ -d $data_dir ]] || mkdir --parents $data_dir
# Current conversation data paths
system_instructions_file="$data_dir/system_instructions"
cp $SYSTEM_INSTRUCTIONS_FILE $system_instructions_file
query_file="$data_dir/query"
calldata_file="$data_dir/calldata"
response_file="$data_dir/response"
response_headers_file="$data_dir/headers_response"
stats_file_current="$data_dir/stats"

# System instructions
system_instructions="$(cat $system_instructions_file)"

# API key
[[ -f $KEY_FILE ]] || exit_error "Missing OpenAI API key file: $KEY_FILE"
openai_api_key="$(cat $KEY_FILE)"
[[ -n $openai_api_key ]] || exit_error "Empty OpenAI API key"

# Get query
[[ -z $VERBOSE ]] || print_debug_prequery
get_query
[[ -n $query_content ]] || exit_error "Query content is empty"
generate_call_data
[[ -n $QUIET ]] || print_query

# Call API
[[ -z $VERBOSE ]] || print_debug_precall
[[ -n $args_historical ]] || call_api
tally_stats
[[ -z $VERBOSE ]] || print_debug
print_response
if [[ -n $history_enabled ]]; then
    save_history
else
    remove_last_query_data
fi

