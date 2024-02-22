#! /bin/bash
set -e

API_URL="https://api.openai.com/v1/chat/completions"
DEFAULT_CONFIG_DIR="$HOME/.config/openassistant"
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
    -O "config-dir;Location for default files;$DEFAULT_CONFIG_DIR;c"
    -f "quiet;Be quiet (overrides --verbose);;q"
    -f "verbose;Be verbose;;v"
    -f "redo-cached;Use cached query and response;;r"
    -f "read-stdin;Read from stdin instead of open an editor;;R"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ -z $args_quiet ]] || args_verbose=

get_query() {
    if [[ -n $args_read_stdin ]]; then
        tcprint "notice]Reading query from stdin..."
        read query_content
    else
        [[ -n $EDITOR ]] || exit_error "No editor configured (use EDITOR environment variable)"
        if [[ -z $args_redo_cached ]]; then
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
}

# Config files
sys_instruct_file="$args_config_dir/system_instructions"
key_file="$args_config_dir/apikey"
query_file="$args_config_dir/query"
response_file="$args_config_dir/response"

[[ -d $args_config_dir ]] || mkdir --parents $args_config_dir
[[ -f $sys_instruct_file ]] || echo 'You are a helpful assistant.' > $sys_instruct_file
[[ -f $key_file ]] || exit_error "Missing OpenAI API key file: $key_file"

# API key
openai_api_key="$(cat $key_file)"
[[ -n $openai_api_key ]] || exit_error "Empty OpenAI API key"
# System instructions
system_instructions="$(cat $sys_instruct_file)"
[[ -z $args_verbose ]] || print_sys_instructions
# Query
get_query
[[ -n $query_content ]] || exit_error "Query content is empty"
generate_call_data
[[ -n $args_quiet ]] || print_query

# Call
[[ -n $args_redo_cached ]] || call_api
read_response

# Debugging
[[ -z $args_verbose ]] || print_debug

