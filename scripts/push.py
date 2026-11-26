"""Point the repo at a GitHub account, then push.

Usage:
    python scripts/push.py <github-username> [--dry-run]

Rewrite the YOUR_GITHUB_USER placeholders, wire the origin remote, push main,
and print the loadstring line that will serve the pushed bundle.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO_NAME = "ojb-test-hub"
PLACEHOLDER = "YOUR_GITHUB_USER"

TARGETS = ["README.md", "loadstring.lua"]


def run(args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=ROOT, text=True, check=check)


def rewrite(username: str) -> int:
    touched = 0
    for name in TARGETS:
        path = ROOT / name
        text = path.read_text(encoding="utf-8")
        if PLACEHOLDER not in text:
            continue
        path.write_text(text.replace(PLACEHOLDER, username), encoding="utf-8", newline="\n")
        touched += 1
    return touched


def remote_url(username: str) -> str:
    return f"https://github.com/{username}/{REPO_NAME}.git"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("username", help="GitHub account that owns the repo")
    parser.add_argument("--dry-run", action="store_true", help="rewrite files only, skip git")
    args = parser.parse_args()

    username = args.username.strip()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}", username):
        print(f"not a valid GitHub username: {username!r}")
        return 2

    touched = rewrite(username)
    print(f"rewrote {touched} file(s) for {username}")

    load_line = (
        'loadstring(game:HttpGet("https://raw.githubusercontent.com/'
        f'{username}/{REPO_NAME}/main/release/ojb-test-hub.lua"))()'
    )

    if args.dry_run:
        print("dry run — skipped git")
        print("loadstring:", load_line)
        return 0

    existing = run(["git", "remote"], check=False).stdout.split()
    if "origin" in existing:
        run(["git", "remote", "set-url", "origin", remote_url(username)])
    else:
        run(["git", "remote", "add", "origin", remote_url(username)])

    run(["git", "add", "-A"])
    if run(["git", "diff", "--cached", "--quiet"], check=False).returncode != 0:
        run(["git", "commit", "-m", f"point loadstring at {username}/{REPO_NAME}"])

    print(f"pushing to {remote_url(username)} — git will ask for credentials")
    pushed = run(["git", "push", "-u", "origin", "main"], check=False)
    if pushed.returncode != 0:
        print("\npush failed. create the empty repo first:")
        print(f"  https://github.com/new  → name it {REPO_NAME}, no README, no .gitignore")
        print("then run this script again")
        return 1

    print("\npushed. run this in the executor:")
    print(load_line)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\ncancelled")
        sys.exit(130)
    except Exception as exc:  # noqa: BLE001 - surface one readable line, not a traceback
        print(f"\npush helper hit a wall: {exc}")
        print("run `git push -u origin main` by hand to see the raw git error")
        sys.exit(1)
