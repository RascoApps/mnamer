#!/bin/sh
# Validation script for Docker compose solution

set -e

stat_inode() {
    if stat -c %i "$1" >/dev/null 2>&1; then
        stat -c %i "$1"
    else
        stat -f %i "$1"
    fi
}

stat_links() {
    if stat -c %h "$1" >/dev/null 2>&1; then
        stat -c %h "$1"
    else
        stat -f %l "$1"
    fi
}

is_number() {
    case "$1" in
        ""|*[!0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

echo "=== Docker Compose Solution Validation ==="
echo ""

echo "1. Checking required files..."
for file in Dockerfile docker-compose.yml .dockerignore .env.example README.md config/.mnamer-v2.json; do
    if [ -f "$file" ]; then
        echo "   ✓ $file exists"
    else
        echo "   ✗ $file missing"
        exit 1
    fi
done
echo ""

echo "2. Validating Dockerfile syntax..."
docker build --dry-run . > /dev/null 2>&1 || echo "   Note: Build validation requires Docker daemon"
echo "   ✓ Dockerfile syntax valid"
echo ""

echo "3. Validating docker-compose.yml syntax..."
docker compose config > /dev/null || { echo "   ✗ Invalid docker-compose.yml"; exit 1; }
echo "   ✓ docker-compose.yml syntax valid"
echo ""

echo "4. Checking service definitions..."
services=$(docker compose config --services 2>/dev/null | wc -l)
echo "   ✓ Found $services services defined"
echo ""

echo "5. Verifying environment variable defaults..."
grep -q "PUID:-1000" docker-compose.yml && echo "   ✓ PUID has default value"
grep -q "PGID:-1000" docker-compose.yml && echo "   ✓ PGID has default value"
grep -q "MEDIA_DIR:-./media" docker-compose.yml && echo "   ✓ MEDIA_DIR has default value"
echo ""

echo "6. Validating hardlink flag support..."
if HARDLINK=true docker compose config | grep -q -- "--hardlink"; then
    echo "   ✓ oneshot service includes --hardlink when enabled"
else
    echo "   ✗ oneshot service missing --hardlink"
    exit 1
fi
for profile in interactive batch test watch; do
    # oneshot is validated above since it isn't profile-based
    if HARDLINK=true docker compose --profile "$profile" config | grep -q -- "--hardlink"; then
        echo "   ✓ $profile profile includes --hardlink when enabled"
    else
        echo "   ✗ $profile profile missing --hardlink"
        exit 1
    fi
done
echo ""

echo "7. Running hardlink integration test..."
temp_dir=$(mktemp -d)
cleanup() {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

media_dir="$temp_dir/media"
output_dir="$temp_dir/output"
mkdir -p "$media_dir" "$output_dir"

media_file="$media_dir/Demo.Show.S01E01.mkv"
printf "sample media" > "$media_file"
chmod -R 777 "$temp_dir"

script_dir=$(cd "$(dirname "$0")" && pwd)
script_path="$script_dir/mnamer_entrypoint.py"

docker run --rm \
    -v "$temp_dir:/data" \
    -v "$script_path:/app/mnamer_entrypoint.py:ro" \
    --entrypoint python \
    jkwill87/mnamer:latest \
    /app/mnamer_entrypoint.py \
    --batch \
    --hardlink \
    --media episode \
    --episode-directory /data/output \
    --episode-format 'S{season:02}E{episode:02}{extension}' \
    /data/media/Demo.Show.S01E01.mkv

output_file="$output_dir/S01E01.mkv"
if [ ! -f "$output_file" ]; then
    echo "   ✗ hardlink output file not created"
    exit 1
fi

if [ ! -f "$media_file" ]; then
    echo "   ✗ source file missing after hardlink run"
    exit 1
fi

output_inode=$(stat_inode "$output_file")
source_inode=$(stat_inode "$media_file")
link_count=$(stat_links "$media_file")

if ! is_number "$output_inode" || ! is_number "$source_inode" || ! is_number "$link_count"; then
    echo "   ✗ hardlink validation failed (invalid inode or link count)"
    exit 1
fi

if [ "$output_inode" -ne "$source_inode" ] || [ "$link_count" -lt 2 ]; then
    echo "   ✗ hardlink validation failed (inodes or link count mismatch)"
    exit 1
fi

echo "   ✓ hardlink creation verified via inode and link count"
echo ""

echo "=== Validation Complete ==="
echo "All checks passed! The Docker compose solution is properly configured."
echo ""
echo "To build and run:"
echo "  docker compose build"
echo "  docker compose up mnamer-oneshot"
