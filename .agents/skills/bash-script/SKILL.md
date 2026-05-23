---
name: bash-script
description: How to write bash scripts for bin/. Use when creating a new shell script, modifying an existing one, adding flags or options, fixing argument parsing, or writing any CLI tool in bash for this repo.
---

# Writing bash scripts

Scripts live in `bin/` and have their file extensions stripped at install time (`foo.sh` becomes `foo` on PATH). Write all new scripts in `bin/` with a `.sh` extension.

## Starting a new script

Start every script with:

```bash
#! /bin/bash
set -e
```

Use `set -e` at the script level and inside functions to prevent unhandled errors from silently continuing.

## Argument parsing with spongecrab

[spongecrab](https://github.com/ArielHorwitz/spongecrab) provides powerful argument parsing for bash. Run `spongecrab --help` for full documentation or `spongecrab --generate` for a fresh boilerplate template.

Always use `--prefix "args_"` to namespace parsed arguments, avoiding conflicts with other variables in the script. The full boilerplate:

```bash
APP_NAME=$(basename "${0%.*}")
ABOUT="program description"
# Argument syntax: "<arg_name>;<help_text>;<default_value>;<short_name>"
# -o, -c, -C are mutually exclusive
CLI=(
    --prefix "args_"
    -p "arg1;Positional argument"
    -o "arg2;Optional positional argument;<default value>"
    -O "option;Optional argument;;o"
    -f "flag;Optional flag argument;;f"
    # -c "collect_any;Optional remaining positional arguments"
    # -C "collect_some;Required remaining positional arguments"
    -e "extra;Optional extra arguments after '--'"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1
```

### Argument types

| Flag | Type | Behavior |
|------|------|----------|
| `-p` | Positional (required) | Must be provided in order |
| `-o` | Positional (optional) | May be omitted, uses default |
| `-O` | Named option | `--name value`, has default |
| `-f` | Flag | Boolean, set or unset |
| `-c` | Collector (optional) | Remaining positional args as array |
| `-C` | Collector (required) | At least one positional required |
| `-e` | Extra args | Everything after `--` as array |

### Variable naming

Hyphens in argument names become underscores in `$args_*` variables:
- `-f "no-inherit;..."` becomes `$args_no_inherit`
- `-O "retry-interval;..."` becomes `$args_retry_interval`

Flags are empty when unset. Test them with `[[ $args_flag ]]`.

## Error handling

`exit_error` is a script on PATH that prints a colored error message to stderr and exits 1. Use it for fatal errors instead of raw `echo + exit`:

```bash
[[ -f "$config_file" ]] || exit_error "Config not found: $config_file"
```

## Notifications and output

Two tools are available on PATH:
- `notify-send` — desktop notifications (from libnotify). Use for user-facing feedback in GUI context.
- `printcolor` — colored terminal output (from the termcolors crate). Use for terminal-facing status messages.

**Example: notification with icon and urgency:**
```bash
notify-send -u critical "Script Name" "Something went wrong"
notify-send -t 3000 -i /usr/share/icons/dmd/monitor.svg "Done" "Task completed"
```

**Example: printcolor for status:**
```bash
printcolor -s ok "Operation succeeded"
printcolor -s error "Operation failed" >&2
```

## Complete example

A minimal but complete script showing all conventions together:

```bash
#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Greet a user with optional enthusiasm"
CLI=(
    --prefix "args_"
    -p "name;Name to greet"
    -O "greeting;Greeting to use;Hello;g"
    -f "loud;Use desktop notification instead of terminal"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

message="${args_greeting}, ${args_name}!"

if [[ $args_loud ]]; then
    notify-send "$APP_NAME" "$message"
else
    printcolor -s ok "$message"
fi
```
