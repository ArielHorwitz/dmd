#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Git clone a single directory from a repo."
CLI=(
    --prefix "args_"
    -p "clone_url;Repo url"
    -p "repo_dir;Directory in repo to clone"
    -o "target_dir;Directory to clone into;."
    -f "delete;Clear target directory before cloning;;d"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

args_target_dir=$(realpath -m $args_target_dir)

# Create temporary working directory
TMPDIR=/tmp/clonedir-$RANDOM/
printcolor -s ok "Creating temporary directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR

# Clone
printcolor -s ok "Cloning: $args_clone_url"
git clone --quiet --no-checkout --depth=1 --filter=tree:0 $args_clone_url $TMPDIR
cd $TMPDIR
git sparse-checkout set --no-cone $args_repo_dir
printcolor -s ok "Sparse checkout: $args_repo_dir"
git checkout

# Move files to download directory
[[ -z $args_delete ]] || printcolor -s ok "Deleting: $args_target_dir" && rm -rf $args_target_dir/$args_repo_dir
mkdir -p $args_target_dir/$args_repo_dir
printcolor -s ok "Moving files to: $args_target_dir/$args_repo_dir"
mv $args_repo_dir $args_target_dir

# Clean up temporary files
printcolor -s ok "Cleaning up..."
rm -rf $TMPDIR

