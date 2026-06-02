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

## PlantUML のインストール方式

### 概要

Dockerfile 内で PlantUML をインストールする方式を定める。

### 方式

GitHub Releases から JAR ファイルを直接ダウンロードする。

```dockerfile
ARG PLANTUML_VERSION
RUN wget -q -O /usr/local/lib/plantuml.jar \
    https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar
```

### 採用理由

apt・公式 Docker イメージからのコピーとの比較において、以下の理由で JAR 直接ダウンロードを採用した。

- **バージョン固定の確実さ**: apt は Debian パッケージのバージョンに依存するため `ARG` による任意バージョンの固定が難しい。JAR ダウンロードは `ARG` で任意バージョンを直接指定できる
- **シンプルさ**: 公式 Docker イメージからのコピーは builder ステージを追加する必要があるが、JAR ダウンロードは `wget` 1 行で済む
- **透明性**: ダウンロード URL により出所が明確に追跡できる

### チェックサム確認について

チェックサム確認は行わない。

- ダウンロード元が GitHub Releases の HTTPS URL であり、TLS により中間者攻撃を防いでいる
- PlantUML は公式リリースに `.sha256` ファイルを提供していないため、チェックサム値の自前管理が必要になる
- バージョンアップのたびにチェックサム値も更新する運用コストが生じ、`ARG` の値を書き換えるだけというシンプルな運用が崩れる
