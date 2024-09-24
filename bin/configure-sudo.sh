#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Configure some sudo settings using checksudo."
CLI=(
    --prefix "args_"
    -c "binaries;Binaries allowed to be run as root for the user"
    -O "user;Apply to user;$USER;u"
    -O "timeout;Password timeout in minutes;;t"
    -f "feedback;Show feedback when typing password;;b"
    -f "disable-feedback;Disable feedback when typing password;;B"
    -f "noconfirm;Do not ask for confirmation;;n"
    -f "quiet;Be quiet;;q"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# printf $CLI
eval "$CLI" || exit 1

# Set up temporary working directory
while :; do
    WORKING_DIR=/tmp/checksudo-$RANDOM
    [[ -e $WORKING_DIR ]] || break
done
mkdir --parents $WORKING_DIR

dropin_file=$WORKING_DIR/90-configure-sudo
printf "" > $dropin_file

# Feedback
if [[ -n $args_disable_feedback ]]; then
    printf '# Disable feedback when typing password\nDefaults !pwfeedback\n\n' >> $dropin_file
elif [[ -n $args_feedback ]]; then
    printf '# Enable feedback when typing password\nDefaults pwfeedback\n\n' >> $dropin_file
fi
# Timeout
if [[ -n $args_timeout ]]; then
    printf '# Set password timeout\nDefaults timestamp_timeout=%d\n\n' "$args_timeout" >> $dropin_file
fi
if [[ -n $args_binaries ]]; then
    printf '# Allow user "%s" to run commands as root without password
%s ALL=(root:root) NOPASSWD: ' "$args_user" "$args_user" >> $dropin_file
    echo "$(IFS=,; echo "${args_binaries[*]}")" >> $dropin_file
fi

checksudo_args=("--force" "--apply")
[[ -z $args_quiet ]] || checksudo_args+=("--quiet")
[[ -z $args_noconfirm ]] || checksudo_args+=("--noconfirm")

sudo checksudo ${checksudo_args[@]} $dropin_file
