#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Create and open documentation for crates"
CLI=(
    --prefix "args_"
    -p "project-dir;Project directory (relative to \$HOME)"
    -o "crate-name;Name of the crate within the project [defaults to project directory name]"
    -O "open-with;Command to open docs with;xdg-open;o"
    -O "generate-command;Custom command to generate docs from within the project root dir;;G"
    -f "generate;Generate the docs;;g"
    -f "private-items;Document private items;;p"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

project_dir="$HOME/${args_project_dir}"
notify_sync_arg="string:synchronous:cdocs_${project_dir}"
crate_name=$args_crate_name
if [[ -z $crate_name ]]; then
    crate_name=$(basename $args_project_dir)
fi
generate_command=$args_generate_command
if [[ -z $generate_command ]]; then
    generate_command="cargo doc -p $crate_name"
    if [[ $args_private_items ]]; then
        generate_command+=" --document-private-items"
    fi
fi

cd "$project_dir"
if [[ $args_generate ]]; then
    notify-send -u low "Generating docs for ${crate_name}..." -h "$notify_sync_arg"
    echo "Running: $generate_command" >&2
    if $generate_command ; then
        notify-send -e -t 1000 -u normal "Generated docs for ${crate_name}" -h "$notify_sync_arg"
    else
        notify-send -u critical "Failed to generate docs for ${crate_name}" -h "$notify_sync_arg"
        exit $?
    fi
fi

$args_open_with target/doc/"$crate_name"/index.html
