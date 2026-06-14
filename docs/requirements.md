# 要件定義

<div class="toc-inline">

<!-- toc -->

</div>

## 概要

mdBook をビルドするための Docker イメージを作成する。
PlantUML はネットワーク越しの使用を避け、コンテナ内でローカル実行する。

## 使用ツール

| ツール | リポジトリ |
|---|---|
| mdBook | https://github.com/rust-lang/mdBook |
| mdbook-plantuml | https://github.com/sytsereitsma/mdbook-plantuml |
| mdbook-mermaid | https://github.com/badboy/mdbook-mermaid |
| PlantUML | https://github.com/plantuml/plantuml |

### イメージ内ツール構成

```plantuml
@startuml
skinparam componentStyle rectangle

package "Docker Image (debian:bookworm-slim)" {
  component [mdbook] as mdbook
  component [mdbook-plantuml] as plantuml_plugin
  component [mdbook-mermaid] as mermaid_plugin
  component [PlantUML JAR] as plantuml
  component [Graphviz] as graphviz
  component [OpenJDK 17] as java
  component [fonts-noto-cjk] as fonts
}

plantuml_plugin --> plantuml : calls
plantuml --> graphviz : uses
plantuml --> java : runs on
plantuml --> fonts : CJK rendering
@enduml
```

## 機能要件

### コンテナの使い方

`mdbook` を ENTRYPOINT に設定し、サブコマンドとして渡す形式で使用する。

```sh
docker container run ... [イメージ名] build
docker container run ... [イメージ名] serve
docker container run ... [イメージ名] watch
```

### ソースファイルの入出力

ボリュームマウントでソースディレクトリをコンテナに渡す。

```sh
docker container run -v $(pwd):/book -w /book [イメージ名] build
```

### PlantUML のローカル実行

PlantUML をコンテナ内でローカル実行し、外部サーバーへのネットワーク通信を行わない。

## バージョン管理

- 全ツール（mdBook、mdbook-plantuml、mdbook-mermaid、PlantUML）のバージョンを Dockerfile の `ARG` で固定する
- バージョンを更新したいときは `ARG` の値を書き換えてイメージを作り直す

## ホスティング・CI/CD

- Dockerfile などのソースは GitHub リポジトリで管理する
- ビルド済みイメージは GHCR（GitHub Container Registry）で公開する
- `main` ブランチへのプッシュ時に GitHub Actions でイメージを自動ビルド・プッシュする

### CI/CD フロー

```mermaid
flowchart LR
    push["git push\n(main)"] --> gha["GitHub Actions"]
    gha --> build["Docker Build\nlinux/amd64\nlinux/arm64"]
    build --> ghcr["GHCR\nghcr.io/nkenbou/\ndocker-mdbook"]
```
