# ADR-0007: GitHub Actions のキャッシュ戦略

Date: 2026/06/03

## ステータス

下書き、提案済み、**承認済み**、却下、廃止、非推奨、置き換え済み

## コンテキスト

Rust ツール（mdBook・mdbook-plantuml・mdbook-mermaid）は Dockerfile 内で `cargo install` によりビルドする。
`cargo install` はコンパイル時間が長く、GitHub Actions のビルド時間を短縮するためにキャッシュが必要である。

キャッシュ対象の候補として以下が挙がった。

- ランナー上の `~/.cargo` と `target/` を `actions/cache` でキャッシュする
- Docker BuildKit の GHA キャッシュバックエンド（`type=gha`）を利用する
- 両方を併用する

## 決定

Docker BuildKit の GHA キャッシュ（`cache-from`/`cache-to: type=gha`）のみを採用する。

Rust ツールは Docker 内でビルドするため、ランナー上の `~/.cargo` や `target/` は Docker ビルドに直接影響しない。
BuildKit のレイヤーキャッシュは `cargo install` を含む RUN 命令を丸ごとキャッシュするため、バージョンを変更しない限り再コンパイルが発生しない。
マルチアーキテクチャビルド（ADR-0005）との組み合わせでは、アーキテクチャごとに `scope` を分けることで独立したキャッシュを維持する。

## 代替案

### `actions/cache` で `~/.cargo` と `target/` をキャッシュする

ランナー上の Cargo キャッシュをホストキャッシュとして保持する方式。
Docker ビルド内の `cargo install` に効かせるには Dockerfile 側で `RUN --mount=type=cache,target=/root/.cargo/registry` を使う必要があり、Dockerfile の変更と BuildKit キャッシュマウントの理解が追加で必要になる。
得られる効果に対して構成の複雑さが増すため採用しなかった。

### 両方を併用する

BuildKit GHA キャッシュに加えて `--mount=type=cache` を Dockerfile に追加することで、レイヤーキャッシュが無効化された場合でも cargo レジストリの再ダウンロードを省略できる。
効果は高いが、Dockerfile の変更が必要になり、単一イメージ・小規模チームの本プロジェクトでは過剰と判断した。

## 影響

- GitHub Actions ワークフローに `cache-from` と `cache-to` の指定を追加するだけで済み、Dockerfile の変更は不要
- `scope` をアーキテクチャ（`linux/amd64`・`linux/arm64`）ごとに分けることでマルチアーキテクチャビルドのキャッシュが干渉しない
- `cargo install` のバージョンや Dockerfile の該当レイヤーより前の命令が変わった場合はキャッシュが無効化され、フルビルドが発生する

## 経過

