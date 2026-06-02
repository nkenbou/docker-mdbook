# 未決設計事項

設計判断が必要な（実現手段に選択肢がある）項目。

## 3. マルチアーキテクチャビルドの実現方法

GitHub Actions での `amd64`/`arm64` 対応をどう実装するか。

- `docker buildx bake` を使う
- `docker buildx build --platform linux/amd64,linux/arm64` を直接指定する

## 5. イメージタグ戦略

GHCR に push する際のタグ命名規則が未定。

- `:latest` のみ
- mdBook のバージョンをタグに含める（例：`v0.4.40`）
- リポジトリ側のバージョン（Git タグ）をタグにする

## 6. GitHub Actions のキャッシュ戦略

`cargo install` のビルド時間緩和のため、何をキャッシュするか。

- `~/.cargo` と `target/` を `actions/cache` でキャッシュする
- Docker の BuildKit キャッシュ（`cache-from: type=gha`）に頼る
- 両方併用する
