#!/bin/python

import shutil
from configparser import ConfigParser
from pathlib import Path

FF_DIR = Path.home() / ".mozilla" / "firefox"
PREF_SHEETS = (
    'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n'
)
USERCHROME_CSS = "toolbar#TabsToolbar { display: none !important }\n"


def main():
    config_parser = ConfigParser()
    config_parser.read(FF_DIR / "installs.ini")
    profile = config_parser[config_parser.sections()[0]]["Default"]
    profile_dir = FF_DIR / profile
    print(f"Profile dir: {profile_dir}")
    userchrome = profile_dir / "chrome" / "userChrome.css"
    userchrome.parent.mkdir(exist_ok=True)
    if userchrome.is_file():
        shutil.copy(userchrome, userchrome.with_suffix(".css.bak"))
    userchrome.write_text(USERCHROME_CSS)
    userprefs = profile_dir / "user.js"
    if userprefs.is_file():
        shutil.copy(userprefs, userprefs.with_suffix(".js.bak"))
    userprefs.write_text(PREF_SHEETS)


if __name__ == "__main__":
    main()
