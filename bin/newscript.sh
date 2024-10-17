#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
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
cat << 'EOF' > $filename
#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="DESCRIPTION"
CLI=(
    --prefix "args_"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

# CONFIGURATION
config_file=$HOME/.config/${APP_NAME}/config.toml
config_keys=()
config_default=''
tt_out=$(mktemp); tt_err=$(mktemp)
if tigerturtle -WD "$config_default" -p "config__" $config_file -- ${config_keys[@]} >$tt_out 2>$tt_err; then
    eval $(<$tt_out); rm $tt_out; rm $tt_err;
else
    echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1;
fi
EOF

# Make executable
chmod +x $filename
