# 設計書

## Java ランタイムのインストール方式

### 概要

PlantUML JAR の実行に必要な JRE をインストールする方式を定める。

### 方式

Debian パッケージの `openjdk-17-jre-headless` を `apt-get install` でインストールする。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*
```

### 採用理由

`default-jre` および Eclipse Temurin upstream イメージからのコピーとの比較において、以下の理由で採用した。

- **イメージサイズ**: `default-jre` は X11 関連のフォント・ディスプレイパッケージを引き込む。コンテナ内で PlantUML JAR を実行するだけなら表示機能は不要であり、`-headless` で十分である
- **バージョンの明示性**: `default-jre` はメタパッケージであり、ベースイメージを将来の Debian リリースへ変更した際に JRE バージョンが暗黙的に変わるリスクがある。`openjdk-17-jre-headless` と明示することで意図が明確になる
- **シンプルさ**: Eclipse Temurin からのコピーは builder ステージの追加とパス設定が必要になるが、`apt-get install` 1 行で済む
