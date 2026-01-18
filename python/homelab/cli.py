#!/usr/bin/env python3
"""homelab_2026.1 command-line wrapper.

Developer notes
- This is an optional entry point. The Bash menu remains the main interface.
- Keep Python focused on structured operations, not shell orchestration.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def main() -> None:
    menu = repo_root() / "scripts" / "menu.sh"
    env = os.environ.copy()
    subprocess.run(["bash", str(menu)], check=False, env=env)


if __name__ == "__main__":
    main()
