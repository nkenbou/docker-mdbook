# ADR-0004: Java ランタイムのインストール方式

Date: 2026/06/03

## ステータス

下書き、提案済み、**承認済み**、却下、廃止、非推奨、置き換え済み

## コンテキスト

PlantUML は JAR ファイルとして配布されており、実行に JRE が必要である。最終ステージのベースイメージは `debian:bookworm-slim` であり、JRE のインストール方式として以下が候補となる。

- Debian パッケージ（`openjdk-17-jre-headless` または `default-jre`）
- Eclipse Temurin など upstream イメージからのコピー

## 決定

Debian パッケージの `openjdk-17-jre-headless` を `apt-get install` でインストールする。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*
```

## 代替案

**`default-jre`**

- メタパッケージであり、ベースイメージを将来の Debian リリースへ変更した際に JRE バージョンが暗黙的に変わるリスクがある
- headless ではなく X11 関連のフォント・ディスプレイパッケージを余分に引き込む

**Eclipse Temurin upstream イメージからのコピー**

- JRE バージョンをイメージタグで完全固定できる
- builder ステージの追加とパスの設定が必要になり、Dockerfile が複雑になる

## 影響

- `apt-get install` 1 行で済み、追加の builder ステージが不要である
- `-headless` により X11 関連パッケージが含まれず、イメージサイズを抑えられる
- `openjdk-17-jre-headless` と明示することでベースイメージ変更時の暗黙的なバージョン変化を防げる
