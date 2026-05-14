#!/usr/bin/env python3

"""
normalize_html_urls.py

Post-process rendered Quarto HTML output to normalize:

    /path/index.html        -> /path/
    /path/index.html#frag  -> /path/#frag
    /path/index.html?q=1   -> /path/?q=1

Designed for static-site SEO canonicalization.

Safe for:
- href attributes
- src attributes (optional toggle)
- canonical tags
- OpenGraph URLs
- Twitter URLs
- JSON-LD embedded URLs

Recommended usage:
    python scripts/normalize_html_urls.py _site

Run AFTER `quarto render` as `post-render:`:
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import urljoin

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------

HTML_EXTENSIONS = {".html"}
SITE_URL = "https://prncevince.xyz"

# Rewrite src="" URLs too?
# Usually False is safest because JS/CSS asset paths may intentionally use files.
REWRITE_SRC_ATTRIBUTES = False

# Verbose output
VERBOSE = True

# -----------------------------------------------------------------------------
# CANONICAL HELPERS
# -----------------------------------------------------------------------------

CANONICAL_PATTERN = re.compile(
    r'<link\s+rel=["\']canonical["\']\s+href=["\'][^"\']*["\']\s*/?>',
    re.IGNORECASE,
)

OG_URL_PATTERN = re.compile(
    r'<meta\s+property=["\']og:url["\']\s+content=["\'][^"\']*["\']\s*/?>',
    re.IGNORECASE,
)

HEAD_CLOSE_PATTERN = re.compile(r"</head>", re.IGNORECASE)

def build_canonical_url(site_dir: Path, html_path: Path) -> str:
    """
    Convert filesystem HTML path into canonical URL.

    Examples:
        _site/index.html
            -> https://prncevince.xyz

        _site/posts/index.html
            -> https://prncevince.xyz/posts/

        _site/foo/bar/index.html
            -> https://prncevince.xyz/foo/bar/
    """

    rel = html_path.relative_to(site_dir)

    parts = list(rel.parts)

    # remove trailing index.html
    if parts[-1] == "index.html":
        parts = parts[:-1]

    # homepage
    if len(parts) == 0:
        return SITE_URL

    url_path = "/".join(parts) + "/"

    return urljoin(SITE_URL + "/", url_path)


def inject_or_replace_canonical(
    html: str,
    canonical_url: str,
) -> tuple[str, bool]:
    """
    Replace existing canonical or inject a new one.
    """

    canonical_tag = (
        f'<link rel="canonical" href="{canonical_url}"/>'
    )

    changed = False

    # replace existing canonical
    if CANONICAL_PATTERN.search(html):
        html = CANONICAL_PATTERN.sub(canonical_tag, html)
        changed = True

    else:
        # inject before </head>
        html, n = HEAD_CLOSE_PATTERN.subn(
            canonical_tag + "\n</head>",
            html,
            count=1,
        )

        if n > 0:
            changed = True

    return html, changed

def inject_or_replace_og_url(
    html: str,
    canonical_url: str,
) -> tuple[str, bool]:
    """
    Replace existing og:url or inject a new one.
    """

    og_url_tag = (
        f'<meta property="og:url" content="{canonical_url}"/>'
    )

    changed = False

    # Replace existing tag
    if OG_URL_PATTERN.search(html):
        html = OG_URL_PATTERN.sub(og_url_tag, html)
        changed = True

    else:
        # Prefer inserting immediately after canonical tag
        canonical_match = CANONICAL_PATTERN.search(html)

        if canonical_match:
            insert_pos = canonical_match.end()

            html = (
                html[:insert_pos]
                + "\n"
                + og_url_tag
                + html[insert_pos:]
            )

            changed = True

        else:
            # Fallback: inject before </head>
            html, n = HEAD_CLOSE_PATTERN.subn(
                og_url_tag + "\n</head>",
                html,
                count=1,
            )

            if n > 0:
                changed = True

    return html, changed

# -----------------------------------------------------------------------------
# REGEXES
# -----------------------------------------------------------------------------

# Matches:
#
# href="/foo/index.html"
# href="/foo/index.html#bar"
# href="/foo/index.html?x=1"
#
# Captures:
#   1 = prefix (href=")
#   2 = path before /index.html
#   3 = suffix (#..., ?..., or empty)
#   4 = closing quote
#
HREF_PATTERN = re.compile(
    r'''(href=["'])           # attribute start
        ([^"']*?)             # URL before /index.html
        /index\.html          # literal
        ([#?][^"']*)?         # optional fragment/query
        (["'])                # closing quote
    ''',
    re.VERBOSE,
)

SRC_PATTERN = re.compile(
    r'''(src=["'])
        ([^"']*?)
        /index\.html
        ([#?][^"']*)?
        (["'])
    ''',
    re.VERBOSE,
)

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

def normalize_match(match: re.Match) -> str:
    prefix = match.group(1)
    path = match.group(2)
    suffix = match.group(3) or ""
    closing = match.group(4)

    # Avoid double slash edge case
    if path.endswith("/"):
        normalized = f"{path}{suffix}"
    else:
        normalized = f"{path}/{suffix}"

    return f"{prefix}{normalized}{closing}"


# -----------------------------------------------------------------------------
# MAIN FILE PROCESSOR
# -----------------------------------------------------------------------------

def process_html_file(path: Path, site_dir: Path) -> tuple[bool, int]:
    original = path.read_text(encoding="utf-8")

    updated, href_count = HREF_PATTERN.subn(normalize_match, original)

    src_count = 0

    if REWRITE_SRC_ATTRIBUTES:
        updated, src_count = SRC_PATTERN.subn(
            normalize_match,
            updated,
        )

    total = href_count + src_count

    # -------------------------------------------------------------------------
    # Canonicals
    # -------------------------------------------------------------------------

    canonical_url = build_canonical_url(site_dir, path)

    updated, canonical_changed = inject_or_replace_canonical(
        updated,
        canonical_url,
    )

    if canonical_changed:
        total += 1

    # -------------------------------------------------------------------------
    # Open Graph URL
    # -------------------------------------------------------------------------

    updated, og_changed = inject_or_replace_og_url(
        updated,
        canonical_url,
    )

    if og_changed:
        total += 1

    # -------------------------------------------------------------------------
    # Write
    # -------------------------------------------------------------------------

    if updated != original:
        path.write_text(updated, encoding="utf-8")

    return updated != original, total


# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

def main() -> int:
    if len(sys.argv) != 2:
        print("Usage:")
        print("  python normalize_html_urls.py <site_directory>")
        return 1

    site_dir = Path(sys.argv[1]).resolve()

    if not site_dir.exists():
        print(f"ERROR: directory does not exist: {site_dir}")
        return 1

    html_files = [
        p for p in site_dir.rglob("*")
        if p.is_file() and p.suffix.lower() in HTML_EXTENSIONS
    ]

    changed_files = 0
    total_rewrites = 0

    for html_file in html_files:
        changed, rewrites = process_html_file(html_file, site_dir)

        if changed:
            changed_files += 1
            total_rewrites += rewrites

            if VERBOSE:
                rel = html_file.relative_to(site_dir)
                print(f"[rewrite] {rel} ({rewrites} replacements)")

    print()
    print("Normalization complete")
    print(f"Files scanned:   {len(html_files)}")
    print(f"Files modified:  {changed_files}")
    print(f"Total rewrites:  {total_rewrites}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())