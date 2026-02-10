#!/usr/bin/env python3

import sys
from os import link
from pathlib import Path

from mnamer.__main__ import main as mnamer_main
from mnamer.exceptions import MnamerException
from mnamer.target import Target

HARDLINK_FLAG = "--hardlink"


def _relocate_hardlink(target: Target) -> None:
    destination_path = Path(target.destination).resolve()
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        link(target.source, destination_path)
    except OSError as exc:
        raise MnamerException(str(exc)) from exc


def _enable_hardlink_mode() -> None:
    Target.relocate = _relocate_hardlink


def main() -> None:
    args = [arg for arg in sys.argv[1:] if arg != HARDLINK_FLAG]
    if len(args) != len(sys.argv) - 1:
        _enable_hardlink_mode()
    sys.argv = [sys.argv[0]] + args
    mnamer_main()


if __name__ == "__main__":
    main()
