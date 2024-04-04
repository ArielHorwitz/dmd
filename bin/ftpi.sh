#! /bin/bash
set -e

CONFIG_FILE=$HOME/.config/ftpi/defaults

DEFAULT_CONFIG="# Defaults for ftpi
USERNAME='username'
SERVER='ftp.example.com'
PORT=21
PROTOCOL='ftp'"

if [[ ! -f $CONFIG_FILE ]]; then
    mkdir --parents $(dirname $CONFIG_FILE)
    echo "$DEFAULT_CONFIG" > $CONFIG_FILE
fi
eval "$(cat $CONFIG_FILE)"

APP_NAME=$(basename "$0")
ABOUT="Simple FTP client.

When downloading, 'file-path' is the remote file and 'target-path' is the local file.
When uploading, 'file-path' is the local file and 'target-path' is the remote file.
When deleting, 'file-path' is the remote file.

Configure defaults in: $CONFIG_FILE"
CLI=(
    --prefix "args_"
    -p "operation;Operation to perform (one of: ls, dl, up, rm)"
    -o "file-path;File path to operate on"
    -O "target-path;Target file path;;t"
    -O "username;Username;$USERNAME;u"
    -O "password;Password;;p"
    -O "server;FTP server to connect to;$SERVER;s"
    -O "port;FTP server port number;$PORT;p"
    -O "protocol;Protocol to use (one of: ftp, ftps);$PROTOCOL;P"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI"
eval "$CLI" || exit 1

# Resolve FTP server and paths
ftp_server="${args_protocol}://${args_server}:${args_port}"
file_path="${args_file_path}"
if [[ -n $args_target_path ]]; then
    target_path="$args_target_path"
elif [[ -n $args_file_path ]]; then
    target_path="$(basename $args_file_path)"
fi

printcolor -nf cyan -od "FTP Server:  "; echo ${ftp_server}

USERPASS_SET=
get_userpass() {
    set -e
    if [[ -z $USERPASS_SET ]]; then
        # Resolve username
        if [[ -n $args_username ]]; then
            userpass="$args_username"
        else
            prompttext "Username: "
            userpass="$(prompttext --read)"
        fi
        # Resolve password
        if [[ -n $PASSWORD ]]; then
            userpass+=":$PASSWORD"
        elif [[ -n $args_password ]]; then
            userpass+=":$args_password"
        else
            prompttext -H "Password: "
            userpass+=":$(prompttext --read)"
        fi
    fi
    USERPASS_SET=1
    echo --user ${userpass}
}

assert_file_arg() {
    set -e
    local operation_name=$1
    [[ -n $args_file_path ]] || exit_error "${operation_name} operation requires file path"
    printcolor -nf cyan -od "File:        "; echo ${file_path}
    printcolor -nf cyan -od "Target file: "; echo ${target_path}
}

list() {
    set -e
    curl $(get_userpass) "${ftp_server}/${file_path}"
}

download() {
    set -e
    assert_file_arg "Download"
    curl $(get_userpass) -o "${target_path}" "${ftp_server}/${file_path}"
}

upload() {
    set -e
    assert_file_arg "Upload"
    curl $(get_userpass) -T "${file_path}" "${ftp_server}/${target_path}"
}

delete() {
    set -e
    assert_file_arg "Delete"
    curl $(get_userpass) -Q "DELE ${file_path}" "${ftp_server}"
}

# Choose operation
case $args_operation in
    ls )   list ;;
    dl )   download ;;
    up )   upload ;;
    rm )   delete ;;
    *  )   exit_error "Invalid operation: $args_operation" ;;
esac
