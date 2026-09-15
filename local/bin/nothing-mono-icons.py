#!/usr/bin/env python3
"""Nothing-Mono: a monochrome (luminance) copy of an icon theme for the Nothing shell.

Rewrites every colour an SVG carries (fill/stroke/stop-color/color as hex or rgb()) to its grey,
converts embedded base64 rasters to greyscale, de-duplicates identical files into symlinks,
and writes a new index.theme. A second phase greys the app icons the base theme lacks (hicolor,
flatpak exports, pixmaps) into apps/<size>/, so launchers don't fall back to colour for them.
Re-run any time (e.g. after installing apps); the target is rebuilt from scratch.

  nothing-mono-icons.py [SRC] [DST]   defaults: ~/.icons/Flat-Remix-Blue-Dark -> ~/.icons/Nothing-Mono
"""
import base64, hashlib, io, os, re, shutil, sys
from multiprocessing import Pool
from PIL import Image

SRC = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/.icons/Flat-Remix-Blue-Dark")
DST = os.path.expanduser(sys.argv[2] if len(sys.argv) > 2 else "~/.icons/Nothing-Mono")
NAME = os.path.basename(DST)

PROP = re.compile(
    r"(?P<prop>\b(?:fill|stroke|stop-color|flood-color|lighting-color|solid-color|color))"
    r"(?P<sep>\s*[:=]\s*[\"']?)"
    r"(?P<val>#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\))")
DATA = re.compile(r"(data:image/)(png|jpe?g|gif|webp|bmp|svg\+xml)(;base64,)([A-Za-z0-9+/=\s]+)")


def luma(r, g, b):
    return max(0, min(255, round(0.299 * r + 0.587 * g + 0.114 * b)))


def grey_hex(h):
    h = h[1:]
    if len(h) in (3, 4):
        r, g, b = (int(c * 2, 16) for c in h[:3])
        alpha = h[3] * 2 if len(h) == 4 else ""
    elif len(h) in (6, 8):
        r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
        alpha = h[6:]
    else:
        return "#" + h
    y = luma(r, g, b)
    return "#%02x%02x%02x%s" % (y, y, y, alpha)


def grey_rgb(v):
    inner = v[v.index("(") + 1:v.rindex(")")]
    parts = [p.strip() for p in re.split(r"[,\s/]+", inner) if p.strip()]
    if len(parts) < 3:
        return v
    def chan(p):
        return round(float(p[:-1]) * 2.55) if p.endswith("%") else round(float(p))
    try:
        y = luma(chan(parts[0]), chan(parts[1]), chan(parts[2]))
    except ValueError:
        return v
    rest = ", " + parts[3] if len(parts) > 3 else ""
    return "%s(%d, %d, %d%s)" % (v[:v.index("(")], y, y, y, rest)


def grey_prop(m):
    val = m.group("val")
    out = grey_hex(val) if val.startswith("#") else grey_rgb(val)
    return m.group("prop") + m.group("sep") + out


def grey_data(m):
    kind, payload = m.group(2), m.group(4)
    try:
        raw = base64.b64decode("".join(payload.split()))
        if kind == "svg+xml":
            out = convert_svg(raw.decode("utf-8")).encode("utf-8")
            return m.group(1) + kind + m.group(3) + base64.b64encode(out).decode("ascii")
        img = Image.open(io.BytesIO(raw))
        has_alpha = img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and "transparency" in img.info)
        img = img.convert("RGBA").convert("LA") if has_alpha else img.convert("L")
        buf = io.BytesIO()
        img.save(buf, format="PNG", optimize=True)
        return m.group(1) + "png" + m.group(3) + base64.b64encode(buf.getvalue()).decode("ascii")
    except Exception:
        return m.group(0)


def convert_svg(text):
    text = PROP.sub(grey_prop, text)
    text = DATA.sub(grey_data, text)
    return text


def convert_one(job):
    rel, dsts = job
    src = os.path.join(SRC, rel)
    first = os.path.join(DST, dsts[0])
    os.makedirs(os.path.dirname(first), exist_ok=True)
    if rel.lower().endswith(".svg"):
        with open(src, encoding="utf-8", errors="surrogateescape") as f:
            text = f.read()
        with open(first, "w", encoding="utf-8", errors="surrogateescape") as f:
            f.write(convert_svg(text))
    elif rel.lower().endswith((".png", ".jpg", ".jpeg")):
        img = Image.open(src)
        has_alpha = img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and "transparency" in img.info)
        (img.convert("RGBA").convert("LA") if has_alpha else img.convert("L")).save(first)
    else:
        shutil.copy2(src, first)
    for dup in dsts[1:]:
        p = os.path.join(DST, dup)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        os.symlink(os.path.relpath(first, os.path.dirname(p)), p)
    return len(dsts)


EXTRA_THEME_DIRS = [
    "/usr/share/icons/hicolor",
    "~/.local/share/icons/hicolor",
    "/var/lib/flatpak/exports/share/icons/hicolor",
    "~/.local/share/flatpak/exports/share/icons/hicolor",
]
PIXMAP_DIRS = ["/usr/share/pixmaps", "~/.local/share/pixmaps"]


def gather_extras():
    """App icons the base theme lacks, as {(name, sizedir): source path}; sizedir is "scalable" or "48"."""
    have = set()
    for root, _, files in os.walk(os.path.join(DST, "apps")):
        have.update(os.path.splitext(f)[0] for f in files)
    found = {}
    for base in EXTRA_THEME_DIRS:
        base = os.path.expanduser(base)
        if not os.path.isdir(base):
            continue
        for sizedir in os.listdir(base):
            appsdir = os.path.join(base, sizedir, "apps")
            if not os.path.isdir(appsdir):
                continue
            m = re.fullmatch(r"(\d+)x\d+", sizedir)
            key = "scalable" if sizedir == "scalable" else m.group(1) if m else None
            if key is None:
                continue
            for f in os.listdir(appsdir):
                name, ext = os.path.splitext(f)
                ext = ext.lower()
                if name in have or ext not in (".png", ".svg") or (ext == ".png" and key == "scalable"):
                    continue
                found.setdefault((name, key), os.path.join(appsdir, f))
    for base in PIXMAP_DIRS:
        base = os.path.expanduser(base)
        if not os.path.isdir(base):
            continue
        for f in os.listdir(base):
            name, ext = os.path.splitext(f)
            ext = ext.lower()
            path = os.path.join(base, f)
            if name in have or not os.path.isfile(path):
                continue
            if ext == ".svg":
                found.setdefault((name, "scalable"), path)
            elif ext == ".png":
                try:
                    w, h = Image.open(path).size
                except Exception:
                    continue
                if w == h:
                    found.setdefault((name, str(w)), path)
    return found


def convert_extra(job):
    (name, key), src = job
    ext = os.path.splitext(src)[1].lower()
    dst = os.path.join(DST, "apps", key, name + ext)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    try:
        if ext == ".svg":
            with open(src, encoding="utf-8", errors="surrogateescape") as f:
                text = f.read()
            with open(dst, "w", encoding="utf-8", errors="surrogateescape") as f:
                f.write(convert_svg(text))
        else:
            img = Image.open(src)
            has_alpha = img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and "transparency" in img.info)
            (img.convert("RGBA").convert("LA") if has_alpha else img.convert("L")).save(dst)
        return key
    except Exception as e:
        print(f"  skip {src}: {e}", flush=True)
        return None


def add_index_dirs(sizes):
    """Register apps/<N> directories for the extra PNG sizes in index.theme."""
    path = os.path.join(DST, "index.theme")
    with open(path, encoding="utf-8") as f:
        idx = f.read()
    m = re.search(r"^Directories=(.*)$", idx, flags=re.M)
    listed = m.group(1).split(",") if m else []
    new = [f"apps/{n}" for n in sorted(sizes, key=int) if f"apps/{n}" not in listed]
    if not new:
        return
    idx = idx.replace(m.group(0), "Directories=" + ",".join(listed + new), 1)
    for d in new:
        idx += f"\n[{d}]\nSize={d.split('/')[1]}\nContext=Applications\nType=Threshold\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(idx)


def main():
    if os.path.exists(DST):
        shutil.rmtree(DST)
    os.makedirs(DST)
    by_hash, order = {}, []
    for root, _, files in os.walk(SRC):
        for name in files:
            if name in ("index.theme", "icon-theme.cache"):
                continue
            path = os.path.join(root, name)
            rel = os.path.relpath(path, SRC)
            if os.path.islink(path):
                target = os.readlink(path)
                d = os.path.join(DST, rel)
                os.makedirs(os.path.dirname(d), exist_ok=True)
                os.symlink(target, d)
                continue
            with open(path, "rb") as f:
                h = hashlib.md5(f.read()).hexdigest()
            if h in by_hash:
                by_hash[h][1].append(rel)
            else:
                by_hash[h] = (rel, [rel])
                order.append(h)
    jobs = [by_hash[h] for h in order]
    print(f"{sum(len(j[1]) for j in jobs)} files, {len(jobs)} unique -> {DST}", flush=True)
    done = 0
    with Pool() as pool:
        for n in pool.imap_unordered(convert_one, jobs, chunksize=64):
            done += n
            if done % 5000 < n:
                print(f"  {done} written", flush=True)
    with open(os.path.join(SRC, "index.theme"), encoding="utf-8") as f:
        idx = f.read()
    idx = re.sub(r"^Name=.*$", f"Name={NAME}", idx, count=1, flags=re.M)
    idx = re.sub(r"^Comment=.*$", f"Comment=Monochrome build of {os.path.basename(SRC)} for the Nothing shell", idx, count=1, flags=re.M)
    with open(os.path.join(DST, "index.theme"), "w", encoding="utf-8") as f:
        f.write(idx)
    extras = gather_extras()
    print(f"{len(extras)} fallback app icons to grey", flush=True)
    sizes = set()
    with Pool() as pool:
        for key in pool.imap_unordered(convert_extra, list(extras.items()), chunksize=16):
            if key and key != "scalable":
                sizes.add(key)
    add_index_dirs(sizes)
    print("done", flush=True)


if __name__ == "__main__":
    main()
