# docker-mdbook

🇺🇸 [English](./README.md) | 🇯🇵 日本語

mdBook をビルド・プレビューするための Docker イメージです。PlantUML、Mermaid、日本語フォントをコンテナ内で完結して利用できます。

## イメージ構成

| コンポーネント | 内容 |
|---|---|
| ベースイメージ | `debian:bookworm-slim` |
| [mdBook](https://github.com/rust-lang/mdBook) | Markdown ドキュメントビルダー |
| [mdbook-plantuml](https://github.com/sytsereitsma/mdbook-plantuml) | PlantUML プリプロセッサ |
| [mdbook-mermaid](https://github.com/badboy/mdbook-mermaid) | Mermaid プリプロセッサ |
| [PlantUML](https://github.com/plantuml/plantuml) | ダイアグラム生成（ローカル実行） |
| Graphviz | PlantUML が使用するグラフ描画エンジン |
| OpenJDK 17 | PlantUML の実行環境 |
| fonts-noto-cjk | 日本語・中国語・韓国語フォント |

PlantUML は外部サーバーを使わずコンテナ内でローカル実行するため、ネットワーク非接続環境でも動作します。

## 対応アーキテクチャ

`linux/amd64` / `linux/arm64`

## 使い方

### ラッパースクリプト（推奨）

リポジトリに付属の `mdbook.sh` を使うと、`docs/` ディレクトリを対象に簡単にコマンドを実行できます。

```sh
# ビルド
./mdbook.sh build

# ライブプレビュー（デフォルト: http://localhost:3000）
./mdbook.sh serve

# ファイル監視（再ビルドのみ、サーバーなし）
./mdbook.sh watch

# サーバー停止
./mdbook.sh stop

# ビルド成果物とキャッシュの削除
./mdbook.sh clean

# mermaid アセットを最新イメージから更新
./mdbook.sh install-assets
```

ポートは環境変数 `MDBOOK_PORT` で変更できます（デフォルト: `3000`）。

```sh
MDBOOK_PORT=4000 ./mdbook.sh serve
```

### Docker コマンドで直接使う

```sh
# ビルド
docker run --rm -v $(pwd):/book --user $(id -u):$(id -g) \
  ghcr.io/nkenbou/docker-mdbook:latest build

# ライブプレビュー
docker run --rm -v $(pwd):/book -p 3000:3000 --user $(id -u):$(id -g) \
  ghcr.io/nkenbou/docker-mdbook:latest serve --hostname 0.0.0.0
```

## イメージの取得

```sh
docker pull ghcr.io/nkenbou/docker-mdbook:latest
```

タグ一覧は [GHCR パッケージページ](https://github.com/nkenbou/docker-mdbook/pkgs/container/docker-mdbook) を参照してください。

## ビルド

バージョンは `Dockerfile` の `ARG` で固定されています。変更する場合は各 `ARG` の値を書き換えてください。

```sh
docker build -t docker-mdbook .
```

## ドキュメント

`docs/` ディレクトリの内容が GitHub Pages に公開されています：
**https://nkenbou.github.io/docker-mdbook/**

## CI/CD

`main` ブランチへのプッシュ時に GitHub Actions でマルチアーキテクチャイメージを自動ビルドし、タグ（`v*`）プッシュ時に GHCR へ公開します。ドキュメントも `main` へのプッシュ時に GitHub Pages へ自動デプロイされます。

## ライセンス

[LICENSE](./LICENSE) を参照してください。
