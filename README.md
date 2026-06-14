# docker-mdbook

🇺🇸 English | 🇯🇵 [日本語](./README.ja.md)

A Docker image for building and previewing mdBook documentation. PlantUML, Mermaid, CJK fonts, and multi-language search support all run entirely within the container.

## Image Contents

| Component | Description |
|---|---|
| Base image | `debian:bookworm-slim` |
| [mdBook](https://github.com/rust-lang/mdBook) | Markdown documentation builder |
| [mdbook-plantuml](https://github.com/sytsereitsma/mdbook-plantuml) | PlantUML preprocessor |
| [mdbook-mermaid](https://github.com/badboy/mdbook-mermaid) | Mermaid preprocessor |
| [PlantUML](https://github.com/plantuml/plantuml) | Diagram generation (local execution) |
| Graphviz | Graph rendering engine used by PlantUML |
| OpenJDK 17 | Runtime for PlantUML |
| fonts-noto-cjk | Japanese/Chinese/Korean fonts |

PlantUML runs locally inside the container without calling any external server, so it works in air-gapped environments.

## Supported Architectures

`linux/amd64` / `linux/arm64`

## Usage

### Wrapper Script (Recommended)

The bundled `mdbook.sh` script targets the `docs/` directory and provides convenient subcommands.

```sh
# Build
./mdbook.sh build

# Live preview (default: http://localhost:3000)
./mdbook.sh serve

# Watch for changes (rebuild only, no server)
./mdbook.sh watch

# Stop the server
./mdbook.sh stop

# Remove build artifacts and cache
./mdbook.sh clean

# Update mermaid assets from the latest image
./mdbook.sh install-assets
```

The port can be changed via the `MDBOOK_PORT` environment variable (default: `3000`).

```sh
MDBOOK_PORT=4000 ./mdbook.sh serve
```

### Using Docker Directly

```sh
# Build
docker run --rm -v $(pwd):/book --user $(id -u):$(id -g) \
  ghcr.io/nkenbou/docker-mdbook:latest build

# Live preview
docker run --rm -v $(pwd):/book -p 3000:3000 --user $(id -u):$(id -g) \
  ghcr.io/nkenbou/docker-mdbook:latest serve --hostname 0.0.0.0
```

## Setting Up in Your Project

To integrate docker-mdbook into an existing mdBook project, copy two files from this repository and adjust the language code.

### 1. Copy the wrapper script

Copy `mdbook.sh` to your project root, then edit the `BOOK_DIR` variable to point to your documentation directory (default: `docs/` relative to the script).

### 2. Enable language-aware search

Copy `docs/theme/head.hbs` to `<your-book-dir>/theme/head.hbs`. This file loads the language-specific search assets. Replace the `ja` language code with yours in three places:

| File | What to change |
|---|---|
| `theme/head.hbs` | `lunr.ja.min.js` → `lunr.<lang>.min.js` |
| `theme/head.hbs` | `window.lunr.ja` → `window.lunr.<lang>` (2 occurrences) |
| `mdbook.sh` (`install-assets` block) | `lunr.ja.min.js` → `lunr.<lang>.min.js` |

See [lunr-languages](https://github.com/nkenbou/lunr-languages) for supported language codes (`fr`, `de`, `zh`, `ko`, `es`, etc.).

Also add `language` to your `book.toml` so the search index builder auto-detects it:

```toml
[book]
language = "ja"  # replace with your language code
```

### 3. Install assets

Run once (and again after updating the image) to copy search and Mermaid assets from the Docker image into `<book-dir>/.mdbook/`:

```sh
./mdbook.sh install-assets
```

## Pulling the Image

```sh
docker pull ghcr.io/nkenbou/docker-mdbook:latest
```

See the [GHCR package page](https://github.com/nkenbou/docker-mdbook/pkgs/container/docker-mdbook) for available tags.

## Building

Tool versions are pinned via `ARG` in the `Dockerfile`. To update a version, change the corresponding `ARG` value and rebuild.

```sh
docker build -t docker-mdbook .
```

## Documentation

The `docs/` directory is published to GitHub Pages:
**https://nkenbou.github.io/docker-mdbook/**

## CI/CD

GitHub Actions automatically builds a multi-architecture image on every push to `main`. The image is published to GHCR only on tag pushes (`v*`). The documentation is also automatically deployed to GitHub Pages on every push to `main`.

## License

See [LICENSE](./LICENSE).
