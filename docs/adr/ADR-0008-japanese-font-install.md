# ADR-0008: PlantUML 日本語フォントのインストール方式

Date: 2026/06/03

<div class="toc-inline">

<!-- toc -->

</div>

## ステータス

下書き、提案済み、**承認済み**、却下、廃止、非推奨、置き換え済み

## コンテキスト

PlantUML は Java の AWT（Abstract Window Toolkit）を使って図を描画する。描画時に使用するフォントは Java がシステムフォントを fontconfig 経由で検索する。`debian:bookworm-slim` をベースイメージとした場合、日本語フォントが含まれないため、日本語テキストを含む図を描画すると文字が「□」（豆腐）として表示される。日本語テキストを正しく描画するために、コンテナ内に日本語フォントをインストールする必要がある。

## 決定

Debian パッケージの `fonts-noto-cjk` を `apt-get install` でインストールする。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*
```

## 代替案

**`fonts-ipafont-gothic`**

- IPA（独立行政法人情報処理推進機構）が配布するゴシックフォント
- インストールサイズは約 12 MB と軽量
- 知名度・普及度が `fonts-noto-cjk` より低く、見慣れていないため採用しない

**`fonts-vlgothic`**

- 軽量なゴシックフォントだが、メンテナンスが停止している
- 採用しない

**PlantUML の `skinparam defaultFontName` で外部フォントを指定する**

- ユーザーが `book.toml` の設定で PlantUML にフォント名を渡す方式
- ユーザー側に設定負担が生じるため採用しない

## 影響

- Google が開発・維持する Noto フォントは普及度・知名度が高く、図の描画結果がユーザーの期待するフォントと一致しやすい
- インストールサイズは約 91 MB であり、`fonts-ipafont-gothic`（約 12 MB）と比べてイメージサイズが増加する
- 日本語に加えて中国語・韓国語もカバーするため、CJK 全般の多言語利用にも対応できる
- `openjdk-17-jre-headless`（ADR-0004）が依存する `fontconfig` により、インストールしたフォントは Java から自動的に検索される。追加の JVM オプションや PlantUML の設定変更は不要
