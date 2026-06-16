#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Scaffold .agents/ (agents.md + skills/) and .claude symlinks in a project"
CLI=(
    --prefix "args_"
    -o "directory;Project directory to scaffold;."
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

project_dir=$(realpath "$args_directory")
[[ -d $project_dir ]] || exit_error "Not a directory: $project_dir"

agents_md="$project_dir/.agents/agents.md"
agents_skills="$project_dir/.agents/skills"
claude_md="$project_dir/.claude/CLAUDE.md"
claude_skills="$project_dir/.claude/skills"

mkdir -p "$agents_skills" "$project_dir/.claude"

if [[ ! -e $agents_md ]]; then
    printf '# AGENTS.md\n' >"$agents_md"
    printcolor -s ok "Created $agents_md"
fi

link_relative() {
    local link_path=$1 target=$2
    if [[ -L $link_path ]]; then
        return
    fi
    [[ -e $link_path ]] && exit_error "Exists and is not a symlink: $link_path"
    ln -s "$target" "$link_path"
    printcolor -s ok "Linked $link_path -> $target"
}

link_relative "$claude_md" "../.agents/agents.md"
link_relative "$claude_skills" "../.agents/skills"
