# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

mdBook を PlantUML・Mermaid・CJK フォント・多言語検索付きで実行するための Docker イメージと、その自己ドキュメント (`docs/`) を管理するリポジトリ。

## 主なコマンド

### Docker イメージのビルド

```sh
docker build -t docker-mdbook .
```

バージョン変更は `Dockerfile` 冒頭の `ARG` を書き換える（`MDBOOK_VERSION` など）。

### ドキュメントのローカル操作（`mdbook.sh`）

```sh
./mdbook.sh build          # docs/ をビルド → docs/book/ に出力
./mdbook.sh serve          # ライブプレビュー（http://localhost:3000）
./mdbook.sh watch          # ファイル監視（サーバーなし）
./mdbook.sh stop           # コンテナ停止
./mdbook.sh clean          # docs/book/ と docs/.mdbook-plantuml-cache/ を削除
./mdbook.sh install-assets # Mermaid・lunr アセットを最新イメージから更新
```

`mdbook.sh` は常に `docs/` を対象とし、`ghcr.io/nkenbou/docker-mdbook:latest` を使用する。

## アーキテクチャ

### Dockerfile（マルチステージビルド）

| ステージ | ベースイメージ | 役割 |
|---|---|---|
| `builder` | `rust:slim-bookworm` | mdbook・mdbook-plantuml・mdbook-mermaid を cargo install |
| `downloader` | `debian:bookworm-slim` | PlantUML jar をダウンロード・検証 |
| `node-builder` | `node:lts-bookworm-slim` | pnpm で elasticlunr・lunr-languages をインストール |
| （最終ステージ） | `debian:bookworm-slim` | 全成果物を集約、`docker-mdbook` エントリーポイントを配置 |

最終イメージの `/usr/local/lib/docker-mdbook/` に Node.js アプリ一式（`build-searchindex.js` と `node_modules`）が配置される。Mermaid アセット（`mermaid.min.js`・`mermaid-init.js`）もイメージビルド時に `mdbook-mermaid install` で生成し、同ディレクトリの `assets/` に保存する。

### `docker-mdbook` エントリーポイント

`build` サブコマンドが渡された場合のみ `mdbook build` の直後に `build-searchindex.js` を実行する。それ以外のサブコマンドは `mdbook` にそのまま委譲する。

### 多言語検索パイプライン

mdbook 組み込みの検索インデックス（elasticlunr）は英語以外の言語に対して精度が低いため、ビルド後に言語対応インデックスへ差し替える 2 層構造をとる。対象言語は `book.toml` の `language` フィールドから自動検出する（`en` の場合は処理をスキップ）。

1. **インデックス再生成（ビルド時）**: `build-searchindex.js` が `lunr-languages/lunr.<lang>.js` のトークナイザーを elasticlunr に組み込み、`docs/book/searchindex-*.js` を上書きする。
2. **クエリ処理（ブラウザ実行時）**: `docs/.mdbook/lunr.<lang>.min.js` が同じトークナイザーを elasticlunr のパイプラインに組み込む。`docs/theme/head.hbs` がこのスクリプト群を注入し、elasticlunr と lunr のグローバル変数の競合を防ぐ。

詳細な意思決定は [ADR-0009](docs/adr/ADR-0009-japanese-search-tokenizer.md) を参照（日本語向けの設計が基盤）。

### 静的アセット管理

`docs/.mdbook/` 以下のファイル（`mermaid.min.js`・`mermaid-init.js`・`elasticlunr.min.js`・`lunr.*.min.js`）はイメージに同梱されたものをコピーしたもの。更新は `./mdbook.sh install-assets` で行う。

## CI/CD

| ワークフロー | トリガー | 動作 |
|---|---|---|
| `build.yml` | `main` push / `v*` タグ | マルチアーキテクチャ（amd64・arm64）イメージをビルド。`v*` タグ時のみ GHCR に push |
| `pages.yml` | `main` push | Docker イメージで `docs/` をビルドし GitHub Pages にデプロイ |

## ADR 運用ルール

`docs/adr/` 内の ADR を作成・編集するときは必ず `ADR-0000-template.md` のフォーマットと運用ルールに従う（ステータスをボールドで示す、決定が覆された場合は既存 ADR を修正せず新規 ADR を起こすなど）。
