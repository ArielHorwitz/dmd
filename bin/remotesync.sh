#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Remote sync (rsync wrapper)"
CLI=(
    --prefix "args_"
    -p "host;Host name as configured in ~/.ssh/config"
    -p "source;Source file"
    -p "target;Target destination"
    -O "include;Patterns to include (full paths);;I"
    -O "exclude;Patterns to exclude (full paths);;E"
    -f "no-compress;Do not compress during transfer"
    -f "upload;Upload instead of download (applies --remote to target instead of source);;u"
    -f "dry-run;Dry run;;d"
    -f "ignore-times;Ignore file modification times;;i"
    -f "verbose;Verbose output;;v"
    -f "sync;Delete extra files from destination;;S"
    -f "resolve;Show the resolved command and exit"
    -e "extra;Extra arguments to rsync"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

include_patterns=()
[[ -z $args_include ]] || read -ra include_patterns <<< "$args_include"

exclude_patterns=()
[[ -z $args_exclude ]] || read -ra exclude_patterns <<< "$args_exclude"

rsync_args=(
    --archive
    --update
    --progress
)
[[ -z $args_sync ]] || rsync_args+=(--delete)
[[ -n $args_no_compress ]] || rsync_args+=(--compress)
[[ -z $args_dry_run ]] || rsync_args+=(--dry-run)
[[ -z $args_ignore_times ]] || rsync_args+=(--ignore-times)
[[ -z $args_verbose ]] || rsync_args+=(-vv)

if [[ ${#include_patterns[@]} -gt 0 ]] || [[ ${#exclude_patterns[@]} -gt 0 ]]; then
    rsync_args+=(--include='*/')
    for pattern in "${include_patterns[@]}"; do
        rsync_args+=(--include="$pattern")
    done
    for pattern in "${exclude_patterns[@]}"; do
        rsync_args+=(--exclude="$pattern")
    done
    if [[ ${#include_patterns[@]} -gt 0 ]]; then
        rsync_args+=(--exclude='*')
    fi
fi

rsync_args+=($args_extra)

if [[ $args_upload ]]; then
    args_target="${args_host}:${args_target}"
else
    args_source="${args_host}:${args_source}"
fi
rsync_args+=("${args_source}" "${args_target}")

if [[ $args_resolve ]]; then
    echo "rsync ${rsync_args[@]}"
    exit 0
fi
if [[ $args_verbose ]]; then
    echo "Running: rsync ${rsync_args[@]}"
fi
rsync "${rsync_args[@]}"
