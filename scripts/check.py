"""Structural sanity check for Luau sources.

Not a parser: it strips comments and strings, then checks block-keyword balance.
Enough to catch a stray `end`, an unterminated string, or a broken module seam.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

LONG_BRACKET = re.compile(r"\[(=*)\[")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def strip_source(text: str) -> str:
    out: list[str] = []
    i = 0
    length = len(text)

    while i < length:
        ch = text[i]

        # long comment / long string
        if ch == "[":
            match = LONG_BRACKET.match(text, i)
            if match:
                level = match.group(1)
                closer = "]" + level + "]"
                end = text.find(closer, match.end())
                if end == -1:
                    raise ValueError("unterminated long bracket at offset %d" % i)
                block = text[i : end + len(closer)]
                out.append(" " if block.startswith("--") else '""')
                i = end + len(closer)
                continue

        if ch == "-" and text.startswith("--", i):
            match = LONG_BRACKET.match(text, i + 2)
            if match:
                level = match.group(1)
                closer = "]" + level + "]"
                end = text.find(closer, match.end())
                if end == -1:
                    raise ValueError("unterminated long comment at offset %d" % i)
                i = end + len(closer)
                continue
            end = text.find("\n", i)
            i = length if end == -1 else end
            continue

        if ch in "\"'":
            quote = ch
            i += 1
            while i < length:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == quote:
                    break
                if text[i] == "\n":
                    raise ValueError("unterminated string at offset %d" % i)
                i += 1
            else:
                raise ValueError("unterminated string at end of file")
            i += 1
            out.append('""')
            continue

        out.append(ch)
        i += 1

    return "".join(out)


def check(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    try:
        stripped = strip_source(text)
    except ValueError as exc:
        return [f"{path.name}: {exc}"]

    tokens = IDENT.findall(stripped)

    openers = sum(1 for token in tokens if token in {"function", "if", "for", "while"})
    closers = sum(1 for token in tokens if token == "end")
    repeats = sum(1 for token in tokens if token == "repeat")
    untils = sum(1 for token in tokens if token == "until")

    problems: list[str] = []
    if openers != closers:
        problems.append(f"{path.name}: {openers} block openers vs {closers} end (delta {openers - closers:+d})")
    if repeats != untils:
        problems.append(f"{path.name}: {repeats} repeat vs {untils} until")

    for pair in ("()", "{}", "[]"):
        opened = stripped.count(pair[0])
        closed = stripped.count(pair[1])
        if opened != closed:
            problems.append(f"{path.name}: unbalanced {pair[0]}{pair[1]} ({opened} vs {closed})")

    # `if`/`elseif` must reach a `then` before the next statement keyword.
    for match in re.finditer(r"\b(?:if|elseif)\b", stripped):
        tail = stripped[match.end() : match.end() + 400]
        stop = re.search(r"\b(?:do|end|function|return|local)\b", tail)
        window = tail if stop is None else tail[: stop.start()]
        if "\nthen" not in window and not window.strip().startswith("then"):
            if "then" not in window:
                line = text.count("\n", 0, match.start()) + 1
                problems.append(f"{path.name}:{line}: if/elseif without then")

    return problems


def main() -> int:
    targets = sorted((ROOT / "src").rglob("*.lua"))
    targets.append(ROOT / "release" / "dolo-hook.lua")
    targets.append(ROOT / "loadstring.lua")

    failures: list[str] = []
    for path in targets:
        problems = check(path)
        status = "ok" if not problems else "FAIL"
        print(f"{status:4} {path.relative_to(ROOT)}")
        failures.extend(problems)

    for problem in failures:
        print("  " + problem)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
