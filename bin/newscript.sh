#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Create a new executable bash script with boilerplate."
CLI=(
    -p "name;Script name"
    -o "target;Target directory (will create if it doesn't exist);."
    -f "force;Overwrite existing file;;f"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# Create/find file
filename="$name.sh"
[[ -d $target ]] || mkdir --parents $target
cd $target
[[ ! -e $filename ]] || [[ -n $force ]] || exit_error "File exists, use --force to ignore this error."

# Write boilerplate
printf '#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="DESCRIPTION"
CLI=(
    --prefix "args_"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# printf $CLI
eval "$CLI" || exit 1
' > $filename

# Make executable
chmod +x $filename
