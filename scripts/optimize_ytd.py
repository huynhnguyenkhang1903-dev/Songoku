import os
import shutil
import tempfile
from pathlib import Path

from texfury import ITD, extract_dict
from PIL import Image, UnidentifiedImageError

MAX_DIMENSION = 2048
MIN_SIZE = 5 * 1024 * 1024

STREAMS = {
    "rpv_car_not_inshop": r"C:\Users\ADMIN\Downloads\server\server-data\resources\rpv_car_not_inshop\stream",
    "rpv_lawandservice_pack": r"C:\Users\ADMIN\Downloads\server\server-data\resources\rpv_lawandservice_pack\stream",
    "mp_gta5vn_roger_2026": r"C:\Users\ADMIN\Downloads\server\server-data\resources\mp_gta5vn_roger_2026\stream",
    "gta5vn_addoncloth": r"C:\Users\ADMIN\Downloads\server\server-data\resources\gta5vn_addoncloth\stream",
    "wp_cq300": r"C:\Users\ADMIN\Downloads\server\server-data\resources\[weapons]\wp_cq300\stream",
}

FORMAT_MAP = {
    0: "BC1", 1: "BC1", 2: "BC3", 3: "BC3",
    4: "BC5", 5: "BC5", 6: "BC7", 8: "BC7",
}


def get_format_name(tex) -> str:
    return FORMAT_MAP.get(tex.format, "BC1")


def optimize_one(ytd_path: Path) -> tuple:
    original_size = ytd_path.stat().st_size
    if original_size < MIN_SIZE:
        return None, None

    name = ytd_path.name
    print(f"  [{name}] Loading ({original_size/1024/1024:.1f}MB) ...", flush=True)

    try:
        td = ITD.load(str(ytd_path))
    except Exception as e:
        print(f"  [{name}] SKIP - cannot load: {e}")
        return None, None

    textures = list(td.textures)
    if not textures:
        print(f"  [{name}] SKIP - no textures")
        return None, None

    oversized = [(i, t) for i, t in enumerate(textures) if t.width > MAX_DIMENSION or t.height > MAX_DIMENSION]
    if not oversized:
        print(f"  [{name}] No oversized textures, skipped")
        return None, None

    work_dir = Path(tempfile.mkdtemp())
    dds_dir = work_dir / "dds"
    dds_dir.mkdir()

    try:
        extract_dict(td, str(dds_dir))
    except Exception as e:
        print(f"  [{name}] SKIP - extract failed: {e}")
        shutil.rmtree(work_dir)
        return None, None

    replaced = 0
    for idx, tex in oversized:
        dds_file = dds_dir / f"{tex.name}.dds"
        if not dds_file.exists():
            dds_file = dds_dir / f"{tex.name}.DDS"
        if not dds_file.exists():
            print(f"  [{name}]  WARN: missing DDS for {tex.name}")
            continue

        try:
            img = Image.open(str(dds_file))
        except (UnidentifiedImageError, NotImplementedError) as e:
            print(f"  [{name}]  SKIP {tex.name}: {e}")
            continue

        w, h = img.size
        ratio = min(MAX_DIMENSION / w, MAX_DIMENSION / h)
        new_w = int(w * ratio)
        new_h = int(h * ratio)
        img = img.resize((new_w, new_h), Image.LANCZOS)

        png_path = work_dir / f"{tex.name}.png"
        img.save(str(png_path), format="PNG")

        fmt_name = get_format_name(tex)
        try:
            from texfury import Texture, BCFormat
            fmt_enum = getattr(BCFormat, fmt_name, BCFormat.BC1)
            new_tex = Texture.from_image(str(png_path), format=fmt_enum)
            new_tex.name = tex.name
            td.replace(tex.name, new_tex)
            replaced += 1
            print(f"  [{name}]  Resized: {tex.name} {w}x{h} -> {new_w}x{new_h} ({fmt_name})")
        except Exception as e:
            print(f"  [{name}]  FAILED {tex.name}: {e}")

    if replaced == 0:
        print(f"  [{name}]  No textures could be resized")
        shutil.rmtree(work_dir)
        return None, None

    out_path = str(ytd_path) + ".opt"
    td.save(out_path)
    new_size = Path(out_path).stat().st_size

    backup = ytd_path.with_suffix(ytd_path.suffix + ".bak")
    if not backup.exists():
        shutil.copy2(str(ytd_path), str(backup))
    Path(out_path).replace(str(ytd_path))
    shutil.rmtree(work_dir)

    saved_mb = (original_size - new_size) / 1024 / 1024
    print(f"  [{name}] Done: {original_size/1024/1024:.1f}MB -> {new_size/1024/1024:.1f}MB ({new_size/original_size*100:.0f}%, saved {saved_mb:.1f}MB)")
    return original_size, new_size


def main():
    all_files = []
    for res_name, stream_dir in STREAMS.items():
        d = Path(stream_dir)
        if not d.exists():
            print(f"SKIP {res_name}: {d} not found")
            continue
        count = 0
        size_total = 0
        for f in sorted(d.glob("*.ytd")):
            size = f.stat().st_size
            if size >= MIN_SIZE:
                all_files.append((res_name, f))
                count += 1
                size_total += size
        if count:
            print(f"{res_name}: {count} files, {size_total/1024/1024:.0f}MB")

    print(f"\n=== Processing {len(all_files)} files ===\n")

    total_orig = 0
    total_new = 0
    done = 0
    skipped = 0

    for res_name, fpath in all_files:
        print(f"\n[{res_name}]")
        orig, new = optimize_one(fpath)
        if orig is not None:
            total_orig += orig
            total_new += new
            done += 1
        else:
            skipped += 1

    print(f"\n=== Complete: {done} resized, {skipped} skipped ===")
    if total_orig > 0:
        saved = total_orig - total_new
        print(f"Total: {total_orig/1024/1024:.0f}MB -> {total_new/1024/1024:.0f}MB ({total_new/total_orig*100:.0f}%, saved {saved/1024/1024:.0f}MB)")


if __name__ == "__main__":
    main()
