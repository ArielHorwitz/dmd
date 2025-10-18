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
    -c "filter;Filter patterns to include"
    -f "compress;Compress during transfer;;c"
    -f "upload;Upload instead of download (applies --remote to target instead of source);;u"
    -f "dry-run;Dry run;;d"
    -f "ignore-times;Ignore file modification times;;i"
    -f "verbose;Verbose output;;v"
    -e "extra;Extra arguments to rsync"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

rsync_args=(
    --archive
    --update
    --progress
)
[[ -z $args_compress ]] || rsync_args+=(--compress)
[[ -z $args_dry_run ]] || rsync_args+=(--dry-run)
[[ -z $args_ignore_times ]] || rsync_args+=(--ignore-times)
[[ -z $args_verbose ]] || rsync_args+=(-vv)

if [[ ${#args_filter[@]} -gt 0 ]]; then
    rsync_args+=(--include='*/')
    for pattern in "${args_filter[@]}"; do
        rsync_args+=(--include="**/$pattern")
    done
    rsync_args+=(--exclude='*')
fi

rsync_args+=($args_extra)

if [[ $args_upload ]]; then
    args_target="${args_host}:${args_target}"
else
    args_source="${args_host}:${args_source}"
fi
rsync_args+=("${args_source}" "${args_target}")

[[ -z $args_verbose ]] || echo "Running: rsync ${rsync_args[@]}"
rsync "${rsync_args[@]}"
