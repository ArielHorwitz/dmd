#! /bin/python

import argparse
import dataclasses
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

import tomllib

ICONS = {
    "sink": "/usr/share/icons/dmd/speaker3.svg",
    "sink_mute": "/usr/share/icons/dmd/speaker0.svg",
    "source": "/usr/share/icons/dmd/mic1.svg",
    "source_mute": "/usr/share/icons/dmd/mic0.svg",
}


@dataclasses.dataclass
class Node:
    id: int
    name: str
    nick: str
    description: str
    is_source: bool
    is_default: bool
    info: dict
    props: dict
    params: dict


def _get_default_devices(pw_data):
    default_sink_name = None
    default_source_name = None
    default_configured_sink_name = None
    default_configured_source_name = None
    for element in pw_data:
        if not element["type"].endswith("Metadata"):
            continue
        props = element.get("props", {})
        if not props.get("metadata.name") == "default":
            continue
        for metadatum in element["metadata"]:
            metadatum_key = metadatum["key"]
            if metadatum_key == "default.audio.sink":
                default_sink_name = metadatum["value"]["name"]
            if metadatum_key == "default.audio.source":
                default_source_name = metadatum["value"]["name"]
            if metadatum_key == "default.configured.audio.sink":
                default_configured_sink_name = metadatum["value"]["name"]
            if metadatum_key == "default.configured.audio.source":
                default_configured_source_name = metadatum["value"]["name"]
    return (
        default_configured_sink_name or default_sink_name,
        default_configured_source_name or default_source_name,
    )


@dataclasses.dataclass
class State:
    @classmethod
    def get(cls):
        return cls(run_cmd("pw-dump"))

    def __init__(self, raw_pw_dump):
        pw_data = json.loads(raw_pw_dump)
        default_sink_name, default_source_name = _get_default_devices(pw_data)

        ids = {}
        names = {}
        nicks = {}
        for element in pw_data:
            if not element["type"].endswith("Node"):
                continue
            info = element.get("info", {})
            props = info.pop("props", {})
            params = info.pop("params", {})
            name = props.get("node.name")
            media_class = props.get("media.class", "NOCLASS")
            if not media_class.startswith("Audio/"):
                continue
            audio_role = media_class.removeprefix("Audio/")
            if audio_role == "Source":
                is_source = True
                if props.get("port.group") != "capture":
                    raise ValueError("Expected source to be 'port.group'='capture'")
            elif audio_role == "Sink":
                is_source = False
                if props.get("port.group") != "playback":
                    raise ValueError("Expected sink to be 'port.group'='playback'")
            else:
                raise ValueError(f"Unknown audio role: {props}")
            is_default = name in (default_sink_name, default_source_name)
            node = Node(
                id=element["id"],
                name=name,
                nick=props.get("node.nick"),
                description=props.get("device..profile.description"),
                is_source=is_source,
                is_default=is_default,
                info=element,
                props=props,
                params=params,
            )
            ids[node.id] = node
            names[node.name] = node
            nicks[node.nick] = node

        self._nodes_by_id = ids
        self._nodes_by_name = names
        self._nodes_by_nick = nicks
        self._default_source = self._nodes_by_name.get(default_source_name)
        self._default_sink = self._nodes_by_name.get(default_sink_name)
        if self._default_source is None:
            print(f"No default source found {default_source_name=}")
        if self._default_sink is None:
            print(f"No default sink found {default_sink_name=}")

    @property
    def default_source(self):
        return self._default_source

    @property
    def default_sink(self):
        return self._default_sink

    def node(self, *, id=None, name=None, nick=None, allow_missing=True):
        param_count = sum((id is not None, name is not None, nick is not None))
        if param_count > 1:
            raise ValueError("Can only choose one parameter for node selection")
        if param_count < 1:
            raise ValueError("Must choose one parameter for node selection")
        if id is not None:
            node = self._nodes_by_id.get(id)
        if name is not None:
            node = self._nodes_by_name.get(name)
        if nick is not None:
            node = self._nodes_by_nick.get(nick)
        if not allow_missing and node is None:
            raise ValueError(f"Failed to find node {id=} {name=} {nick=}")
        return node

    def all_nodes(self):
        return list(self._nodes_by_id.values())


def run_cmd(*cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def get_default_device(source: bool):
    device_type = "SOURCE" if source else "SINK"
    return f"@DEFAULT_AUDIO_{device_type.upper()}@"


def _get_status(device_id: int):
    output = run_cmd("wpctl", "get-volume", str(device_id))
    # print(f"{output=}")
    # Output format: "Volume: 0.65 [MUTED]"
    try:
        parts = output.split()
        volume = round(float(parts[1]) * 100, 2)
        is_muted = output.endswith("[MUTED]")
    except Exception as e:
        raise RuntimeError(
            f"Failed to parse device volume status from {output=} for {device_id=}"
        ) from e
    return volume, is_muted


def get_volume(device_id: int):
    return _get_status(device_id)[0]


def set_volume(
    device_id: int,
    /,
    volume: Optional[float] = None,
    *,
    increment: Optional[float] = None,
):
    if volume is not None:
        run_cmd("wpctl", "set-volume", str(device_id), f"{volume}%")
    if increment is not None:
        sign = "+" if increment >= 0 else "-"
        increment = abs(increment)
        run_cmd("wpctl", "set-volume", str(device_id), f"{increment}%{sign}")


def get_mute(device_id: int):
    return _get_status(device_id)[1]


def set_mute(device_id: int, mute_status: Optional[bool] = None):
    if mute_status is None:
        mute_status = "toggle"
    else:
        mute_status = str(int(mute_status))
    run_cmd("wpctl", "set-mute", str(device_id), mute_status)


def set_default_device(device_id: int):
    run_cmd("wpctl", "set-default", str(device_id))


def fade(device_id: int, target_volume: float, fade_seconds: float):
    initial_volume = get_volume(device_id)
    volume_diff = abs(initial_volume - target_volume)
    if volume_diff == 0:
        return
    direction = 1 if target_volume > initial_volume else -1
    current_volume = initial_volume
    step_volume = 1
    step_delay = fade_seconds / volume_diff * step_volume

    print(
        f"Fading from {initial_volume}% to {target_volume}% over {fade_seconds}s",
        file=sys.stderr,
    )
    last_step = time.time()
    while True:
        if current_volume == target_volume:
            break
        if current_volume != get_volume(device_id):
            print("Volume changed externally, stopping fade", file=sys.stderr)
            break
        if direction > 0:
            current_volume = min(target_volume, current_volume + step_volume)
        else:
            current_volume = max(target_volume, current_volume - step_volume)
        set_volume(device_id, current_volume)
        print(current_volume)
        if current_volume == target_volume:
            break
        step_elapsed = time.time() - last_step
        time.sleep(max(0, step_delay - step_elapsed))
        last_step = time.time()


def notify(*device_ids: int, sleep_between: Optional[float] = None):
    state = State.get()
    do_sleep = False
    for device_id in device_ids:
        if do_sleep:
            time.sleep(sleep_between)
        if sleep_between is not None:
            do_sleep = True
        node = state.node(id=device_id)
        current_volume = get_volume(device_id)
        is_muted = get_mute(device_id)
        device_type = "source" if node.is_source else "sink"

        if is_muted:
            volume_text = f"{current_volume}% [MUTED]"
            icon = ICONS[f"{device_type}_mute"]
        else:
            volume_text = f"{current_volume}%"
            icon = ICONS[device_type]

        cmd = [
            "notify-send",
            "-u",
            "low",
            "-t",
            "1500",
            "-i",
            icon,
            "-h",
            f"int:value:{current_volume}",
            "-h",
            f"string:synchronous:volume_{device_type}",
            f"Volume: {volume_text}",
            f"{node.nick} ({device_type})",
        ]
        subprocess.run(cmd)


def main():
    parser = argparse.ArgumentParser(
        prog="daudio",
        description="Manage audio devices and volumes",
    )
    parser.add_argument(
        "--debug-args",
        action="store_true",
        help="Debug argument parser",
    )
    subparsers = parser.add_subparsers(dest="command", help="Command")

    subparsers.add_parser("config", help="Show user configuration")

    list_parser = subparsers.add_parser("list", help="Show information")
    list_select_group = list_parser.add_mutually_exclusive_group()
    list_select_group.add_argument("--id", type=int, help="Device ID")
    list_select_group.add_argument("--class", dest="dclass", help="Device class")
    list_parser.add_argument(
        "--reverse-class-order",
        action="store_true",
        help="Reverse order of class devices",
    )
    list_parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Print more details",
    )

    device_parser = subparsers.add_parser("device", help="Manage default devices")
    device_select_group = device_parser.add_mutually_exclusive_group()
    device_select_group.add_argument("--id", type=int, help="Device ID")
    device_select_group.add_argument("--class", dest="dclass", help="Device class")
    device_parser.add_argument(
        "--reverse-class-order",
        action="store_true",
        help="Reverse order of class devices",
    )
    device_parser.add_argument(
        "-N",
        "--notification",
        action="store_true",
        help="Show notification",
    )

    volume_parser = subparsers.add_parser("volume", help="Manage volume")
    device_group = volume_parser.add_mutually_exclusive_group()
    device_group.add_argument(
        "--device-id",
        type=int,
        help="Device ID (instead of default device)",
    )
    device_group.add_argument(
        "--mic",
        action="store_true",
        help="Choose default source instead of sink",
    )
    volume_parser.add_argument(
        "volume",
        nargs="?",
        type=float,
        help="Set volume percentage",
    )
    volume_parser.add_argument(
        "-i",
        "--increase",
        type=float,
        help="Increase volume percentage",
    )
    volume_parser.add_argument(
        "-d",
        "--decrease",
        type=float,
        help="Decrease volume percentage",
    )
    volume_parser.add_argument(
        "-F",
        "--fade",
        type=float,
        help="Fade to target volume over seconds",
    )
    mute_group = volume_parser.add_mutually_exclusive_group()
    mute_group.add_argument(
        "-m",
        "--mute",
        action="store_true",
        help="Mute device",
    )
    mute_group.add_argument(
        "-u",
        "--unmute",
        action="store_true",
        help="Unmute device",
    )
    mute_group.add_argument(
        "--mute-toggle",
        action="store_true",
        help="Toggle device mute",
    )
    volume_parser.add_argument(
        "-M",
        "--is-mute",
        action="store_true",
        help="Print mute status",
    )
    volume_parser.add_argument(
        "-N",
        "--notification",
        action="store_true",
        help="Show notification",
    )
    volume_parser.add_argument(
        "--notify-all",
        action="store_true",
        help="Show notifications for sink and source",
    )

    args = parser.parse_args()
    if args.debug_args:
        print(args, file=sys.stderr)

    if args.command == "volume":
        command_volume(args)
    elif args.command == "config":
        command_config(args)
    elif args.command == "list":
        command_list(args)
    elif args.command == "device":
        command_device(args)
    else:
        raise ValueError(f"Unknown command: {args.command}")


def command_volume(args):
    state = State.get()
    if args.device_id:
        device_id = args.device_id
    else:
        node = state.default_source if args.mic else state.default_sink
        device_id = node.id
    if args.volume is not None:
        if args.fade is not None:
            fade(device_id, args.volume, args.fade)
        else:
            set_volume(device_id, args.volume)
    if args.increase is not None:
        set_volume(device_id, increment=args.increase)
        # raise NotImplementedError("increase")
    if args.decrease is not None:
        set_volume(device_id, increment=-args.decrease)
        # raise NotImplementedError("decrease")
    if args.mute:
        set_mute(device_id, True)
    if args.unmute:
        set_mute(device_id, False)
    if args.mute_toggle:
        set_mute(device_id, None)
    if args.is_mute:
        is_muted = get_mute(device_id)
        print(int(is_muted))
    elif args.notify_all:
        notify(
            state.default_sink.id,
            state.default_source.id,
        )
    else:
        print(get_volume(device_id))
        if args.notification:
            notify(device_id)


def command_config(args):
    state = State.get()
    device_classes = get_device_classes()
    for dclass in device_classes.keys():
        print(f"Device class: [[ {dclass} ]]")
        device_names = device_classes[dclass]
        for name in device_names:
            found_repr = "   ❌"
            node = state.node(name=name)
            if node is not None:
                found_repr = f"{node.id:>2} ✅"
            print(f"  {found_repr} {name}")


def command_list(args):
    state = State.get()
    print_nodes = state.all_nodes()
    if args.id:
        print_nodes = [state.node(id=args.id, allow_missing=False)]
    elif args.dclass:
        print_nodes = get_class_nodes(state, args.dclass, args.reverse_class_order)
    for node in print_nodes:
        print_node(node, args.verbose)


def command_device(args):
    state = State.get()
    if args.dclass is not None:
        nodes = get_class_nodes(state, args.dclass, args.reverse_class_order)
        if not nodes:
            raise ValueError(f"No available devices found for class: {args.dclass}")
        node = nodes[0]
        set_default_device(node.id)
        print(node.name)
        if args.notification:
            notify(node.id)
    elif args.id is not None:
        node = state.node(id=args.id, allow_missing=False)
        set_default_device(node.id)
        print(node.name)
        if args.notification:
            notify(node.id)
    else:
        print_node(state.default_sink)
        print_node(state.default_source)


def print_node(node: Node, verbosity: int = 0):
    if not isinstance(node, Node):
        print(f"     ⛔ Missing data, {node=}")
        return
    default_repr = "✳" if node.is_default else " "
    ntype = "🎙 " if node.is_source else "🔊"
    print(f"{node.id:>4} {default_repr} {ntype} {node.nick} [ {node.name} ]")
    if verbosity >= 2:
        print(json.dumps(node.info, indent=4))
    if verbosity >= 1:
        print(json.dumps(node.props, indent=4))
    if verbosity >= 3:
        print(json.dumps(node.params, indent=4))


def get_device_classes():
    user_config_file = Path.home() / ".config" / "daudio" / "daudio.toml"
    user_config = tomllib.loads(user_config_file.read_text())
    return user_config.get("classes", {})


def get_class_nodes(
    state: State,
    dclass: str,
    reverse: bool = False,
):
    device_names = get_device_classes().get(dclass)
    if device_names is None:
        raise ValueError(f"Unknown device class: {dclass}")
    result = list(filter(None, (state.node(name=n) for n in device_names)))
    if not result:
        raise ValueError(f"No devices found from: {dclass}")
    if reverse:
        result = list(reversed(result))
    return result


if __name__ == "__main__":
    main()
