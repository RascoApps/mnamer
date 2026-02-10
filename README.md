# mnamer - Docker Compose Solution

A containerized solution for running [mnamer](https://github.com/jkwill87/mnamer) - an intelligent media file organizer and renamer.

## Overview

This repository provides a Docker Compose setup for running mnamer without cloning the entire upstream repository. The solution installs mnamer directly from PyPI and offers multiple operational modes.

## Features

- **Multi-stage Docker build** for optimized image size
- **Multiple operational modes**: interactive, batch, test, and watch
- **Non-root user execution** for enhanced security
- **Configurable via JSON** file or environment variables
- **Health checks** for container monitoring
- **Volume mounting** for media and configuration management

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose V2

### Initial Setup

1. Clone this repository:
```bash
git clone https://github.com/RascoApps/mnamer.git
cd mnamer
```

2. Create required directories:
```bash
mkdir -p media output config
```

3. Configure environment variables (optional):
```bash
cp .env.example .env
# Edit .env to customize settings
```

4. Place your media files in the `media` directory

5. (Optional) Customize the configuration in `config/.mnamer-v2.json`

### Usage

#### One-Shot Mode (Default)
Process files once and exit - perfect for cron jobs or manual runs:
```bash
docker compose up mnamer-oneshot
```

With custom environment variables:
```bash
PUID=1001 PGID=1001 docker compose up mnamer-oneshot
```

#### Interactive Mode
Process files with manual confirmation prompts:
```bash
docker compose --profile interactive run --rm mnamer-interactive
```

#### Batch Mode
Automatically process all files without prompts:
```bash
docker compose --profile batch run --rm mnamer-batch
```

#### Test Mode
Dry-run to preview changes without modifying files:
```bash
docker compose --profile test run --rm mnamer-test
```

#### Watch Mode
Continuously monitor and process new files every 5 minutes:
```bash
docker compose --profile watch up -d mnamer-watch
```

To stop watch mode:
```bash
docker compose --profile watch down
```

## Configuration

### Environment Variables

The following environment variables can be set in a `.env` file or passed directly:

#### User/Group Configuration
- `PUID`: User ID for file operations (default: `1000`)
- `PGID`: Group ID for file operations (default: `1000`)

#### Directory Configuration
- `MEDIA_DIR`: Path to media directory (default: `./media`)
- `CONFIG_DIR`: Path to configuration directory (default: `./config`)
- `OUTPUT_DIR`: Path to output directory (default: `./output`)

#### Processing Options (One-Shot Mode)
- `BATCH_MODE`: Enable batch processing (default: `true`)
- `RECURSE`: Process subdirectories recursively (default: `true`)
- `VERBOSE`: Verbosity level 0-2 (default: `1`)
- `LANGUAGE`: Metadata language code (default: `en`)
- `NO_OVERWRITE`: Prevent overwriting existing files (default: `false`)
- `HARDLINK`: Set to any value to pass `--hardlink` (entrypoint swaps mnamer relocation for hardlinks; requires source/output on same filesystem)

#### Watch Mode
- `WATCH_INTERVAL`: Seconds between processing runs (default: `300`)

#### Build Configuration
- `VERSION`: Specific mnamer version to install (optional, defaults to latest)

### Configuration File

Edit `config/.mnamer-v2.json` to customize mnamer behavior. Key options:

- `movie_directory`: Output path for movies
- `episode_directory`: Output path for TV episodes
- `movie_format`: Filename pattern for movies
- `episode_format`: Filename pattern for episodes
- `language`: Metadata language (e.g., "en", "es", "fr")
- `mask`: File extensions to process

See [mnamer documentation](https://github.com/jkwill87/mnamer/wiki/Settings) for all available options.

## Building from Source

Build the Docker image (installs latest mnamer version):
```bash
docker compose build
```

Build with specific mnamer version:
```bash
docker compose build --build-arg VERSION=2.5.5
```

Build with custom user/group IDs:
```bash
docker compose build --build-arg USER_ID=1001 --build-arg GROUP_ID=1001
```

Or configure the version in `docker-compose.yml` by uncommenting and setting the VERSION argument, or use environment variables in a `.env` file.

## Advanced Usage

### Custom Commands

Run mnamer with custom arguments:
```bash
docker compose run --rm mnamer-batch --verbose --language es /media
```

### Multiple Media Directories

Mount additional volumes in `docker-compose.yml`:
```yaml
volumes:
  - ./media:/media:ro
  - ./downloads:/downloads:ro
  - ./output:/output
```

### API Keys

Some providers require API keys. Set them in the configuration:
```json
{
  "api_key_tmdb": "your_tmdb_key",
  "api_key_omdb": "your_omdb_key"
}
```

## Troubleshooting

### Permission Issues

If you encounter permission errors, set the `PUID` and `PGID` environment variables to match your host user:

```bash
# Find your user ID and group ID
id -u  # User ID
id -g  # Group ID

# Set in .env file
echo "PUID=$(id -u)" >> .env
echo "PGID=$(id -g)" >> .env

# Or pass directly
PUID=$(id -u) PGID=$(id -g) docker compose up mnamer-oneshot
```

Alternatively, rebuild the image with custom IDs:
```bash
docker compose build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)
```

### Network Issues

If mnamer cannot reach metadata providers, check your network configuration and firewall settings.

### View Logs

For watch mode:
```bash
docker compose --profile watch logs -f mnamer-watch
```

For other modes, logs are shown in the terminal output.

## License

This Docker implementation is provided as-is. The mnamer application is licensed under the MIT License by its original author.

## Credits

- Original mnamer project: [jkwill87/mnamer](https://github.com/jkwill87/mnamer)
- Docker solution maintained by: RascoApps

## Support

For mnamer-specific issues, see the [upstream repository](https://github.com/jkwill87/mnamer/issues).

For Docker/compose issues with this implementation, open an issue in this repository.
