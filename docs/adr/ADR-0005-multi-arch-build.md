# ADR-0005: マルチアーキテクチャビルドの実現方法

Date: 2026/06/03

<div class="toc-inline">

<!-- toc -->

</div>

## ステータス

下書き、提案済み、**承認済み**、却下、廃止、非推奨、置き換え済み

## コンテキスト

GitHub Actions で `amd64`/`arm64` 両対応のイメージを GHCR に push する必要がある。
実現手段として `docker buildx bake` と `docker buildx build --platform` の直接指定の2つが候補に挙がっていた。

## 決定

`docker buildx build --platform linux/amd64,linux/arm64` を直接指定する方式を採用する。

このプロジェクトは単一イメージを管理するシンプルな構成であり、ワークフローファイル内で完結する直接指定で十分に要件を満たせる。

## 代替案

### `docker buildx bake` を使う

ビルド設定を `docker-bake.hcl` として外部化し、宣言的に管理する方式。
複数イメージや複数タグを一括管理する場合に強力だが、管理ファイルが増える。
本プロジェクトは単一イメージのため、`bake` の恩恵を受けにくく採用しなかった。

## 影響

- GitHub Actions ワークフローのみで設定が完結し、追加ファイルが不要
- `docker/build-push-action` の `platforms` パラメータに `linux/amd64,linux/arm64` を指定することで実現する
- 将来的にイメージが複数になった場合は `bake` への移行を検討する

## 経過

