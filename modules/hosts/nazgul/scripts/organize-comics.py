"""Sort manga and comics into a clean Komga layout.

    <dest>/<Series>/<Series> v01.cbz      volumes
    <dest>/<Series>/<Series> #001.cbz     issues / chapters
    <dest>/<Series> (Chapters)/...        loose chapters of a series that
                                          also has volumes (e.g. Chainsaw Man)

Dry run by default: prints the plan as "old -> new" lines and changes
nothing. --apply moves the files (same filesystem, so instant) and writes
an undo log; --undo <log> moves everything back.
"""

import argparse
import os
import re
import sys
import time
import unicodedata

# EPUB too, for manga released that way (Komga reads EPUB)
COMIC_EXT = {".cbz", ".cbr", ".cb7", ".epub"}
# Words that describe a folder rather than name a series
GENERIC = {"manga", "comics", "comic", "collection", "complete", "cbz", "cbr", "pdf"}
# Suffixes added to series names; ignored when matching file names
SUFFIX_RE = re.compile(r"\s+\((?:Colored|One-shots|Chapters)\)$")


def clean(name):
    """Drop release tags, years, numbering prefixes and volume ranges."""
    s = name.replace("_", " ")
    s = re.sub(r"\[[^\]]*\]|\([^)]*\)|\{[^}]*\}", " ", s)
    s = re.sub(r"^\s*\d+\.\s+", "", s)  # "1. Elric of Melnibone"
    # "v01-10", "Vol. 1 - 3", "v01-v27"
    s = re.sub(r"\s+v(?:ol\.?)?\s*\d+\s*[-–]\s*v?\d+\s*$", "", s, flags=re.I)
    s = re.sub(r"\s+", " ", s).strip(" -–.,")
    return s


def words(s):
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    w = re.findall(r"[a-z0-9]+", s)
    if w and w[0] == "the":
        w = w[1:]
    return w


def safe(name):
    return name.replace("/", "-").replace(":", " -").strip()


def strip_generic(name):
    """'Dragon Ball Super Manga' -> 'Dragon Ball Super'; 'cbz' -> ''"""
    parts = name.split()
    while parts and parts[-1].lower() in GENERIC:
        parts.pop()
    return " ".join(parts)


def series_name(rel_dirs, root_label):
    """Series from the folder path below the source root."""
    dirs = list(rel_dirs)
    # "Dorohedoro/cbz": format folders belong to their parent
    while dirs and not strip_generic(clean(dirs[-1])):
        dirs.pop()
    if not dirs:
        return root_label
    leaf = strip_generic(clean(dirs[-1])) or dirs[-1]
    if len(dirs) >= 2:
        parent = strip_generic(clean(dirs[-2]))
        pw = words(parent)
        # "Vagabond/Art Books" -> "Vagabond - Art Books"; keep leaves that
        # already name the series ("Hawkmoon/Hawkmoon The Runestaff")
        if pw and pw[0] not in words(leaf):
            leaf = f"{parent} - {leaf}"
    # Keep colored editions apart from the originals
    if re.search(r"colou?red", dirs[-1], re.I):
        leaf = re.sub(r"\s*\bcolou?red\b.*$", "", leaf, flags=re.I) + " (Colored)"
    return leaf


VOL_RE = re.compile(r"^(?:-\s*)?(?:v|vol\.?\s*|volume\s+)(\d+(?:\.\d+)?)\b", re.I)
NUM_RE = re.compile(r"^(?:-\s*)?#?(\d+(?:\.\d+)?)(?:\s*of\s*\d+)?\b", re.I)
TRAIL_RE = re.compile(r"(\d+(?:\.\d+)?)\s*(?:of\s*\d+)?\s*$", re.I)


def parse(stem, series):
    """-> ("vol"|"num"|None, number, cleaned stem)"""
    c = clean(stem)
    sw, cw = words(SUFFIX_RE.sub("", series)), words(c)
    if sw and cw[: len(sw)] == sw:
        # Text after the series name: "v01 ...", "01 of 7", "155"
        rest = c
        for w in sw:
            m = re.search(re.escape(w), unicodedata.normalize("NFKD", rest).lower())
            rest = rest[m.end():] if m else rest
        rest = rest.strip(" -–,")
        m = VOL_RE.match(rest)
        if m:
            return "vol", m.group(1), c
        m = NUM_RE.match(rest)
        if m:
            return "num", m.group(1), c
    elif sw and cw and cw[0] == sw[0]:
        # Same series, slightly different title ("Corum - The Bull & the
        # Spear 01" in "Corum The Bull and the Spear")
        m = TRAIL_RE.search(c)
        if m:
            return "num", m.group(1), c
    return None, None, c


def run_prefix(filename):
    """Title before the first number: 'Dragon Ball Z 03.cbz' -> 'Dragon Ball Z'"""
    c = clean(os.path.splitext(filename)[0])
    m = re.search(r"[\s,#-]*(?:v|vol\.?\s*|volume\s+)?\d+(?:\.\d+)?\b.*$", c, re.I)
    return (c[: m.start()] if m else "").strip(" ,-\u2013")


def pad(n, width):
    whole, _, frac = n.partition(".")
    return whole.lstrip("0").zfill(width) + (f".{frac}" if frac else "")


def plan(sources, dest):
    moves, skipped = [], []
    for src, kind, label in sources:
        if not os.path.isdir(src):
            print(f"# missing source, skipped: {src}", file=sys.stderr)
            continue
        groups = {}  # series -> [(path, ext, kind, num, cleaned)]
        for dirpath, dirnames, filenames in os.walk(src):
            # Skip hidden folders, e.g. a file manager's .Trash-1000
            dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
            filenames = [f for f in filenames if not f.startswith(".")]
            rel = os.path.relpath(dirpath, src)
            rel_dirs = [] if rel == "." else rel.split(os.sep)
            comics = sorted(f for f in filenames if os.path.splitext(f)[1].lower() in COMIC_EXT)
            skipped += [os.path.join(dirpath, f) for f in sorted(filenames) if f not in comics]
            if not comics:
                continue
            series = series_name(rel_dirs, label)
            has_subseries = any(
                os.path.splitext(f)[1].lower() in COMIC_EXT
                for sub, _, fs in os.walk(dirpath)
                if sub != dirpath and "/." not in sub
                for f in fs
            )
            # Loose files next to sub-series folders: a real run of volumes
            # when most of them start with the series name, otherwise
            # unrelated one-shots
            if has_subseries or not rel_dirs:
                sw = words(series)
                named = sum(1 for f in comics if words(clean(f))[: len(sw)] == sw)
                if named * 2 < len(comics):
                    series = f"{series} (One-shots)"
            # One folder holding several numbered runs ("Dragon Ball 01..16"
            # and "Dragon Ball Z 01..26") becomes one series per run
            runs = {}
            for f in comics:
                runs.setdefault(run_prefix(f), []).append(f)
            split = "(One-shots)" not in series and sum(len(v) >= 2 for k, v in runs.items() if k) >= 2
            for f in comics:
                stem, ext = os.path.splitext(f)
                if stem.lower().endswith(".cbr"):  # "x.cbr.cbz"
                    stem = stem[:-4]
                s = series
                if split and run_prefix(f) and len(runs[run_prefix(f)]) >= 2:
                    s = run_prefix(f)
                k, n, c = parse(stem, s) if "(One-shots)" not in s else (None, None, clean(stem))
                groups.setdefault(s, []).append((os.path.join(dirpath, f), ext.lower(), k, n, c))

        for series, items in groups.items():
            kinds = {k for _, _, k, _, _ in items}
            for path, ext, k, n, c in items:
                s = series
                if k == "num" and "vol" in kinds:
                    s = f"{series} (Chapters)"
                if k:
                    same = [x[3] for x in items if x[2] == k]
                    width = max(2, max(len(x.split(".")[0].lstrip("0") or "0") for x in same))
                    name = f"{series} v{pad(n, width)}" if k == "vol" else f"{series} #{pad(n, width)}"
                else:
                    # Unnumbered: keep the title, including "(from Epic
                    # Illustrated 20)"-style notes; drop only [tags]
                    stem = os.path.splitext(os.path.basename(path))[0]
                    stem = re.sub(r"\.cbr$", "", stem, flags=re.I)
                    name = re.sub(r"\s+", " ", re.sub(r"\[[^\]]*\]", " ", stem)).strip() or c
                moves.append((path, os.path.join(dest, kind, safe(s), safe(name) + ext)))

    # Never let two files land on the same name
    seen, out = {}, []
    for old, new in moves:
        base, ext = os.path.splitext(new)
        i = 1
        while new in seen or (os.path.exists(new) and os.path.realpath(new) != os.path.realpath(old)):
            i += 1
            new = f"{base} ({i}){ext}"
        seen[new] = old
        out.append((old, new))
    return out, skipped


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--media", default="/srv/data/media", help="media subvolume (default: %(default)s)")
    p.add_argument("--apply", action="store_true", help="move the files")
    p.add_argument("--undo", metavar="LOG", help="move files back using an undo log")
    a = p.parse_args()

    if a.undo:
        with open(a.undo) as fh:
            pairs = [line.rstrip("\n").split("\t") for line in fh if line.strip()]
        for new, old in reversed(pairs):
            os.makedirs(os.path.dirname(old), exist_ok=True)
            os.rename(new, old)
        print(f"Restored {len(pairs)} files")
        return

    lit = os.path.join(a.media, "library", "lit")
    sources = [
        (os.path.join(lit, "manga"), "manga", "Manga"),
        (os.path.join(lit, "comics"), "comics", "Comics"),
        (os.path.join(lit, "books", "Michael Moorcock Comics"), "comics", "Michael Moorcock"),
    ]
    moves, skipped = plan(sources, os.path.join(a.media, "library"))

    for old, new in moves:
        print(f"{os.path.relpath(old, lit)}\n    -> {os.path.relpath(new, os.path.join(a.media, 'library'))}")
    print(f"\n{len(moves)} comics to move")
    if skipped:
        print(f"{len(skipped)} other files left in place (not comics):")
        for s in skipped:
            print(f"    {os.path.relpath(s, lit)}")

    if not a.apply:
        print("\nDry run, nothing changed. Re-run with --apply to move the files.")
        return

    log = os.path.join(a.media, "library", f".organize-comics-{time.strftime('%Y%m%d-%H%M%S')}.undo")
    with open(log, "w") as fh:
        for old, new in moves:
            os.makedirs(os.path.dirname(new), exist_ok=True)
            os.rename(old, new)
            fh.write(f"{new}\t{old}\n")
            fh.flush()
    print(f"\nMoved {len(moves)} files. Undo with: organize-comics --undo '{log}'")


if __name__ == "__main__":
    main()
