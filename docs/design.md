# 設計書

## Rust ツールのインストール方式

### 概要

Dockerfile 内で mdBook・mdbook-plantuml・mdbook-mermaid をインストールする方式を定める。

### 方式

マルチステージビルドを採用し、builder ステージで `cargo install` によりバイナリをビルドする。最終ステージには成果物のバイナリのみをコピーし、Rust ツールチェーンは含めない。

```dockerfile
FROM rust:slim AS builder
ARG MDBOOK_VERSION
RUN cargo install mdbook --version $MDBOOK_VERSION
# 他ツールも同様

FROM debian:bookworm-slim
COPY --from=builder /usr/local/cargo/bin/mdbook /usr/local/bin/
```

### 採用理由

GitHub Releases からプリビルドバイナリをダウンロードする方式との比較において、以下の理由で `cargo install` を採用した。

- **マルチアーキテクチャ対応**: バイナリダウンロードでは `amd64`/`arm64` ごとに異なる URL を管理する必要があるが、`cargo install` はアーキテクチャを問わずソースからビルドされるため対応が容易である
- **バイナリ提供の不確実性**: mdbook-plantuml など一部ツールは arm64 向けバイナリを提供していない場合がある
- **バージョン固定の簡潔さ**: `cargo install --version $VERSION` の形式で `ARG` と組み合わせた固定が一貫して書ける

### トレードオフ

- ビルド時間がバイナリダウンロード方式より長くなる。Docker レイヤーキャッシュおよび GitHub Actions のキャッシュを活用して緩和する
