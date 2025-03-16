#! /bin/bash
set -e

SSH_ENV_FILE="$HOME/.ssh/environment"

APP_NAME=$(basename "$0")
ABOUT="Manage ssh agent."
CLI=(
    --prefix "args_"
    -f "check;Check if an ssh agent is running;;c"
    -f "add;Add identities;;a"
    -f "kill;Kill all running agents;;k"
    -f "print_shell;Print shell commands;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


check_running() {
    set -e
    local agent_pids=$(pgrep -x ssh-agent) || :
    if [[ -n $agent_pids ]]; then
        echo "Agent pid: $agent_pids"
        return 0
    else
        echo "No agent running"
        return 1
    fi
}

kill_agents() {
    set -e
    check_running > /dev/null
    kill $(pgrep -x ssh-agent)
    echo "unset SSH_AGENT_PID" > $SSH_ENV_FILE
    echo "unset SSH_AUTH_SOCK" >> $SSH_ENV_FILE
    echo "echo No agent running" >> $SSH_ENV_FILE
    chmod 600 $SSH_ENV_FILE
}

start_agent() {
    set -e
    if check_running > /dev/null; then
        return 0
    fi
    ssh-agent -s > $SSH_ENV_FILE
    chmod 600 $SSH_ENV_FILE
}

add_identities() {
    if ssh-add -L >/dev/null; then
        current_identities=$(ssh-add -l)
        echo "Added identities:"
        while IFS= read -r id_details; do
            read -r _bits keyhash email _crypt <<< "$id_details"
            echo "> $email [$keyhash]"
        done <<< "$current_identities"
    else
        current_identities=
    fi
    for privkey in $(find ~/.ssh -type f -name 'id_*' ! -name '*.pub'); do
        echo "Reading file: $privkey"
        read -r _bits keyhash email _crypt <<< "$(ssh-keygen -lf "$privkey")"
        echo "> $email [$keyhash]"
        if echo "$current_identities" | grep "$keyhash" >/dev/null; then
            echo "Skipping..."
        else
            ssh-add "$privkey"
        fi
    done
}


mkdir -p $(dirname "$SSH_ENV_FILE")

if [[ -n $args_kill ]]; then
    kill_agents
    cat $SSH_ENV_FILE
elif [[ -n $args_print_shell ]]; then
    cat $SSH_ENV_FILE
elif [[ -n $args_check ]]; then
    check_running
elif [[ -n $args_add ]]; then
    if ! check_running >/dev/null; then
        exit_error "Agent not running."
    fi
    add_identities
else
    start_agent
    cat $SSH_ENV_FILE
fi
