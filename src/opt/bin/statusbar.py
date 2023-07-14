#!/usr/bin/python

import argparse
import asyncio
import colorsys
import itertools
import json
import shlex
import subprocess
import time
from abc import ABC, abstractmethod
from pathlib import Path
from typing import NamedTuple, Optional

import arrow
import httpx

parser = argparse.ArgumentParser()
parser.add_argument("-d", "--debug", help="Debug mode", action="store_true")
parser.add_argument("-s", "--stop-after", help="Stop after seconds", type=float)
parser.add_argument(
    "--no-weather",
    help="Do not update weather",
    action="store_true",
)
ARGS = parser.parse_args()


def run(command: str):
    result = subprocess.run(shlex.split(command), capture_output=True)
    if result.returncode != 0:
        raise Exception(f"{command} failed: {result.stderr.decode()}")
    return result.stdout.decode()


async def arun(command: str):
    cmd, *args = shlex.split(command)
    process = await asyncio.create_subprocess_exec(
        cmd,
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await process.communicate()
    if stderr:
        raise Exception(f"{cmd} {args} failed: {stderr.decode()}")
    return stdout.decode()


def grep(substring: str, search_string: str):
    for line in search_string.splitlines():
        if substring.lower() in line.lower():
            return line
    raise ValueError(f"substr {substring!r} not found in search string")


def float2icon(iconlist: str | list[str], value: float):
    return iconlist[round(value * (len(iconlist) - 1))]


def hsv2hex(h: float, s: float = 1, v: float = 1) -> str:
    rgb = colorsys.hsv_to_rgb(h, s, v)
    rgb_hex = "".join(f"{round(c*255):x}".rjust(2, "0") for c in rgb)
    return f"#{rgb_hex}"


class Component(ABC):
    UPDATE_INTERVAL_SECONDS = 120
    INSTALLED = True
    _last_updated = arrow.now().shift(years=-1)
    _cached_blocks = tuple()

    def block(self, **kwargs) -> dict:
        kwargs = dict(separator=True, separator_block_width=20, align="center") | kwargs
        return dict(name=self.__class__.__name__, **kwargs)

    async def get_blocks(self) -> tuple[dict, ...]:
        if self._check_update():
            try:
                blocks = await asyncio.wait_for(self._update(), 3)
                assert isinstance(blocks, tuple)
            except Exception as exc:
                return (
                    self.block(
                        full_text=f"{self.__class__} failed: {exc}",
                        color="#ff0000",
                    ),
                )
            self._last_updated = arrow.now()
            self._cached_blocks = blocks
        return self._cached_blocks

    def _check_update(self, now: Optional[float] = None) -> bool:
        now = now or arrow.now()
        next_update = self._last_updated.shift(seconds=self.UPDATE_INTERVAL_SECONDS)
        return now >= next_update

    @abstractmethod
    async def _update(self):
        pass


REGISTERED_COMPONENTS = []


def register_component(cls):
    assert issubclass(cls, Component)
    REGISTERED_COMPONENTS.append(cls)
    return cls


class WeatherCode(NamedTuple):
    icon_day: str
    icon_night: str
    icon: str
    description: str


@register_component
class Weather(Component):
    INSTALLED = not ARGS.no_weather
    UPDATE_INTERVAL_SECONDS = 5 * 60
    TEMP_COLOR_SCALE = 0.8
    TEMP_MIN, TEMP_MAX = 15, 35

    CACHE_FILE = Path(".iukweather")
    TEMP_RANGE = TEMP_MAX - TEMP_MIN
    TEMPERATURES = ""
    DAY_NIGHT_PHASES = ""
    MOON_PHASES = ""
    DIRECTIONS = ""
    PERCIPITATION = ""
    HUMIDITY = ""
    PRESSURE = ""
    TIDE = ""
    API_REQUEST = (
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=31.89&longitude=34.81"
        "&current_weather=true"
    )
    CODE_ICONS = {
        0: WeatherCode(" ", " ", " ", "clear"),
        1: WeatherCode(" ", " ", " ", "mostly clear"),
        2: WeatherCode(" ", " ", " ", "partly cloudy"),
        3: WeatherCode(" ", " ", " ", "overcast"),
        45: WeatherCode(" ", " ", " ", "fog"),
        48: WeatherCode(" ", " ", " ", "fog, rime"),
        51: WeatherCode(" ", " ", " ", "light drizzle"),
        53: WeatherCode(" ", " ", " ", "moderate drizzle"),
        55: WeatherCode(" ", " ", " ", "dense drizzle"),
        56: WeatherCode(" ", " ", " ", "light freezing drizzle"),
        57: WeatherCode(" ", " ", " ", "moderate freezing drizzle"),
        61: WeatherCode(" ", " ", " ", "light rain"),
        63: WeatherCode(" ", " ", " ", "moderate rain"),
        65: WeatherCode(" ", " ", " ", "dense rain"),
        66: WeatherCode(" ", " ", " ", "light freezing rain"),
        67: WeatherCode(" ", " ", " ", "moderate freezing rain"),
        71: WeatherCode(" ", " ", " ", "light snow"),
        73: WeatherCode(" ", " ", " ", "moderate snow"),
        75: WeatherCode(" ", " ", " ", "heavy snow"),
        77: WeatherCode(" ", " ", " ", "snow grains"),
        80: WeatherCode(" ", " ", " ", "rain, light shower"),
        81: WeatherCode(" ", " ", " ", "rain, moderate shower"),
        82: WeatherCode(" ", " ", " ", "rain, violent shower"),
        85: WeatherCode(" ", " ", " ", "light snow shower"),
        86: WeatherCode(" ", " ", " ", "heavy snow shower"),
        95: WeatherCode(" ", " ", " ", "thunderstorm"),
        96: WeatherCode(" ", " ", " ", "thunderstorm, light hail"),
        99: WeatherCode(" ", " ", " ", "thunderstorm, heavy hail"),
    }

    def __init__(self):
        if self.CACHE_FILE.exists():
            with open(self.CACHE_FILE) as file:
                self._cached_blocks = tuple(json.load(file))
                self._last_updated = arrow.get(self._cached_blocks[0]["_last_updated"])

    async def _update(self) -> tuple[dict, ...]:
        self._last_updated = self._last_updated.shift(seconds=10)
        async with httpx.AsyncClient() as client:
            response = await client.get(self.API_REQUEST)
        data = response.json()["current_weather"]

        code = self.CODE_ICONS[data["weathercode"]]
        if data["is_day"]:
            code_icon = code.icon_day
        else:
            code_icon = code.icon_night

        temp = round(data["temperature"], 2)
        bounded_temp = max(self.TEMP_MIN, min(temp, self.TEMP_MAX))
        temp_scale = (bounded_temp - self.TEMP_MIN) / self.TEMP_RANGE
        temp_hue = 1 - temp_scale
        temp_color = hsv2hex(temp_hue * self.TEMP_COLOR_SCALE)
        temp_icon = float2icon(self.TEMPERATURES, temp_scale)

        wind_speed = data["windspeed"]
        wind_direction = float(data["winddirection"])
        wind_direction_icon = float2icon(self.DIRECTIONS, wind_direction / 360)

        text = (
            f"{code_icon} {temp_icon} {temp}糖 {wind_direction_icon}  {wind_speed}㎞/h"
        )
        data = self.block(
            full_text=text,
            color=temp_color,
            _last_updated=arrow.now().timestamp(),
        )
        with open(self.CACHE_FILE, "w") as file:
            json.dump([data], file)
        return (data,)


@register_component
class Resources(Component):
    UPDATE_INTERVAL_SECONDS = 3
    REFRESH = ""
    CPU = ""
    MEM = ""

    async def _update(self) -> tuple[dict, ...]:
        resources = run(f"top -bd {self.UPDATE_INTERVAL_SECONDS} -n 1 -p 0")
        resources = resources.splitlines()
        cpuraw = resources[2].split(",")
        cpuidle = cpuraw[3].split()[0]
        cpuuser = float(cpuraw[0].split()[-2])
        pcpu = 100 - float(cpuidle)
        cpu_color = hsv2hex((1 - pcpu / 100) / 3)
        mem = resources[3].split(":")[1].split(",")
        mem_total = float(mem[0].split()[0])
        mem_used = float(mem[2].split()[0])
        pmem = 100 * mem_used / mem_total
        mem_color = hsv2hex((1 - pmem / 100) / 3)
        cpu = self.block(
            full_text=f"{self.CPU} %{pcpu:.1f} (%{cpuuser})",
            align="left",
            color=cpu_color,
            min_width=f"{self.CPU} %99.9 (%99.9)",
        )
        mem = self.block(
            full_text=f"{self.MEM} %{pmem:.1f}",
            align="left",
            color=mem_color,
            min_width=f"{self.MEM} %99.9",
        )
        return mem, cpu


@register_component
class Audio(Component):
    UPDATE_INTERVAL_SECONDS = 0.1
    MIC = ""
    MIC_MUTED = ""
    HEADPHONES = ""
    HEADPHONES_MUTED = ""
    SPEAKER = "墳"
    SPEAKER_MUTED = "婢"
    NOT_AVAILABLE = ""

    async def _update(self) -> tuple[dict, ...]:
        # Source
        mic_muted = run("pactl get-source-mute @DEFAULT_SOURCE@")
        mic_muted = mic_muted.strip() == "Mute: yes"
        audio_source = self.block(
            full_text=self.MIC_MUTED if mic_muted else self.MIC,
            color="#ff0000" if mic_muted else "#00ff00",
            separator=False,
            separator_block_width=10,
        )
        # Sink
        sink_muted = run("pactl get-sink-mute @DEFAULT_SINK@")
        sink_muted = sink_muted.strip() == "Mute: yes"
        device = run("pactl get-default-sink")
        device = device.split(".")[1].split("-")[0]
        if device == "usb":
            device_icon = self.HEADPHONES
        elif device == "pci":
            device_icon = self.SPEAKER_MUTED if sink_muted else self.SPEAKER
        else:
            device_icon = self.NOT_AVAILABLE
        volume_details = run("pactl get-sink-volume @DEFAULT_SINK@")
        volume = volume_details.split("/")[3].strip().removesuffix("%")
        volume = round(float(volume))
        color = "#ff0000" if sink_muted else "#00ff00"
        audio_sink = self.block(
            full_text=f"{device_icon} {volume}%",
            min_width="- - 100%",
            color=color,
            align="left",
        )
        return audio_source, audio_sink


@register_component
class Power(Component):
    UPDATE_INTERVAL_SECONDS = 1
    INSTALLED = Path("/sys/class/power_supply/BAT0").exists()
    PLUG = ""
    BATTERIES = ""

    async def _update(self) -> tuple[dict, ...]:
        status = run("cat /sys/class/power_supply/BAT0/status")
        charging = status.strip().lower() != "discharging"
        capacity = round(float(run("cat /sys/class/power_supply/BAT0/capacity")))
        state = self.BATTERIES[round(capacity / 100 * (len(self.BATTERIES) - 1))]
        if charging:
            state = f"{self.PLUG}{state}"
            color = "#00ffff"
        else:
            color = hsv2hex(capacity / 300)
        return (
            self.block(
                full_text=f"{state} {capacity}%",
                min_width=f"{self.PLUG}{self.BATTERIES[0]} 100%",
                color=color,
            ),
        )


@register_component
class Kmd(Component):
    UPDATE_INTERVAL_SECONDS = 0.1
    WARNING = ""
    KMD = ""
    KEYBOARD = ""
    CAPS = "ﮥ"
    NOCAPS = ""
    US = "Ꭺ"
    IL = "ℵ"

    async def _update(self) -> tuple[dict, ...]:
        kmd_running = run("pgrep kmd")
        if not kmd_running:
            mode = "warning"
        else:
            with open("/var/opt/iukbtw/layer", "r") as mode_file:
                mode = mode_file.read().strip().lower()
        layout = run("setxkbmap -query")
        layout = grep("layout", layout).split(":")[1].strip()
        is_caps = run("xset q")
        is_caps = "on" in grep("caps", is_caps).split(":")[2].strip()

        fg = "#bbffbb"

        # mode state
        if mode == "warning":
            state = self.WARNING
            bg = "#ff4444"
            fg = "#ffffff"
        elif mode == "base":
            state = self.KMD
            fg = "#ff44ff"
        elif mode == "text":
            state = self.KEYBOARD

        # layout state
        if layout == "us":
            state = f"{state} {self.US}"
        elif layout == "il":
            state = f"{state} {self.IL}"

        # caps state
        if is_caps:
            state = f"{state} {self.CAPS}"
        else:
            state = f"{state} {self.NOCAPS}"

        # background
        if mode == "text" and layout == "us":
            bg = "#660000"
        elif mode == "text" and layout == "il":
            bg = "#000066"
        else:
            bg = "#000000"

        return (
            self.block(
                full_text=state,
                min_width="- - - -",
                color=fg,
                background=bg,
            ),
        )


@register_component
class Time(Component):
    UPDATE_INTERVAL_SECONDS = 1

    async def _update(self) -> tuple[dict, ...]:
        date = self.block(
            full_text=arrow.now().format("DD/MM/YY ddd"),
            color="#884488",
            separator=False,
            separator_block_width=10,
        )
        time = self.block(
            full_text=arrow.now().format("HH:mm:ss"),
            color="#ff88ff",
        )
        return date, time


class StatusBar:
    def __init__(self):
        self._components = [
            component() for component in REGISTERED_COMPONENTS if component.INSTALLED
        ]

    async def get(self) -> list[dict]:
        tasks = tuple(component.get_blocks() for component in self._components)
        results = await asyncio.gather(*tasks)
        return tuple(itertools.chain(*results))


async def main():
    debug = ARGS.debug
    update_interval = min(c.UPDATE_INTERVAL_SECONDS for c in REGISTERED_COMPONENTS)
    statusbar = StatusBar()
    # Print header
    print(json.dumps(dict(version=1)))
    print("[")
    # Endless loop
    end = None
    if ARGS.stop_after is not None:
        end = arrow.now().shift(seconds=ARGS.stop_after)
    while True:
        loop_iter_start = time.perf_counter()
        data = await statusbar.get()
        print(
            json.dumps(data) if debug else f"{json.dumps(data)},",
            flush=True,
        )
        if end and arrow.now() >= end:
            quit()
        loop_iter_elapsed = time.perf_counter() - loop_iter_start
        time.sleep(max(0, update_interval - loop_iter_elapsed))


if __name__ == "__main__":
    asyncio.run(main())
