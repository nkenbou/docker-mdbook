# 設計書

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

## Graphviz のインストール方式

### 概要

PlantUML が必要とする Graphviz をインストールする方式を定める。

### 方式

Debian パッケージの `graphviz` を `apt-get install` でインストールする。

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*
```

### 採用理由

インストールしない（Graphviz 不要な図種のみサポート）との比較において、以下の理由でインストールを採用した。

- **対応図種の広さ**: クラス図・コンポーネント図・オブジェクト図・アクティビティ図（v1）など、Graphviz が必要な図種は多い。インストールしない場合、ユーザーが図種を書いた際に PlantUML がエラーを返すが、その原因が分かりにくく混乱を招きやすい
- **汎用性**: mdBook ビルド用の汎用イメージとして、図種の制限を設けないほうが実用的である
- **シンプルさ**: `apt-get install --no-install-recommends graphviz` 1行で済み、Java ランタイムの方式と一貫性がある

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
