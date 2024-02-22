#! /bin/bash
if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    echo "
Get format codes for coloring text in the terminal.

USAGE: $0 [STYLES..] [COLORS..] [OPTIONS..]

# STYLES
A style can be named from the following list:
* ok
* debug
* info
* notice
* warn
* error
* retro

# COLORS
The first color specified will be set as the foreground color, and the second
color will be the background. The color names are:
* black
* white
* red
* green
* blue
* yellow
* cyan
* purple

# OPTIONS
More options are available:
* b - Bold text
* d - Dim color
* u - Underline text
* s - Strikethrough text
* i - Inverted color
* r - Do not reset colors after printing
* n - Do not print newline at the end of format
* t - Do not include a placeholder for text
* y - Interpret text as bytes instead of string

# EXAMPLES
$0 error             # bold red text
$0 blue              # blue text
$0 blue green        # blue text, green background
$0 green un          # underlined green text, no newline
"
    exit 1
fi


get_opt_codes() {
    options=$1
    [[ -z $options ]] && return 0
    while [[ -n $options ]]; do
        opt=${options: -1}
        options="${options%?}"
        case $opt in
            b ) codes+="1;" ;; # Bold
            d ) codes+="2;" ;; # Dim
            u ) codes+="4;" ;; # Underline
            s ) codes+="9;" ;; # Strikethrough
            i ) codes+="7;" ;; # Inverted
        esac
    done
    echo $codes
}

get_post_format() {
    # Text placeholder
    [[ $1 != *t* ]] && { [[ $1 != *y* ]] && echo -n "%s" || echo -n "%b"; }
    # Reset color
    [[ $1 != *r* ]] && echo -n "\e[0m"
    # Newline
    [[ $1 != *n* ]] && echo -n "\n"
}

get_color() {
    case $1 in
        black     ) echo -n "0;" ;;
        red       ) echo -n "1;" ;;
        green     ) echo -n "2;" ;;
        yellow    ) echo -n "3;" ;;
        blue      ) echo -n "4;" ;;
        purple    ) echo -n "5;" ;;
        cyan      ) echo -n "6;" ;;
        white     ) echo -n "7;" ;;
    esac
}

get_style_codes() {
    case $1 in
        # debugging
        ok        ) echo -n "32;"    ;;
        notice    ) echo -n "35;"    ;;
        debug     ) echo -n "2;36;"  ;;
        info      ) echo -n "36;"    ;;
        warn      ) echo -n "33;"    ;;
        error     ) echo -n "31;"    ;;
        # themes
        retro     ) echo -n "1;42;30;" ;;
    esac
}


# Process arguments as options
while [[ $@ ]]; do
    arg=$1 && shift 1

    # Check if style
    style_codes=$(get_style_codes $arg)
    if [[ -n $style_codes ]]; then
        style+=$style_codes
        continue
    fi

    # Check if color
    color_code=$(get_color $arg)
    if [[ -n $color_code ]]; then
        [[ -z $fg ]] && fg="3$color_code" && continue
        [[ -z $bg ]] && bg="4$color_code" && continue
    fi

    # Parse options
    opts+=$(get_opt_codes $arg)
    post_opts+=$arg
done
# Remaining args are text
text="$@"
# Concat codes and remove last semicolon
format="$style$opts$bg$fg"
if [[ -n $format ]]; then
    [[ ";" == ${format: -1} ]] && format="${format%?}"
    format="\e[${format}m"
fi
# Post processing
format+=$(get_post_format $post_opts)

echo -n $format

