# lovesfx - LÖVE2D Game Packager

Pack LÖVE games into a single `.exe` for Windows, or create `.love` archives for distribution.

## Prerequisites

- **Windows or Linux** with bash/sh available
  - Windows: Git Bash or MSYS2
  - Linux: standard shell
- **curl** - for downloading dependencies
- **7-Zip** - for archive operations (downloaded automatically)
- **ImageMagick** - for icon processing (downloaded automatically)
- **rcedit** - for Windows resource editing (downloaded automatically)
- **LÖVE 11.5** - game runtime (downloaded automatically)

## Project Structure

The script expects the following layout:

```
your-game-project/
├── lovesfx.sh              # Build script (place in project root)
├── main.lua                # Game entry point (in root)
├── conf.lua                # LÖVE config (in root)
├── meta.txt                # Build metadata (required)
├── .7z-exclude.txt         # Archive exclusion list
├── icon.png                # Game icon (256x256 PNG)
├── libs/                   # Game libraries
├── data/                   # Game assets
└── cache/                  # (git-ignored) Downloaded tools & runtimes
    ├── 7z/
    ├── love/
    ├── 7zsfx/
    ├── imagemagick/
    └── *.zip, *.7z, *.exe
```

**Important:** The script must be placed in your **project root** alongside `main.lua`. It does not download itself or operate remotely.

## Current Limitations

⚠️ **Game source files must be in the project root** - The script currently only packages:
- Files/directories in the project root (`.`)
- The LÖVE runtime directory

**This means:**
- ✅ Works: `main.lua`, `conf.lua`, `libs/`, `data/` in root
- ❌ Does NOT work: Game files in a `game/` subdirectory

**Planned enhancement:** Refactor script to support game source in subdirectories (e.g., `game/main.lua`).

## Configuration

### meta.txt

Required file with game metadata (placed in project root):

```ini
version=1.0.0
build=1001
identity=mygame
package=com.company.mygame
title=My Game Title
title[ja]=ゲームのタイトル
comment=Created with lovesfx
publisher=Company Name
url=https://example.com
orientation=default
```

### .7z-exclude.txt

Patterns to exclude from the final archive (one per line):

```
.7z-*.txt        # Exclude .7z-exclude.txt from archive
*.love           # Exclude .love files
*.zip
*.exe
*.7z
cache            # Exclude build tools
.git
.vscode
```

### icon.png

- **Required** for Windows .exe
- Format: PNG, 256×256 pixels or larger
- The script will generate multiple resolutions for Windows icon requirements

## Building

### Without Password

```bash
./lovesfx.sh
```

### With 7z Password (Optional)

Pass the password as an environment variable:

```bash
PASSWORD="mysecret" ./lovesfx.sh
```

Output: `game.exe` (Windows SFX self-extracting archive)

The password protects the internal 7z archive and requires it to be entered when extracting.

### On Windows
```bash
# Via Git Bash or MSYS2
./lovesfx.sh

# With password
PASSWORD="mysecret" ./lovesfx.sh
```

### On Linux
```bash
# Requires Wine to patch Windows resources
./lovesfx.sh

# With password
PASSWORD="mysecret" ./lovesfx.sh
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PASSWORD` | (empty) | 7z archive password (optional) |
| `PROGRESS` | `"no"` | Show 7z progress bar (`"yes"` or `"no"`) |

Example:
```bash
PASSWORD="secret" PROGRESS=yes ./lovesfx.sh
```

## Generated Files

After running the build:

- `game.exe` - Final packaged game (Windows executable)
- `game.7z` - Game archive with runtime
- `icon.ico` - Processed icon file
- `config.txt` - SFX configuration
- `cache/` - Build tools and runtimes (git-ignored)

## How It Works

1. **Download tools** - 7-Zip, ImageMagick, rcedit, LÖVE runtime (cached in `cache/`)
2. **Process icon** - Converts `icon.png` to multi-resolution `icon.ico`
3. **Patch SFX** - Sets version info and icon on 7-Zip self-extractor
4. **Create archive** - Packs game + LÖVE runtime into `game.7z`, filtered by `.7z-exclude.txt`, optionally password-protected
5. **Build .exe** - Concatenates SFX + config + archive into `game.exe`

## Troubleshooting

### "meta.txt not found"
Ensure `meta.txt` exists in the project root with required fields.

### Icon generation fails
- Verify `icon.png` exists in project root
- Ensure ImageMagick downloaded successfully to `cache/`
- Try manual regeneration: `rm icon.ico` then re-run script

### 7z archive errors
- Check `.7z-exclude.txt` patterns don't exclude needed files
- Verify no unintended duplicate directories in project root

### Script not found / permission denied
- Ensure `lovesfx.sh` is in your project root (not in `PATH`)
- On Linux/Mac: `chmod +x lovesfx.sh`

## Notes

- All downloads cached in `cache/` for faster rebuilds
- Cache is git-ignored - safe to delete and rebuild
- Windows executable is ~6MB (includes LÖVE 11.5 runtime)
- .gitignore should include: `/cache/`, `*.exe`, `*.7z`, `*.ico`
- Password is passed via environment variable for security (not stored in files)

## License

MIT License - See LICENSE file

## Credits

- Built on [7-Zip SFX MM](https://github.com/chrislake/7zsfxmm) by chrislake
- Uses [LÖVE 2D](https://love2d.org/) framework
