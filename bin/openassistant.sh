#! /bin/bash
set -e

API_URL="https://api.openai.com/v1/chat/completions"
CONFIG_DIR="$HOME/.config/openassistant"
HISTORY_DIR="$HOME/.local/share/openassistant/history"
DEFAULT_MODEL="gpt-4-turbo-preview"
DEFAULT_MAX_TOKENS=2048
DEFAULT_TEMPERATURE="1"
DEFAULT_TOP_P="1"
DEFAULT_FREQUENCY_PENALTY="0.2"
DEFAULT_PRESENCE_PENALTY="0.1"

APP_NAME=$(basename "$0")
ABOUT="Query your personal OpenAI assistant.

MODEL: ID of the model to use. See the model endpoint compatibility table (https://platform.openai.com/docs/models/model-endpoint-compatibility) for details on which models work with the Chat API at '/v1/chat/completions'.

MAX TOKENS: The maximum number of tokens that can be generated in the chat completion. The total length of input tokens and generated tokens is limited by the model's context length.

TEMPERATURE: What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. It is generally recommended to alter this or top_p but not both.

TOP-P: An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. It is generally recommended to alter this or temperature but not both.

FREQUENCY PENALTY: Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.

PRESENCE PENALTY: Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.

See details: https://platform.openai.com/docs/api-reference/chat
"
CLI=(
    --prefix "args_"
    -O "model;Open AI gpt model;$DEFAULT_MODEL;m"
    -O "max-tokens;Maximum tokens including prompt and response;$DEFAULT_MAX_TOKENS;M"
    -O "temperature;Model temperature sampling;$DEFAULT_TEMPERATURE;T"
    -O "top-p;Model top-p sampling;$DEFAULT_TOP_P;O"
    -O "frequency-penalty;Model frequency penalty;$DEFAULT_FREQUENCY_PENALTY;F"
    -O "presence-penalty;Model presence penalty;$DEFAULT_PRESENCE_PENALTY;P"
    -O "use-history;Use previous conversation from history;;H"
    -f "list-history;List previous conversations from history and exit;;l"
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
    else
        jq < "$response_file"
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

# Config files
key_file="$CONFIG_DIR/apikey"
sys_instruct_file="$CONFIG_DIR/system_instructions"
data_dir="$HISTORY_DIR/.last"

if [[ -n $args_use_history ]]; then
    convo_name=$(list_history | grep "$args_use_history" -m 1)
    [[ -n $args_quiet ]] || tcprint "notice]Using historical conversation: $convo_name"
    data_dir="$HISTORY_DIR/$convo_name"
    sys_instruct_file="$data_dir/system_instructions"
fi

query_file="$data_dir/query"
response_file="$data_dir/response"
response_headers_file="$data_dir/headers_response"

[[ -d $CONFIG_DIR ]] || mkdir --parents $CONFIG_DIR
[[ -d $data_dir ]] || mkdir --parents $data_dir

# API key
[[ -f $key_file ]] || exit_error "Missing OpenAI API key file: $key_file"
openai_api_key="$(cat $key_file)"
[[ -n $openai_api_key ]] || exit_error "Empty OpenAI API key"
# System instructions
[[ -f $sys_instruct_file ]] || echo 'You are a helpful assistant.' > $sys_instruct_file
system_instructions="$(cat $sys_instruct_file)"
[[ -z $args_verbose ]] || print_sys_instructions
# Query
get_query
[[ -n $query_content ]] || exit_error "Query content is empty"
generate_call_data
[[ -n $args_quiet ]] || print_query

# Call
[[ -n $args_use_history ]] || call_api
read_response
[[ -n $args_no_history ]] || save_history

# Debugging
[[ -z $args_verbose ]] || print_debug

