#! /bin/bash
set -e

CONFIG_FILE=$HOME/.config/ftpi/defaults.toml

DEFAULT_CONFIG='# Defaults for ftpi
USERNAME = "username"
SERVER = "ftp.example.com"
PORT = 21
PROTOCOL = "ftp" # One of: ftp, ftps'


CONFIG_KEYS=(username server port protocol)
tt_out=$(mktemp); tt_err=$(mktemp)
if tigerturtle $CONFIG_FILE -WD "$DEFAULT_CONFIG" -p 'config__' -- ${CONFIG_KEYS[@]} >$tt_out 2>$tt_err; then
    eval $(<$tt_out); rm $tt_out; rm $tt_err;
else
    echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1;
fi

APP_NAME=$(basename "$0")
ABOUT="Simple FTP client.

When downloading, 'file-path' is the remote file and 'target-path' is the local file.
When uploading, 'file-path' is the local file and 'target-path' is the remote file.
When deleting, 'file-path' is the remote file.

Configure defaults in: $CONFIG_FILE"
CLI=(
    --prefix "args_"
    -p "operation;Operation to perform (one of: ls, dl, up, rm, dlrm, cat)"
    -o "file-path;File path to operate on"
    -O "target-path;Target file path;;t"
    -O "username;Username;$config__username;u"
    -O "password;Password;;p"
    -O "server;FTP server to connect to;$config__server;s"
    -O "port;FTP server port number;$config__port;p"
    -O "protocol;Protocol to use (one of: ftp, ftps);$config__protocol;P"
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
    target_path=$(basename "$args_file_path")
fi

printcolor -nfc " FTP Server: " >&2; echo ${ftp_server} >&2

USERPASS=
resolve_userpass() {
    set -e
    local username
    local password
    if [[ -z $USERPASS ]]; then
        # Resolve username
        printcolor -nfc "   Username: " >&2
        if [[ -n $args_username ]]; then
            username="$args_username"
            echo $username >&2
        else
            read username
        fi
        # Resolve password
        if [[ -n $args_password ]]; then
            password=":$args_password"
        else
            password=$(promptpassword \
                --cache="ftpi:${ftp_server}__${username}" \
                "$(printcolor -nfc "   Password:")" \
            )
        fi
    fi
    USERPASS="${username}:${password}"
}

assert_file_arg() {
    set -e
    local operation_name=$1
    [[ -n $args_file_path ]] || exit_error "${operation_name} operation requires file path"
    printcolor -nfc "       File: "  >&2; echo "${file_path}" >&2
    printcolor -nfc "Target file: "  >&2; echo "${target_path}" >&2
}

list() {
    set -e
    resolve_userpass
    curl --user "${USERPASS}" "${ftp_server}/${file_path}"
}

download() {
    set -e
    assert_file_arg "Download"
    resolve_userpass
    curl --user "${USERPASS}" -o "${target_path}" "${ftp_server}/${file_path}"
}

upload() {
    set -e
    assert_file_arg "Upload"
    resolve_userpass
    curl --user "${USERPASS}" -T "${file_path}" "${ftp_server}/${target_path}"
}

delete() {
    set -e
    assert_file_arg "Delete"
    resolve_userpass
    curl --user "${USERPASS}" -Q "DELE ${file_path}" "${ftp_server}"
}

download_delete() {
    set -e
    assert_file_arg "Download+Delete"
    resolve_userpass
    curl --user "${USERPASS}" -o "${target_path}" "${ftp_server}/${file_path}"
    curl --user "${USERPASS}" -Q "DELE ${file_path}" "${ftp_server}"
}

show() {
    set -e
    assert_file_arg "Show"
    resolve_userpass
    curl --user "${USERPASS}" "${ftp_server}/${file_path}"
}

# Choose operation
case $args_operation in
    ls )   list ;;
    dl )   download ;;
    up )   upload ;;
    rm )   delete ;;
    dlrm ) download_delete ;;
    cat )  show ;;
    *  )   exit_error "Invalid operation: $args_operation" ;;
esac
