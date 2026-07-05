#!/bin/sh
#set -x
set -e

# Read metadata from meta.txt
if [ ! -f "meta.txt" ]; then
    echo "Error: meta.txt not found"
    exit 1
fi

# Parse meta.txt and set variables
TITLE=$(grep "^title=" meta.txt | cut -d'=' -f2 | head -1)
AUTHOR=$(grep "^publisher=" meta.txt | cut -d'=' -f2)
VERSION=$(grep "^version=" meta.txt | cut -d'=' -f2)
LICENSE=$(grep "^comment=" meta.txt | cut -d'=' -f2)

# Set defaults if not found in meta.txt
TITLE=${TITLE:-"Game"}
AUTHOR=${AUTHOR:-"Unknown"}
VERSION=${VERSION:-"1.0.0.0"}
LICENSE=${LICENSE:-"Public Domain"}

# Password from environment variable (not from meta.txt)
PASSWORD=${PASSWORD:-""}

# Icon source to be processed into icon.ico
FILE_icon="icon.png"

# 7z exclusion list
EXCLUDE_FILE=".7z-exclude.txt"

# Show 7z progress bar?
PROGRESS=${PROGRESS:-"no"}

# Detect OS
SYSTEM="$(uname -s)"

# Cache directory for downloads
CACHE_DIR="cache"
mkdir -p "$CACHE_DIR"

# Download links
if [ "$SYSTEM" = "Linux" ]; then
    LINK_7z="https://github.com/ip7z/7zip/releases/download/26.02/7z2602-linux-x64.tar.xz"
    LINK_magick="https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-26/ImageMagick-7.1.2-26-gcc-x86_64.AppImage"
    LINK_wine="https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable/wine-stable_11.0-x86_64.AppImage"
else
    LINK_7zr="https://github.com/ip7z/7zip/releases/download/26.02/7zr.exe"
    LINK_7z="https://github.com/ip7z/7zip/releases/download/26.02/7z2602-extra.7z"
    LINK_magick="https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-26/ImageMagick-7.1.2-26-portable-Q16-HDRI-x64.7z"
fi

LINK_love="https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip"
LINK_icon="https://upload.wikimedia.org/wikipedia/commons/6/6f/Softies-icons-star_256px.png"
LINK_rcedit="https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe"
LINK_sfx="https://github.com/chrislake/7zsfxmm/releases/download/1.7.1.3901/7zsd_extra_171_3901.7z"

download() {
    if [ ! -f "$2" ]; then
        echo "Downloading $2"
        curl -LJ -o "$2" "$1"
    fi
}

# File paths (in cache directory)
EXE_7zr="$CACHE_DIR/$(basename "$LINK_7zr")"
EXE_wine="$CACHE_DIR/$(basename "$LINK_wine")"
ARCHIVE_7z="$CACHE_DIR/$(basename "$LINK_7z")"
ARCHIVE_love="$CACHE_DIR/$(basename "$LINK_love")"
ARCHIVE_sfx="$CACHE_DIR/$(basename "$LINK_sfx")"
ARCHIVE_magick="$CACHE_DIR/$(basename "$LINK_magick")"
FILE_rcedit="$CACHE_DIR/$(basename "$LINK_rcedit")"

if [ "$SYSTEM" != "Linux" ]; then
    download "$LINK_7zr" "$EXE_7zr"
else
    download "$LINK_wine" "$EXE_wine"
fi
download "$LINK_7z" "$ARCHIVE_7z"
download "$LINK_love" "$ARCHIVE_love"
download "$LINK_sfx" "$ARCHIVE_sfx"
download "$LINK_icon" "$FILE_icon"
download "$LINK_magick" "$ARCHIVE_magick"
download "$LINK_rcedit" "$FILE_rcedit"

# Unpacked paths
DIR_7z="$CACHE_DIR/7z"
if [ "$SYSTEM" = "Linux" ]; then
    EXE_7z="$DIR_7z/7zz"
else
    EXE_7z="$DIR_7z/x64/7za.exe"
fi
DIR_game="."
DIR_love="$CACHE_DIR/love"
DIR_sfx="$CACHE_DIR/7zsfx"
DIR_magick="$CACHE_DIR/imagemagick"
FILE_sfx="7zsd_All_x64.sfx"

# Setup magick and rcedit paths based on OS
if [ "$SYSTEM" = "Linux" ]; then
    EXE_magick="$ARCHIVE_magick"
    EXE_rcedit="$EXE_wine $FILE_rcedit"
else
    # On Windows, extract to cache subdirectory to contain files
    EXE_magick="$DIR_magick/magick.exe"
    EXE_rcedit="$FILE_rcedit"
fi

unpack_7z() {
    TARGETDIR="-o"
    if [ ! -f "./$EXE_7z" ]; then
        if [ "$SYSTEM" = "Linux" ]; then
            UNARCH="tar xf"
            TARGETDIR="-C"
        else
            UNARCH="./$EXE_7zr x"
        fi
    else
        UNARCH="./$EXE_7z x"
    fi

    if [ "$#" -lt 2 ]; then
        if [ ! -d "${1%.*}" ]; then
            echo "Unpacking $1"
            $UNARCH "$1"
        fi
    else
        if [ ! -d "$2" ]; then
            echo "Unpacking $1 to $2"
            mkdir -p "$2"
            $UNARCH "$1" "$TARGETDIR$2"
        fi
    fi
}

unpack_7z "$ARCHIVE_7z" "$DIR_7z"
unpack_7z "$ARCHIVE_love" "$DIR_love"
unpack_7z "$ARCHIVE_sfx" "$DIR_sfx"
if [ "$SYSTEM" = "Linux" ]; then
    chmod +x "$EXE_magick"
    chmod +x "$EXE_wine"
else
    # Always extract ImageMagick to cache subdirectory
    unpack_7z "$ARCHIVE_magick" "$DIR_magick"
fi

# Icon settings
FILE_ico="$CACHE_DIR/${FILE_icon%.*}.ico"
SFX_game="game.exe"

generate_ico() {
    if [ ! -f "$FILE_ico" ]; then
        echo "Creating $FILE_ico"
        # 256, 48, 32, 24, 16: these sizes are the minimum requirement according to Microsoft
        # https://learn.microsoft.com/en-us/windows/apps/design/style/iconography/app-icon-construction#icon-scaling
        "./$EXE_magick" "$FILE_icon" -define icon:auto-resize=256,48,32,24,16 "$FILE_ico"
    fi
}

modify_sfx() {
    if [ ! -f "$FILE_sfx" ]; then
        echo "Patching $FILE_sfx"
        cp "$DIR_sfx/$FILE_sfx" .
        ./$EXE_rcedit "$FILE_sfx" \
            --set-version-string CompanyName "$AUTHOR" \
            --set-version-string ProductName "$TITLE" \
            --set-version-string FileDescription "$TITLE love2d game" \
            --set-version-string InternalName "game" \
            --set-version-string LegalCopyright "$LICENSE" \
            --set-version-string OriginalFilename "$SFX_game" \
            --set-version-string PrivateBuild "$VERSION" \
            --set-file-version "$VERSION" \
            --set-product-version "$VERSION" \
            --set-icon "$FILE_ico"
    fi
}

generate_ico
modify_sfx

# SFX settings
CONFIG_file="config.txt"
ARCHIVE_packed="$CACHE_DIR/game.7z"
EXTRACTED_love="$(basename ${ARCHIVE_love%.*})"

pack_7z() {
    if [ ! -f "$ARCHIVE_packed" ]; then
        echo "Creating $ARCHIVE_packed"

        PACK_OPTS=""
        if [ ! -z "$PASSWORD" ]; then
            PACK_OPTS="-p$PASSWORD"
        fi

        if [ ! -d "$DIR_game/$EXTRACTED_love" ]; then
            mv -v "$DIR_love/$EXTRACTED_love" "$DIR_game"
        fi

        # Create exclusion list if it exists
        if [ -f "$EXCLUDE_FILE" ]; then
            echo "Using exclusion list: $EXCLUDE_FILE"
            "./$EXE_7z" a $PACK_OPTS -x@"$EXCLUDE_FILE" "$ARCHIVE_packed" "$DIR_game"
        else
            "./$EXE_7z" a $PACK_OPTS "$ARCHIVE_packed" "$DIR_game"
        fi
    fi
}

patch_config() {
    if [ ! -f "$CONFIG_file" ]; then
        echo "Creating $CONFIG_file"
        sed -e "s|@TITLE@|$TITLE|g" \
            -e "s|@PROGRESS@|$PROGRESS|g" \
            -e "s|@LOVE@|$EXTRACTED_love|g" \
            -e "s|@GAME@|$DIR_game|g" \
            "$CONFIG_file.in" > "$CONFIG_file"
    fi
}

create_sfx() {
    if [ ! -f "$SFX_game" ]; then
        echo "Creating $SFX_game"
        cat "$FILE_sfx" "$CONFIG_file" "$ARCHIVE_packed" > "$SFX_game"
    fi
}

pack_7z
patch_config
create_sfx

echo "Build complete: $SFX_game"

# Clean up
#rm -f "$EXE_7zr" "$EXE_wine" "$ARCHIVE_7z" "$ARCHIVE_love" "$ARCHIVE_sfx" "$ARCHIVE_magick" "$FILE_icon" "$FILE_rcedit"
#rm -rf "$DIR_7z" "$DIR_love" "$DIR_sfx" "$DIR_magick"
#rm -f "$FILE_ico" "$FILE_sfx" "$CONFIG_file" "$ARCHIVE_packed"
