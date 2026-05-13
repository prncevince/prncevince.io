#!/usr/bin/env python3
"""
Post-process Quarto search.json files.

Converts:
    path/index.html       -> path/
    /path/index.html      -> /path/
    index.html            -> /

Preserves hash fragments:
    path/index.html#foo   -> path/#foo

Designed for:
- Quarto
- Vercel trailingSlash=true
- Canonical trailing slash SEO
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


# ============================================================================
# URL canonicalization
# ============================================================================

def canonicalize_url(url: str) -> str:
    """
    Convert Quarto index.html URLs into trailing-slash canonical URLs.

    Examples
    --------
    index.html
        -> /

    posts/index.html
        -> posts/

    /posts/index.html
        -> /posts/

    posts/index.html#intro
        -> posts/#intro
    """

    if not isinstance(url, str):
        return url

    # Separate hash fragment
    if "#" in url:
        base, fragment = url.split("#", 1)
        fragment = "#" + fragment
    else:
        base = url
        fragment = ""

    # Normalize root index.html
    if base == "index.html":
        return "/" + fragment

    if base == "/index.html":
        return "/" + fragment

    # Replace trailing index.html
    if base.endswith("/index.html"):
        base = base[:-10]  # remove "index.html"

    # Ensure trailing slash for directory paths
    if base and not base.endswith("/"):
        # only if path-like and extensionless
        if "." not in Path(base).name:
            base += "/"

    return base + fragment


# ============================================================================
# JSON processing
# ============================================================================

def process_search_json(path: Path) -> None:
    """
    Rewrite href/objectID URLs inside a Quarto search.json file.
    """

    print(f"[search.json] Processing: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR reading {path}: {e}")
        return

    if not isinstance(data, list):
        print(f"Skipping {path} (not a JSON array)")
        return

    modified = 0

    for item in data:

        if not isinstance(item, dict):
            continue

        # ------------------------------------------------------------------
        # href
        # ------------------------------------------------------------------

        href = item.get("href")

        if isinstance(href, str):
            new_href = canonicalize_url(href)

            if new_href != href:
                item["href"] = new_href
                modified += 1

        # ------------------------------------------------------------------
        # objectID
        # ------------------------------------------------------------------

        object_id = item.get("objectID")

        if isinstance(object_id, str):
            new_object_id = canonicalize_url(object_id)

            if new_object_id != object_id:
                item["objectID"] = new_object_id
                modified += 1

    # ----------------------------------------------------------------------
    # Write updated file
    # ----------------------------------------------------------------------

    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False),
        encoding="utf-8"
    )

    print(f"Updated {modified} URL fields.")


# ============================================================================
# Recursive discovery
# ============================================================================

def main() -> None:

    root = Path("_site")

    if not root.exists():
        print("ERROR: _site directory not found")
        sys.exit(1)

    files = list(root.rglob("search.json"))

    if not files:
        print("No search.json files found")
        return

    for file in files:
        process_search_json(file)

    print("Done.")


# ============================================================================
# Entry
# ============================================================================

if __name__ == "__main__":
    main()