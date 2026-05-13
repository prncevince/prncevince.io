#!/usr/bin/env python3
"""
Post-process Quarto listings.json files.

Converts:
    /posts/index.html        -> /posts/
    /posts/example/index.html -> /posts/example/
    /index.html              -> /

Designed for:
- Quarto
- Vercel trailingSlash=true
- Canonical trailing-slash SEO
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
    """

    if not isinstance(url, str):
        return url

    # Root edge cases
    if url == "index.html":
        return "/"

    if url == "/index.html":
        return "/"

    # Replace trailing index.html
    if url.endswith("/index.html"):
        url = url[:-10]

    # Ensure trailing slash
    if url and not url.endswith("/"):
        if "." not in Path(url).name:
            url += "/"

    return url


# ============================================================================
# listings.json processing
# ============================================================================

def process_listings_json(path: Path) -> None:

    print(f"[listings.json] Processing: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR reading {path}: {e}")
        return

    if not isinstance(data, list):
        print(f"Skipping {path} (not JSON array)")
        return

    modified = 0

    for entry in data:

        if not isinstance(entry, dict):
            continue

        # ------------------------------------------------------------------
        # listing
        # ------------------------------------------------------------------

        listing = entry.get("listing")

        if isinstance(listing, str):
            new_listing = canonicalize_url(listing)

            if new_listing != listing:
                entry["listing"] = new_listing
                modified += 1

        # ------------------------------------------------------------------
        # items
        # ------------------------------------------------------------------

        items = entry.get("items")

        if isinstance(items, list):

            new_items = []

            for item in items:

                if isinstance(item, str):
                    new_item = canonicalize_url(item)

                    if new_item != item:
                        modified += 1

                    new_items.append(new_item)

                else:
                    new_items.append(item)

            entry["items"] = new_items

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

    files = list(root.rglob("listings.json"))

    if not files:
        print("No listings.json files found")
        return

    for file in files:
        process_listings_json(file)

    print("Done.")


# ============================================================================
# Entry
# ============================================================================

if __name__ == "__main__":
    main()