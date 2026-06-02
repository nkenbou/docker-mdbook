# ADR-0001: Rust ツールのインストール方式

Date: 2026/06/03

## ステータス

下書き、提案済み、**承認済み**、却下、廃止、非推奨、置き換え済み

## コンテキスト

Dockerfile 内で mdBook・mdbook-plantuml・mdbook-mermaid をインストールする必要がある。これらはいずれも Rust 製ツールであり、インストール手段として GitHub Releases からのバイナリダウンロードと `cargo install` の2つが候補となる。

## 決定

マルチステージビルドを採用し、builder ステージで `cargo install` によりバイナリをビルドする。最終ステージには成果物のバイナリのみをコピーし、Rust ツールチェーンは含めない。

```dockerfile
FROM rust:slim AS builder
ARG MDBOOK_VERSION
RUN cargo install mdbook --version $MDBOOK_VERSION
# 他ツールも同様

FROM debian:bookworm-slim
COPY --from=builder /usr/local/cargo/bin/mdbook /usr/local/bin/
```

## 代替案

**GitHub Releases からプリビルドバイナリをダウンロードする**

- `amd64`/`arm64` でダウンロード URL が異なるため、マルチアーキテクチャ対応時に Dockerfile が複雑になる
- mdbook-plantuml など一部ツールは arm64 向けバイナリを提供していない場合がある

## 影響

- `cargo install --version $VERSION` の形式で `ARG` と組み合わせたバージョン固定が一貫して書ける
- アーキテクチャを問わずソースからビルドされるため、マルチアーキテクチャ対応が容易である
- ビルド時間はバイナリダウンロード方式より長くなる。Docker レイヤーキャッシュおよび GitHub Actions のキャッシュを活用して緩和する
