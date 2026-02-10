#!/usr/bin/env python3

import sys
from os import link
from pathlib import Path

from mnamer.__main__ import main as mnamer_main
from mnamer.exceptions import MnamerException
from mnamer.target import Target

HARDLINK_FLAG = "--hardlink"


def _relocate_hardlink(target: Target) -> None:
    source_path = Path(target.source).resolve()
    destination_path = Path(target.destination).resolve()
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        if destination_path.exists():
            destination_path.unlink()
        link(source_path, destination_path)
    except OSError as exc:
        raise MnamerException(
            f"failed to create hardlink from '{source_path}' to '{destination_path}': {exc}"
        ) from exc


def _enable_hardlink_mode() -> None:
    """Patch mnamer to create hardlinks instead of moving files."""
    Target.relocate = _relocate_hardlink


def main() -> None:
    args = [arg for arg in sys.argv[1:] if arg != HARDLINK_FLAG]
    if len(args) != len(sys.argv) - 1:
        _enable_hardlink_mode()
    sys.argv = [sys.argv[0]] + args
    mnamer_main()


if __name__ == "__main__":
    main()
