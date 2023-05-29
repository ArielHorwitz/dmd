#!/usr/bin/python

import time
import json
import sys
import subprocess
import colorsys
from pathlib import Path
import arrow
import requests


DEFAULT_DATA = dict(separator=True, separator_block_width=20, align="center")

WARNING = ""
KMD = ""
KEYBOARD = ""
CAPS = "ﮥ"
NOCAPS = ""
US = "Ꭺ"
IL = "ℵ"

PLUG = ""
PLUG = "ﮣ"
UNPLUG = "ﮤ"
BATTERIES = ""
TEMPERATURES = ""
MICROPHONE = ""
MIC_MUTED = ""
HEADPHONES = ""
HEADPHONES_MUTED = ""
SPEAKER = "墳"
SPEAKER_MUTED = "婢"

TEMP_MIN = 10.0
TEMP_MAX = 35.0
TEMP_RANGE = TEMP_MAX - TEMP_MIN
WEATHER_UPDATE_INTERVAL = 5
WEATHER_REQUEST = (
    "https://api.open-meteo.com/v1/forecast"
    "?latitude=31.89&longitude=34.81"
    "&current_weather=true"
)
WEATHER_CODE_ICONS = {
    0: ("clear", " ", " ", " "),
    1: ("mostly clear", " ", " ", " "),
    2: ("partly cloudy", " ", " ", " "),
    3: ("overcast", " ", " ", " "),
    45: ("fog", " ", " ", " "),
    48: ("fog, rime", " ", " ", " "),
    51: ("light drizzle", " ", " ", " "),
    53: ("moderate drizzle", " ", " ", " "),
    55: ("dense drizzle", " ", " ", " "),
    56: ("light freezing drizzle", " ", " ", " "),
    57: ("moderate freezing drizzle", " ", " ", " "),
    61: ("light rain", " ", " ", " "),
    63: ("moderate rain", " ", " ", " "),
    65: ("dense rain", " ", " ", " "),
    66: ("light freezing rain", " ", " ", " "),
    67: ("moderate freezing rain", " ", " ", " "),
    71: ("light snow", " ", " ", " "),
    73: ("moderate snow", " ", " ", " "),
    75: ("heavy snow", " ", " ", " "),
    77: ("snow grains", " ", " ", " "),
    80: ("rain, light shower", " ", " ", " "),
    81: ("rain, moderate shower", " ", " ", " "),
    82: ("rain, violent shower", " ", " ", " "),
    85: ("light snow shower", " ", " ", " "),
    86: ("heavy snow shower", " ", " ", " "),
    95: ("thunderstorm", " ", " ", " "),
    96: ("thunderstorm, light hail", " ", " ", " "),
    99: ("thunderstorm, heavy hail", " ", " ", " "),
}
DAY_NIGHT_PHASES = ""
MOON_PHASES = ""
DIRECTIONS = ""
PERCIPITATION = ""
HUMIDITY = ""
PRESSURE = ""
TIDE = ""
NONE = ""


def source(func):
    SOURCES.append(func)
    return func


class State:
    weather_data = dict(
        full_text="awaiting weather data...",
        color="#ff88ff",
        _updated=arrow.now().shift(years=-1).timestamp(),
    )


def run(command: str):
    r = subprocess.run(command, capture_output=True, shell=True)
    return r.stdout.decode().strip()


def stdp(text):
    sys.stdout.write(f"{text}\n")
    sys.stdout.flush()


def float2icon(iconlist: str | list[str], value=float):
    return iconlist[round(value * (len(iconlist) - 1))]


def hsv2hex(h: float, s: float = 1, v: float = 1) -> str:
    rgb = colorsys.hsv_to_rgb(h, s, v)
    rgb_hex = ''.join(f"{round(c*255):x}".rjust(2, "0") for c in rgb)
    return f"#{rgb_hex}"


def add_refresh_timer(data: dict) -> dict:
    since_last = arrow.now().timestamp() - data["_updated"]
    until_next = int(WEATHER_UPDATE_INTERVAL * 60 - since_last)
    if until_next < 10:
        return dict(
            full_text=f"{until_next}s {data['full_text']}",
            **{k: v for k, v in data.items() if k != "full_text"}
        )
    return data


def poll_weather() -> dict:
    response = requests.get(WEATHER_REQUEST)
    weather_data = response.json()["current_weather"]

    dayphase = 2 - weather_data["is_day"]
    wcode = weather_data["weathercode"]
    summary = WEATHER_CODE_ICONS[wcode][0]
    icon = WEATHER_CODE_ICONS[wcode][dayphase]

    temperature = weather_data["temperature"]
    bounded_temp = max(TEMP_MIN, min(temperature, TEMP_MAX))
    temp_scale = (bounded_temp - TEMP_MIN) / TEMP_RANGE
    temp_hue = 1 - temp_scale
    color = hsv2hex(temp_hue)
    temp_icon = float2icon(TEMPERATURES, temp_scale)

    windspeed = weather_data["windspeed"]
    winddirection = float(weather_data["winddirection"])
    dir_icon = float2icon(DIRECTIONS, winddirection / 360)

    data = dict(
        full_text=f"{icon} {temp_icon} {temperature}糖 {dir_icon}  {windspeed}㎞/h",
        color=color,
        _updated=arrow.now().timestamp(),
    )
    with open(".kmdweather", "w") as f:
        f.write(json.dumps(data))
    return data


def get_weather(state: State):
    expiration = arrow.now().shift(minutes=-WEATHER_UPDATE_INTERVAL).timestamp()
    if state.weather_data["_updated"] > expiration:
        return add_refresh_timer(state.weather_data)

    if Path(".kmdweather").is_file():
        with open(".kmdweather", "r") as f:
            state.weather_data = json.loads(f.read())
    if state.weather_data["_updated"] > expiration:
        return state.weather_data

    try:
        state.weather_data = poll_weather()
    except Exception as err:
        state.weather_data["full_text"] = f"weather update failed: {err}"
    return state.weather_data


def get_audio_source(state: State) -> dict:
    is_muted = run("pactl get-source-mute @DEFAULT_SOURCE@") == "Mute: yes"
    color = "#ff0000" if is_muted else "#00ff00"
    return dict(
        full_text=MIC_MUTED if is_muted else MICROPHONE,
        color=color,
        separator=False,
        separator_block_width=10,
    )


def get_audio_sink(state: State) -> dict:
    is_muted = run("pactl get-sink-mute @DEFAULT_SINK@") == "Mute: yes"
    device = run("pactl get-default-sink").split(".")[1].split("-")[0]
    if device == "usb":
        device_icon = HEADPHONES
    elif device == "pci":
        device_icon = SPEAKER_MUTED if is_muted else SPEAKER
    else:
        device_icon = "?"

    # volume
    volume_details = run("pactl get-sink-volume @DEFAULT_SINK@")
    parts = volume_details.split("/")
    volume = round(float(parts[3].strip().removesuffix('%')))

    # mute
    if is_muted:
        color = "#ff0000"
        status = SPEAKER_MUTED
    else:
        color = "#00ff00"
        status = SPEAKER
    return dict(
        full_text=f"{device_icon} {volume}%",
        min_width=f"{SPEAKER} 100%",
        color=color,
        align="left",
    )


def get_power(state: State) -> dict:
    capacity = round(float(run("cat /sys/class/power_supply/BAT0/capacity")))
    alarmpower = run("cat /sys/class/power_supply/BAT0/alarm")
    currentpower = run("cat /sys/class/power_supply/BAT0/energy_now")
    fullpower = run("cat /sys/class/power_supply/BAT0/energy_full")
    fulldesign = run("cat /sys/class/power_supply/BAT0/energy_full_design")
    charging = run("cat /sys/class/power_supply/BAT0/status").lower() != "discharging"
    state = BATTERIES[round(capacity / 100 * (len(BATTERIES) - 1))]
    if charging:
        state = f"{PLUG}{state}"
    else:
        state = f"{state}"
    color = hsv2hex(capacity / 200)
    return dict(
        full_text=f"{state} {capacity}%",
        color=color,
    )


def get_monitor(state: State) -> dict:
    return dict(
        full_text="",
    )


def get_kmd(state: State) -> dict:
    kmd_running = run("pgrep kmd") != ""
    if not kmd_running:
        mode = "warning"
    else:
        with open("/var/opt/iukbtw/layer", "r") as mode_file:
            mode = mode_file.read().strip().lower()
    layout = run("setxkbmap -query | grep layout | cut -d: -f2").strip()
    is_caps = "on" in run("xset q | grep -i caps | cut -d: -f3")

    fg = "#bbffbb"
    bg = "#000000"

    # mode state
    if mode == "warning":
        state = WARNING
        bg = "#ff4444"
        fg = "#ffffff"
    if mode == "base":
        state = KMD
        fg = "#ff44ff"
    if mode == "text":
        state = KEYBOARD

    # layout state
    if layout == "us":
        state = f"{state} {US}"
    elif layout == "il":
        state = f"{state} {IL}"

    # caps state
    if is_caps:
        state = f"{state} {CAPS}"
    else:
        state = f"{state} {NOCAPS}"

    # background
    match (mode, layout):
        case ("text", "us"):
            bg = "#660000"
        case ("text", "il"):
            bg = "#000066"

    return dict(
        full_text=state,
        min_width=100,
        color=fg,
        background=bg,
    )


def get_date(state: State) -> dict:
    return dict(
        full_text=arrow.now().format("DD/MM/YY"),
        color="#884488",
        separator=False,
        separator_block_width=10,
    )


def get_time(state: State) -> dict:
    return dict(
        full_text=arrow.now().format("HH:mm:ss"),
        color="#ff88ff",
    )


SOURCES = [
    get_weather,
    get_audio_source,
    get_audio_sink,
    get_power,
    # get_monitor,
    get_kmd,
    get_date,
    get_time,
]
if not Path("/sys/class/power_supply/BAT0").exists():
    SOURCES.remove(get_power)
SOURCES = tuple(SOURCES)


def get_block_data(state: State) -> list[dict]:
    blocks = list()
    for call in SOURCES:
        try:
            block_data = call(state)
        except Exception as e:
            block_data = dict(full_text=f"{call.__name__}: {e}", min_width=1000)
        blocks.append(DEFAULT_DATA | dict(name=call.__name__) | block_data)
    return blocks


def main():
    state = State()
    # Print header
    stdp(json.dumps(dict(version=1)))
    stdp("[")
    # Start endless loop
    while True:
        try:
            data = get_block_data(state)
        except Exception as e:
            err = str(e).replace('\n', ' -- ')
            data = dict(full_text=err, min_width=1000)
        stdp(f"{json.dumps(data)},")
        time.sleep(0.1)


if __name__ == "__main__":
    main()
