#!/usr/bin/env python3
"""Build a staging directory of hoard investigation artifacts + a manifest.

Usage:
    python3 .github/scripts/build_staging.py <repo_root> <staging_dir>

Discovers every top-level directory in <repo_root> that directly contains an
index.html, copies each index.html into <staging_dir>/<slug>/index.html, and
writes <staging_dir>/manifest.json describing the set of projects.

Stdlib only, so it can be run/tested locally without dependencies. Untrusted
folder names are only ever passed to git via subprocess list-args (never a
shell), so there is no shell-injection surface here.
"""

import html
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

# Directory names we never treat as investigation folders.
_TITLE_RE = re.compile(r"<title[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)
_WS_RE = re.compile(r"\s+")


def warn(message):
    """Emit a GitHub Actions warning annotation (harmless locally).

    The message is escaped per Actions workflow-command rules so untrusted
    content (e.g. a folder name containing a newline) cannot inject a second
    workflow command. Order matters: % first, then CR, then LF.
    """
    escaped = (
        str(message)
        .replace("%", "%25")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )
    print(f"::warning::{escaped}")


def extract_title(html_path, slug):
    """Return the decoded, whitespace-collapsed <title>, or the slug."""
    try:
        with open(html_path, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError as exc:
        warn(f"could not read {html_path}: {exc}")
        return slug

    match = _TITLE_RE.search(content)
    if not match:
        return slug

    title = html.unescape(match.group(1))
    title = _WS_RE.sub(" ", title).strip()
    return title or slug


def git_dates(repo_root, rel_path):
    """Return (created, updated) YYYY-MM-DD dates from git history.

    Falls back to today's date for both if the file has no commits yet.
    """
    try:
        out = subprocess.run(
            ["git", "log", "--follow", "--format=%as", "--", rel_path],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    except (subprocess.CalledProcessError, OSError) as exc:
        warn(f"git log failed for {rel_path}: {exc}")
        out = ""

    dates = [line.strip() for line in out.splitlines() if line.strip()]
    if not dates:
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        return today, today

    # git log lists newest first: dates[0] = last commit, dates[-1] = first.
    updated = dates[0]
    created = dates[-1]
    return created, updated


def discover(repo_root):
    """Yield (slug, index_path) for each qualifying top-level directory.

    Symlinks are refused: a committed symlink (either the top-level folder
    itself or its index.html) could otherwise publish arbitrary files from
    outside the checkout to the public bucket.
    """
    real_root = os.path.realpath(repo_root)
    for name in sorted(os.listdir(repo_root)):
        if name.startswith("."):
            continue
        dir_path = os.path.join(repo_root, name)
        if not os.path.isdir(dir_path):
            continue
        if os.path.islink(dir_path):
            warn(
                f"top-level folder '{name}' is a symlink; "
                f"skipping (not published)"
            )
            continue
        index_path = os.path.join(dir_path, "index.html")
        if not os.path.isfile(index_path):
            warn(
                f"top-level folder '{name}' has no index.html; "
                f"skipping (not published)"
            )
            continue
        if os.path.islink(index_path):
            warn(
                f"'{name}/index.html' is a symlink; "
                f"skipping (not published)"
            )
            continue
        real_index = os.path.realpath(index_path)
        if os.path.commonpath([real_root, real_index]) != real_root:
            warn(
                f"'{name}/index.html' resolves outside the repository; "
                f"skipping (not published)"
            )
            continue
        yield name, index_path


def build(repo_root, staging_dir):
    projects = []
    os.makedirs(staging_dir, exist_ok=True)

    for slug, index_path in discover(repo_root):
        dest_dir = os.path.join(staging_dir, slug)
        os.makedirs(dest_dir, exist_ok=True)
        dest_path = os.path.join(dest_dir, "index.html")
        # Copy bytes verbatim.
        with open(index_path, "rb") as src, open(dest_path, "wb") as dst:
            dst.write(src.read())

        title = extract_title(index_path, slug)
        rel_path = f"{slug}/index.html"
        created, updated = git_dates(repo_root, rel_path)

        projects.append(
            {
                "slug": slug,
                "title": title,
                "created": created,
                "updated": updated,
            }
        )

    if not projects:
        print(
            "ERROR: no qualifying folders found (none contain index.html). "
            "Something is badly wrong; refusing to publish an empty manifest.",
            file=sys.stderr,
        )
        return 1

    # Sort primary: created DESC; secondary: slug ASC (stable tiebreak).
    # Python's sort is stable, so sort by the secondary key first, then the
    # primary key, to get the combined ordering right.
    projects.sort(key=lambda p: p["slug"])
    projects.sort(key=lambda p: p["created"], reverse=True)

    manifest = {
        "generated_at": datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
        "projects": projects,
    }

    manifest_path = os.path.join(staging_dir, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    print(f"Staged {len(projects)} project(s) into {staging_dir}:")
    for proj in projects:
        print(
            f"  - {proj['slug']}: {proj['title']!r} "
            f"(created {proj['created']}, updated {proj['updated']})"
        )
    print(f"Wrote manifest: {manifest_path}")
    return 0


def main(argv):
    if len(argv) != 3:
        print(
            "Usage: build_staging.py <repo_root> <staging_dir>",
            file=sys.stderr,
        )
        return 2
    repo_root = os.path.abspath(argv[1])
    staging_dir = os.path.abspath(argv[2])

    if not os.path.isdir(repo_root):
        print(f"ERROR: repo_root is not a directory: {repo_root}", file=sys.stderr)
        return 2

    return build(repo_root, staging_dir)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
