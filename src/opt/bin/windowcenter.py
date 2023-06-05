#!/bin/python

import subprocess
import json


def run(*command, **kwargs):
    kwargs = dict(check=True, capture_output=True) | kwargs
    result = subprocess.run(command, **kwargs)
    return result.stdout.decode().strip()


if __name__ == "__main__":
    wingeo = run("xdotool", "getactivewindow", "getwindowgeometry", "--shell")
    wingeo = {
        line.split("=")[0]: float(line.split("=")[1])
        for line in wingeo.splitlines() if line
    }
    window_width, window_height = wingeo["WIDTH"], wingeo["HEIGHT"]
    for ws in json.loads(run("i3-msg", "-t", "get_workspaces")):
        if ws["focused"]:
            workspace = ws
            break
    else:
        raise Exception("No focused workspace found")
    workspace_width = float(workspace["rect"]["width"])
    workspace_height = float(workspace["rect"]["height"])
    offset_x = float(workspace["rect"]["x"])
    offset_y = float(workspace["rect"]["y"])
    newx = round(offset_x + workspace_width/2 - window_width/2)
    newy = round(offset_y + workspace_height/2 - window_height/2)
    print(newx, newy)
    run("xdotool", "getactivewindow", "windowmove", str(newx), str(newy))
    quit()
