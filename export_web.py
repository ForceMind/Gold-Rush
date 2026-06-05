#!/usr/bin/env python3
"""
Gold Rush Web Export Script
Steps: Update version, import resources, export, split wasm, patch HTML, create zip
"""
import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path

# Configuration
GODOT_PATH = r"C:\Users\wxx11\OneDrive\桌面\工具\Godot\Godot_v4.6.3-stable_win64.exe"
VERSION_FILE = "version.txt"
SCENE_FILE = "scenes/StartScreen.tscn"
EXPORT_DIR = "export/web"
ZIP_FILE = "gold-rush-web.zip"
ICON_FILE = "icon.png"
MAX_WASM_SIZE = 15 * 1024 * 1024  # 15MB (Smaller limit for more chunks)
FONT_FILE = "assets/fonts/NotoSansCJKsc-Regular.otf"
FONT_BACKUP = "assets/fonts/NotoSansCJKsc-Regular.otf.bak"

def print_step(num, total, msg):
    print(f"\n[{num}/{total}] {msg}")

def fix_scene_files():
    """Fix common .tscn issues: move sub_resource before node."""
    fixed = []
    for f in os.listdir("scenes"):
        if not f.endswith(".tscn"):
            continue
        path = os.path.join("scenes", f)
        with open(path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()

        # Find if any sub_resource appears after first node
        first_node_line = -1
        misplaced_subs = []
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if line.startswith("[node ") and first_node_line == -1:
                first_node_line = i
            if line.startswith("[sub_resource ") and first_node_line != -1:
                # Collect this sub_resource block
                block = [lines[i]]
                i += 1
                while i < len(lines) and not lines[i].strip().startswith("["):
                    block.append(lines[i])
                    i += 1
                misplaced_subs.append((first_node_line, block))
                continue
            i += 1

        if misplaced_subs:
            # Remove misplaced sub_resource blocks (in reverse order)
            for _, block in reversed(misplaced_subs):
                for line in block:
                    if line in lines:
                        lines.remove(line)

            # Insert them before first node
            insert_pos = first_node_line
            for _, block in misplaced_subs:
                for j, line in enumerate(block):
                    lines.insert(insert_pos + j, line)
                insert_pos += len(block)

            with open(path, "w", encoding="utf-8") as fh:
                fh.writelines(lines)
            fixed.append(f)
    return fixed


def verify_scene_files():
    """Verify all .tscn files have correct load_steps and resource order."""
    errors = []
    for f in os.listdir("scenes"):
        if not f.endswith(".tscn"):
            continue
        path = os.path.join("scenes", f)
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
        # Check load_steps
        ext = content.count("[ext_resource")
        sub = content.count("[sub_resource")
        m = re.search(r"load_steps=(\d+)", content)
        if m:
            load_steps = int(m.group(1))
            expected = ext + sub + 1
            if load_steps != expected:
                errors.append(f"  {f}: load_steps={load_steps} expected={expected}")
        # Check resource order: all [sub_resource] must come before first [node]
        first_node = content.find("[node ")
        first_sub = content.find("[sub_resource ")
        if first_node > 0 and first_sub > 0 and first_sub > first_node:
            errors.append(f"  {f}: [sub_resource] appears after [node] - must be before")
    return errors

def run_godot(*args):
    cmd = [GODOT_PATH] + list(args)
    result = subprocess.run(cmd, capture_output=True)
    return result.returncode

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    print("=" * 40)
    print("Gold Rush Web Export")
    print("=" * 40)

    # Step 1: Update version
    print_step(1, 9, "Update version...")
    if os.path.exists(VERSION_FILE):
        version = open(VERSION_FILE, "r").read().strip()
    else:
        version = "v1.0"

    m = re.match(r"v(\d+)\.(\d+)", version)
    if m:
        major, minor = int(m.group(1)), int(m.group(2))
    else:
        major, minor = 1, 0

    minor += 1
    if minor >= 10:
        minor = 0
        major += 1

    new_version = f"v{major}.{minor}"
    print(f"  Version: {version} -> {new_version}")

    with open(VERSION_FILE, "w") as f:
        f.write(new_version)

    scene_content = open(SCENE_FILE, "r", encoding="utf-8").read()
    scene_content = re.sub(r'text = "v\d+\.\d+"', f'text = "{new_version}"', scene_content)
    with open(SCENE_FILE, "w", encoding="utf-8") as f:
        f.write(scene_content)
    print("  Updated scene file version")

    # Step 2: Font subset and import
    print_step(2, 9, "Font subset and import...")
    if os.path.exists(FONT_BACKUP):
        # Restore full font, import, subset, replace, import again
        import shutil
        shutil.copy2(FONT_BACKUP, FONT_FILE)
        print("  Restored full font for import")
        run_godot("--headless", "--import")
        print("  Imported with full font")

        # Create subset
        from fontTools.ttLib import TTFont
        from fontTools.subset import Subsetter, Options
        chars = set()
        for root, dirs, files in os.walk('.'):
            if '.godot' in root or 'dist' in root or 'export' in root:
                continue
            for f in files:
                if f.endswith(('.tscn', '.gd')):
                    with open(os.path.join(root, f), 'r', encoding='utf-8') as fh:
                        for char in fh.read():
                            chars.add(char)
        for i in range(128):
            chars.add(chr(i))
        for char in '，。！？、；：""''（）【】《》…—～·':
            chars.add(char)
        font = TTFont(FONT_BACKUP)
        subsetter = Subsetter(options=Options())
        subsetter.populate(text=''.join(chars))
        subsetter.subset(font)
        font.save(FONT_FILE)
        print(f"  Font subset created: {os.path.getsize(FONT_FILE) / 1024:.0f} KB")

        # Re-import with subset font
        run_godot("--headless", "--import")
        print("  Re-imported with subset font")
    else:
        run_godot("--headless", "--import")
        print("  Resources imported (no font backup found)")

    # Step 3: Fix and verify scene files
    print("\n[3/9] Fix and verify scene files...")
    fixed = fix_scene_files()
    if fixed:
        print(f"  Auto-fixed: {', '.join(fixed)}")
    errors = verify_scene_files()
    if errors:
        print("  ERROR: scene file issues:")
        for e in errors:
            print(e)
        sys.exit(1)
    print("  All scene files OK")

    # Step 4: Export Web
    print_step(4, 9, "Export Web version...")
    os.makedirs(EXPORT_DIR, exist_ok=True)
    run_godot("--headless", "--export-release", "Web", f"{EXPORT_DIR}/index.html")

    if not os.path.exists(f"{EXPORT_DIR}/index.html"):
        print("  Error: Export failed - index.html not found")
        sys.exit(1)
    print("  Export completed")

    # Step 5: Split wasm
    print_step(5, 9, "Split wasm file...")
    wasm_file = f"{EXPORT_DIR}/index.wasm"
    if os.path.exists(wasm_file):
        file_size = os.path.getsize(wasm_file)
        file_size_mb = round(file_size / 1024 / 1024, 2)
        print(f"  Original wasm size: {file_size_mb} MB")

        if file_size > MAX_WASM_SIZE:
            import math
            num_parts = math.ceil(file_size / MAX_WASM_SIZE)
            # Calculate a balanced chunk size
            chunk_size = math.ceil(file_size / num_parts)
            
            part = 0
            with open(wasm_file, "rb") as f:
                while True:
                    chunk = f.read(chunk_size)
                    if not chunk:
                        break
                    part_file = f"{wasm_file}.{part}"
                    with open(part_file, "wb") as out:
                        out.write(chunk)
                    part_size_mb = round(len(chunk) / 1024 / 1024, 2)
                    print(f"  Created: index.wasm.{part} ({part_size_mb} MB)")
                    part += 1

            os.remove(wasm_file)
            print("  Deleted original wasm file")
            print(f"  Split completed, {part} files")
        else:
            print("  Wasm file smaller than 25MB, no split needed")
    else:
        print("  Warning: wasm file not found")

    # Step 6: Replace icon.png
    print_step(6, 9, "Replace icon.png...")
    export_icon = f"{EXPORT_DIR}/index.png"
    if os.path.exists(ICON_FILE):
        import shutil
        shutil.copy2(ICON_FILE, export_icon)
        print("  Replaced with HD icon")
    else:
        print("  Warning: icon.png not found")

    # Step 7: Patch index.html for split wasm
    print_step(7, 9, "Patch index.html for split wasm...")
    html_file = f"{EXPORT_DIR}/index.html"
    wasm_parts = sorted([f for f in os.listdir(EXPORT_DIR) if f.startswith("index.wasm.")])

    if wasm_parts and os.path.exists(html_file):
        html_content = open(html_file, "r", encoding="utf-8").read()

        # Build JS array of part filenames
        part_names_json = ",".join(f'"{p}"' for p in wasm_parts)

        # Get total wasm size from fileSizes in GODOT_CONFIG
        wasm_size_match = re.search(r'"index\.wasm":(\d+)', html_content)
        wasm_total_size = wasm_size_match.group(1) if wasm_size_match else "37700666"

        loader_script = f"""<script>
// WASM chunk loading configuration
const WASM_CHUNKS = [{part_names_json}];
const WASM_TOTAL_SIZE = {wasm_total_size};
const WASM_EXECUTABLE = 'index';

// Pre-load and merge WASM chunks before engine starts
const wasmReady = (async function() {{
    const statusProgress = document.getElementById('status-progress');
    const statusOverlay = document.getElementById('status');

    // Show progress bar
    statusOverlay.style.visibility = 'visible';
    statusProgress.style.display = 'block';

    const chunks = [];
    let loadedSize = 0;

    for (let i = 0; i < WASM_CHUNKS.length; i++) {{
        const chunkUrl = WASM_CHUNKS[i];
        const response = await fetch(chunkUrl);
        if (!response.ok) {{
            throw new Error(`Failed to load WASM chunk: ${{chunkUrl}}`);
        }}
        const chunkData = await response.arrayBuffer();
        chunks.push(new Uint8Array(chunkData));
        loadedSize += chunkData.byteLength;

        // Update progress
        statusProgress.value = loadedSize;
        statusProgress.max = WASM_TOTAL_SIZE;
    }}

    // Merge all chunks into one ArrayBuffer
    const merged = new Uint8Array(WASM_TOTAL_SIZE);
    let offset = 0;
    for (const chunk of chunks) {{
        merged.set(chunk, offset);
        offset += chunk.length;
    }}

    // Hide progress bar after loading
    statusProgress.style.display = 'none';

    return merged.buffer;
}})();

// Override fetch to intercept WASM loading
const originalFetch = window.fetch;
window.fetch = function(url, options) {{
    // Check if this is a WASM file request
    const urlStr = (typeof url === 'string') ? url : url.url;
    if (urlStr && urlStr.endsWith('.wasm') && urlStr.includes(WASM_EXECUTABLE)) {{
        return wasmReady.then(function(buffer) {{
            // Create a ReadableStream from the buffer for proper progress tracking
            const stream = new ReadableStream({{
                start: function(controller) {{
                    controller.enqueue(new Uint8Array(buffer));
                    controller.close();
                }}
            }});
            return new Response(stream, {{
                headers: [['content-type', 'application/wasm']]
            }});
        }});
    }}
    return originalFetch.call(this, url, options);
}};
</script>
"""

        # Insert before the first <script> tag in <body>
        html_content = re.sub(
            r'(<body>.*?)(<script src="index\.js">)',
            r'\1' + loader_script + r'\2',
            html_content,
            flags=re.DOTALL
        )

        with open(html_file, "w", encoding="utf-8") as f:
            f.write(html_content)
        print("  Patched index.html with split wasm loader")
    else:
        print("  No split wasm files found, skipping patch")

    # Step 8: Clean old zip
    print_step(8, 9, "Clean old zip file...")
    if os.path.exists(ZIP_FILE):
        os.remove(ZIP_FILE)
        print("  Deleted old zip file")

    # Step 9: Create zip
    print_step(9, 9, "Create zip package...")
    with zipfile.ZipFile(ZIP_FILE, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(EXPORT_DIR):
            for file in files:
                if file.endswith(".import"):
                    continue
                filepath = os.path.join(root, file)
                zf.write(filepath, file)

    zip_size = os.path.getsize(ZIP_FILE)
    zip_size_mb = round(zip_size / 1024 / 1024, 2)
    print(f"  Zip created")
    print(f"  File size: {zip_size_mb} MB")

    print()
    print("=" * 40)
    print("Export completed!")
    print(f"Version: {new_version}")
    print(f"File: {ZIP_FILE}")
    print("=" * 40)

if __name__ == "__main__":
    main()
