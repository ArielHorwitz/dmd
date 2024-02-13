#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Properly check drop-in files for /etc/sudoers.d using visudo.

From visudo(8) man page:
\"Because the policy is evaluated in its entirety, it is not sufficient to check
an individual sudoers include file for syntax errors.\"

To overcome this, the sudoers file at /etc/sudoers and all existing files under
/etc/sudoers.d/ are copied to a temporary working directory along with any
drop-in files passed as arguments. Then, 'visudo --check --strict' is run on the
base file (which will check inclusions from sudoers.d/) before replacing the
/etc/sudoers.d/ directory with the one in the temporary working directory.

Critically, it is assumed that the base sudoers has an @includedir directive
and is then modified to be relative instead of absolute.

No options (including but not limited to --apply, --force, --noconfirm) will do
any modifications to the system if the visudo check failed."
CLI=(
    -f "apply;Copy checked files (if pass) to /etc/sudoers.d;;a"
    -f "noconfirm;Bypass prompts for confirmation"
    -f "force;Overwrite files in case of conflict;;f"
    -O "exclude;Comma-separated files to remove;;e"
    -f "quiet;Be silent;;q"
    -f "show;Show all existing file contents and exit;;s"
    -c "files;Drop-in sudoer files"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1
[[ -n $force ]] || clobber="--no-clobber"
[[ -z $quiet ]] || quiet="--quiet"

print_warn() {
    echo -e "\e[1;33m$@\e[0m"
}

# Assertions
[[ $EUID -eq 0 ]] || exit_error "$APP_NAME must be run as root."


# Show existing
if [[ -n $show ]]; then
    bat /etc/sudoers $(find /etc/sudoers.d -type f)
    exit 0
fi


# Set up temporary working directory
WORKING_DIR=/tmp/checksudo-$RANDOM
[[ ! -e $WORKING_DIR ]] || rm -rf $WORKING_DIR
mkdir --parents $WORKING_DIR
# Copy existing sudoers files
cp /etc/sudoers $WORKING_DIR
cp --recursive /etc/sudoers.d $WORKING_DIR
# Copy Include files
if [[ -n "${files[@]}" ]]; then
    cp $clobber --target-directory $WORKING_DIR/sudoers.d ${files[@]} || exit_error "Failed to copy files. Use '--force' to overwrite."
fi
# Remove exclude files
IFS="," read -ra exclude <<< "$exclude"
for file in "${exclude[@]}"; do
    file="$WORKING_DIR/sudoers.d/$file"
    rm $file || print_warn "Failed to remove file '$file' (from --exclude), it may not exist or was provided with an incorrect path."
done
# Modify includedir directive
sed -i 's;@includedir /etc/sudoers.d;@includedir sudoers.d;g' $WORKING_DIR/sudoers
grep -r '^@includedir sudoers.d$' $WORKING_DIR/sudoers >/dev/null || exit_error "Failed to find includedir directive."


# Check with visudo
[[ -n $quiet ]] || echo -e "\e[33mCheck with visudo:\e[0m"
visudo $quiet --check --strict --file $WORKING_DIR/sudoers >&2 || exit_error "visudo check failed."
[[ -n $quiet ]] || echo -e "\e[32mvisudo check passed.\e[0m"


# Apply
[[ -n $apply ]] || exit 0
# Confirm
if [[ -z $noconfirm ]]; then
    bat --paging=never $WORKING_DIR/sudoers.d/*
    prompt_ask 0 "Apply these to system?" || exit_error "User cancelled the operation."
fi
# Copy to system
rm --force /etc/sudoers.d/*
cp $WORKING_DIR/sudoers.d/* /etc/sudoers.d/
# Set owner and permissions
chown --recursive root:root /etc/sudoers.d
chmod --recursive 0440 /etc/sudoers.d


# Done
if [[ -z $quiet ]]; then
    printf "\e[32mInstalled sudoer drop-in files:\e[0m\n"
    for f in /etc/sudoers.d/*; do echo $f; done
fi
