#!/bin/python

from tempfile import NamedTemporaryFile
import argparse
import subprocess
import shlex


def run(*command, **kwargs):
    kwargs = dict(check=True, capture_output=True) | kwargs
    result = subprocess.run(command, **kwargs)
    return result.stdout.decode().strip()


if __name__ == "__main__":
    # Parse args
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-p",
        "--prompt",
        help="Prompt text for user",
    )
    parser.add_argument(
        "-e",
        "--execute",
        help="Command to execute, where '{{}}' is replaced with user input",
    )
    args = parser.parse_args()
    if args.execute is None:
        raise Exception("Missing execute argument")
    if "{{}}" not in args.execute:
        raise Exception("Missing '{{}}' placeholder in execute argument")
    # Kill existing prompts
    while run("xdotool", "search", "--class", "iukbtw-prompt", check=False):
        run("xdotool", "search", "--class", "iukbtw-prompt", "windowkill")
    # Prompt user
    with NamedTemporaryFile() as tempfile:
        prompt_command = "; ".join([
            f"printf {shlex.quote(args.prompt)}",
            "read line",
            f"echo $line > {shlex.quote(tempfile.name)}"
        ])
        popup_prompt_command = [
            "alacritty",
            "--title",
            "User prompt",
            "--class",
            "iukbtw-prompt",
            "-e",
            "bash",
            "-c",
            prompt_command,
        ]
        run(*popup_prompt_command)
        tempfile.seek(0)
        user_text = tempfile.read().decode().strip()
    print(f"User input text: {user_text}")
    execute_command = shlex.split(args.execute.replace("{{}}", shlex.quote(user_text)))
    print(f"Executing command: {execute_command}")
    run(*execute_command)
