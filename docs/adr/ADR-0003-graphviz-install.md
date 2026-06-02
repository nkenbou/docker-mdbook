# ADR-0003: Graphviz のインストール方式

Date: 2026/06/03

## ステータス

承認済み

## コンテキスト

PlantUML はクラス図・コンポーネント図・オブジェクト図・アクティビティ図（v1）などの図種を描画する際に Graphviz を必要とする。コンテナ内で PlantUML をローカル実行する方針のため、Graphviz をどう扱うかを決定する必要がある。

## 決定

Debian パッケージの `graphviz` を `apt-get install` でインストールする。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*
```

## 代替案

**インストールしない（Graphviz 不要な図種のみサポート）**

- イメージサイズを小さく保てる
- ただし Graphviz が必要な図種を書いた場合に PlantUML がエラーを返す。原因が分かりにくくユーザーが混乱しやすい

## 影響

- クラス図・コンポーネント図など Graphviz が必要な図種を含め、PlantUML がサポートする図種を広く利用できる
- `apt-get install --no-install-recommends graphviz` 1行で済み、Java ランタイムの方式（ADR-0004）と一貫性がある
- イメージサイズは若干増えるが、`--no-install-recommends` で最小限に抑えられる
