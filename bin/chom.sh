#! /bin/bash

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="WIP chown and chmod files recursively.

Affected files and directories are printed with their owners and permission
details prior to change.

Permissions may be specified in octal (777) or symbolic format (ugo+rwx)."
CLI=(
    -o "target;Directory to iterate;"
    -O "file;Permissions for files;664;f"
    -O "dir;Permissions for directories;775;d"
    -O "owner;New owner;$USER;o"
    -f "dryrun;Do not apply changes (list affected files and details);;D"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

find $target -type d -print0 | xargs -0 stat --format "D %U %a %n"
find $target -type f -print0 | xargs -0 stat --format "F %U %a %n"

if [[ -z $dryrun ]]; then
    find $target -type f -print0 | xargs -0 chown $owner
    find $target -type f -print0 | xargs -0 chmod 664
    find $target -type d -print0 | xargs -0 chown $owner
    find $target -type d -print0 | xargs -0 chmod 775
fi

