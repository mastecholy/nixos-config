"""List videos in formats that nazgul (Intel UHD 630) or common players
handle badly, so they can be replaced or converted.

Flags
  AV1        no hardware decode on the UHD 630: CPU transcode when the
             player can't direct-play it
  HEVC-RExt  4:2:2/4:4:4 HEVC, no hardware decode on the UHD 630
  DV5        Dolby Vision profile 5: no HDR10 fallback, wrong colors when
             tone-mapped
  PGS-only   only image subtitles: burned in (full video transcode) when on
  HD-audio   only TrueHD/DTS audio: audio transcode on most TVs (cheap)
  legacy     MPEG-4 part 2 / DivX / WMV etc.: CPU decode, old files
  HDR        informational: tone-mapped (GPU) for SDR screens
  unreadable ffprobe found no video stream: damaged or incomplete file

Shows are summarised per series; --all lists every file.
"""

import argparse
import json
import os
import subprocess
import sys
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor

VIDEO_EXT = {".mkv", ".mp4", ".m4v", ".avi", ".mov", ".ts", ".m2ts", ".webm", ".wmv", ".mpg", ".mpeg"}
TEXT_SUBS = {"subrip", "ass", "ssa", "mov_text", "webvtt", "text"}
IMAGE_SUBS = {"hdmv_pgs_subtitle", "dvd_subtitle", "dvb_subtitle", "xsub"}
HD_AUDIO = {"truehd", "dts", "mlp"}
LEGACY = {"mpeg4", "msmpeg4v1", "msmpeg4v2", "msmpeg4v3", "wmv1", "wmv2", "wmv3", "h263", "rv40", "theora"}
ORDER = ["unreadable", "AV1", "HEVC-RExt", "DV5", "PGS-only", "HD-audio", "legacy", "HDR"]


def probe(path):
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-show_streams", "-of", "json", path],
            capture_output=True, text=True, timeout=120,
        ).stdout
        streams = json.loads(out or "{}").get("streams", [])
    except (subprocess.TimeoutExpired, json.JSONDecodeError):
        return ["unreadable"], ""
    video = [s for s in streams if s.get("codec_type") == "video" and not s.get("disposition", {}).get("attached_pic")]
    audio = {s.get("codec_name") for s in streams if s.get("codec_type") == "audio"}
    subs = {s.get("codec_name") for s in streams if s.get("codec_type") == "subtitle"}
    if not video:
        return ["unreadable"], ""
    v = video[0]
    codec, profile = v.get("codec_name", "?"), v.get("profile", "") or ""
    flags = []
    if codec == "av1":
        flags.append("AV1")
    if codec == "hevc" and "rext" in profile.lower().replace(" ", ""):
        flags.append("HEVC-RExt")
    for sd in v.get("side_data_list", []):
        if "DOVI" in sd.get("side_data_type", "") and sd.get("dv_profile") == 5:
            flags.append("DV5")
    if subs and subs <= IMAGE_SUBS:
        flags.append("PGS-only")
    if audio and audio <= HD_AUDIO:
        flags.append("HD-audio")
    if codec in LEGACY:
        flags.append("legacy")
    if v.get("color_transfer") in ("smpte2084", "arib-std-b67"):
        flags.append("HDR")
    desc = f"{codec} {v.get('width', '?')}x{v.get('height', '?')}"
    return flags, desc


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("dirs", nargs="*", default=["/srv/data/media/library/Movies", "/srv/data/media/library/Shows"])
    p.add_argument("--all", action="store_true", help="list every flagged file, not one line per series")
    p.add_argument("--hdr", action="store_true", help="also list files whose only flag is HDR")
    a = p.parse_args()

    files = []
    for d in a.dirs:
        for root, dirnames, names in os.walk(d):
            dirnames[:] = sorted(x for x in dirnames if not x.startswith("."))
            files += [os.path.join(root, n) for n in sorted(names) if os.path.splitext(n)[1].lower() in VIDEO_EXT and not n.startswith(".")]
    print(f"Scanning {len(files)} videos...", file=sys.stderr)

    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(zip(files, pool.map(probe, files)))

    totals = Counter()
    groups = defaultdict(lambda: [Counter(), 0, ""])  # series -> flags, episodes, example codec
    rows = []
    for path, (flags, desc) in results:
        totals.update(set(flags))
        shown = [f for f in flags if a.hdr or f != "HDR"]
        if not shown:
            continue
        top = next((d for d in a.dirs if path.startswith(d.rstrip("/") + "/")), "")
        rel = os.path.relpath(path, top) if top else path
        is_show = "show" in os.path.basename(top.rstrip("/")).lower()
        if is_show and not a.all:
            series = rel.split(os.sep)[0]
            g = groups[series]
            g[0].update(shown)
            g[1] += 1
            g[2] = desc
        else:
            rows.append((", ".join(f for f in ORDER if f in shown), desc, rel))

    if rows:
        print("\n# Files")
        for flags, desc, rel in sorted(rows):
            print(f"{flags:<22} {desc:<20} {rel}")
    if groups:
        print("\n# Shows (episodes affected)")
        for series, (fl, n, desc) in sorted(groups.items()):
            summary = ", ".join(f"{f} {fl[f]}" for f in ORDER if fl[f])
            print(f"{series}: {summary}   (e.g. {desc})")

    print(f"\n# Totals ({len(files)} videos)")
    for f in ORDER:
        if totals[f]:
            print(f"{f:<12} {totals[f]}")


if __name__ == "__main__":
    main()
