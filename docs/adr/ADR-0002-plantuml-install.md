# ADR-0002: PlantUML のインストール方式

Date: 2026/06/03

## ステータス

承認済み

## コンテキスト

Dockerfile 内で PlantUML をインストールする必要がある。インストール手段として、JAR ファイルの直接ダウンロード・apt によるインストール・公式 Docker イメージからのコピーの3つが候補となる。また、ダウンロードしたファイルのチェックサム確認を行うかどうかも検討が必要である。

## 決定

GitHub Releases から JAR ファイルを直接ダウンロードする。チェックサム確認は行わない。

```dockerfile
ARG PLANTUML_VERSION
RUN wget -q -O /usr/local/lib/plantuml.jar \
    https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar
```

## 代替案

**apt でインストールする**

- Debian パッケージのバージョンに依存するため、`ARG` による任意バージョンの固定が難しい

**公式 Docker イメージからコピーする**

- 実態は JAR をコピーするだけであり、JAR 直接ダウンロードと本質的に同じ
- マルチステージビルドの builder ステージを追加する手間が生じる

**チェックサム確認を行う**

- PlantUML は公式リリースに `.sha256` ファイルを提供していないため、チェックサム値の自前管理が必要になる
- バージョンアップのたびにチェックサム値も更新する運用コストが生じ、`ARG` の値を書き換えるだけというシンプルな運用が崩れる

## 影響

- `ARG` で任意バージョンを直接指定でき、バージョン固定が確実になる
- ダウンロード URL により出所が明確に追跡できる
- ダウンロード元が GitHub Releases の HTTPS URL であり、TLS により中間者攻撃を防いでいる
