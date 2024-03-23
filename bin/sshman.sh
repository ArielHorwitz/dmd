#! /bin/bash
set -e

SSH_ENV_FILE="$HOME/.ssh/environment"

APP_NAME=$(basename "$0")
ABOUT="Manage ssh agent."
CLI=(
    --prefix "args_"
    -f "check;Check if an ssh agent is running;;c"
    -f "kill;Kill all running agents;;k"
    -f "print_shell;Print shell commands;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1


check_running() {
    set -e
    local agent_pids=$(pgrep -x ssh-agent) || :
    if [[ -n $agent_pids ]]; then
        echo Agent pid: $agent_pids
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


if [[ -n $args_kill ]]; then
    kill_agents
    cat $SSH_ENV_FILE
elif [[ -n $args_print_shell ]]; then
    cat $SSH_ENV_FILE
elif [[ -n $args_check ]]; then
    check_running
else
    start_agent
    cat $SSH_ENV_FILE
fi
