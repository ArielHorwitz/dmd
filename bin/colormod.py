#! /bin/python
import argparse
import colorsys

RESET_TERMINAL_CODE = "\033[0m"
FG_WHITE_CODE = "38;0"
FG_BLACK_CODE = "38;2;0;0;0"
FG_GRAY_CODE = "38;2;128;128;128"

def clamp(value):
    return max(0, min(1, value))


def hex_to_rgb(hex):
    hex = hex.lstrip('#')
    return tuple(int(hex[i:i+2], 16) / 255.0 for i in (0, 2, 4))


def rgb_to_hex(rgb, leading_hex):
    raw = "".join(f"{int(round(c * 255)):02X}" for c in rgb)
    return f"#{raw}" if leading_hex else raw


def modify_hsv(hsv, saturation_factor, value_factor):
    return hsv[0], clamp(hsv[1] * saturation_factor), clamp(hsv[2] * value_factor)


def print_color_table(hsv, saturation_range, value_range):
    leading_ws = "" if args.hide_leading_hex else " "
    if args.show_legend:
        print(f"sat\\val", end="")
        for v in value_range:
            print(f" {round(v, 2):^6}{leading_ws}", end="")
        print()
    for saturation_factor in saturation_range:
        if args.show_legend:
            print(f"{round(saturation_factor, 2):<6}{leading_ws}", end="")
        for value_factor in value_range:
            modified_hsv = modify_hsv(hsv, saturation_factor, value_factor)
            modified_rgb = colorsys.hsv_to_rgb(*modified_hsv)
            modified_hex = rgb_to_hex(modified_rgb, not args.hide_leading_hex)
            rgb_codes = ";".join(str(round(c * 255)) for c in modified_rgb)
            if args.text_color.lower() == "white":
                fg_code = FG_WHITE_CODE
            elif args.text_color.lower() == "black":
                fg_code = FG_BLACK_CODE
            elif args.text_color.lower() in ["gray", "grey"]:
                fg_code = FG_GRAY_CODE
            else:
                fg_code = f"38;2;{rgb_codes}"
            terminal_code = f"\033[48;2;{rgb_codes};{fg_code}m"
            print(f"{terminal_code}{modified_hex}{RESET_TERMINAL_CODE} ", end="")
        print()


def custom_range(n, factor):
    step1 = (1 - 1 / factor) / (n - 1)
    step2 = (factor - 1) / (n - 1)

    small = [1 / factor + i * step1 for i in range(n - 1)]
    large = [1 + i * step2 for i in range(n)]
    return small + large


parser = argparse.ArgumentParser("palette-expander", description="Get more colors out of your palettes")
parser.add_argument("COLORS", nargs="+", help="Base color in hex")
parser.add_argument("-H", "--hide-leading-hex", action="store_true", help="Hide leading hex symbol")
parser.add_argument("-t", "--text-color", default="none", help="Text color (black/grey/white)")
parser.add_argument("-s", "--saturation", default=2, type=float, help="How much to modify color saturation")
parser.add_argument("-S", "--saturations", default=5, type=float, help="How many colorsaturation columns")
parser.add_argument("-v", "--value", default=2, type=float, help="How much to modify color value")
parser.add_argument("-V", "--values", default=5, type=float, help="How many color value rows")
parser.add_argument("-L", "--show-legend", action="store_true", help="Show saturation and value legend")
args = parser.parse_args()

saturations = custom_range(args.saturations, args.saturation)
values = custom_range(args.values, args.value)

for i, color in enumerate(args.COLORS):
    rgb = hex_to_rgb(color)
    hsv = colorsys.rgb_to_hsv(*rgb)
    if i > 0:
        print()
    print_color_table(hsv, saturations, values)
