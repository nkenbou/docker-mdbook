# ADR-0009: mdbook 日本語検索のトークナイザー選定

Date: 2026/06/12

## ステータス

下書き、**提案済み**、承認済み、却下、廃止、非推奨、置き換え済み

## コンテキスト

mdbook の組み込み検索機能は elasticlunr-rs を用いてビルド時に検索インデックスを生成し、クライアント側（ブラウザ）では elasticlunr.js でクエリを処理する。

この仕組みには日本語検索に関する以下の問題がある。

**mdbook はデフォルトで日本語をサポートしない**

elasticlunr-rs は `ja` feature フラグ（内部で lindera を使用）を持つが、mdbook 0.5.3 はこれを有効にしていない。インデックス生成時に英語用トークナイザーが適用されるため、日本語テキストは適切に分割されず、日本語での検索が機能しない。

**インデックス生成とクエリ処理のトークナイザー一致が必須**

elasticlunr はインデックス生成時とクエリ処理時に同一のパイプライン（トークナイザー → フィルター → ステマー）を適用してトークンをマッチングする。両者のトークナイザーが異なると正しく検索できない。

```
例:
  インデックス時: "東京都の天気" → tokenize → ["東京", "都", "天気"]（助詞"の"は除去）
  クエリ処理時:  "東京の天気"   → tokenize → ["東京", "天気"] になれば一致するが、
                               異なるトークナイザーを使うと不一致が生じる
```

**lindera はブラウザで動作しない**

elasticlunr-rs の `ja` feature が採用している lindera（IPADIC 辞書ベースの形態素解析エンジン）は Rust ライブラリであり、ブラウザでそのまま動作しない。クライアント側で lindera 互換のトークナイズを再現するには別途対応が必要になる。

## 決定

インデックス生成（ビルド時）とクエリ処理（ブラウザ実行時）の両方に **`Intl.Segmenter`** を使用する。

具体的には以下の方針をとる。

- **インデックス生成**: mdbook のビルド後に Node.js スクリプトを実行し、`Intl.Segmenter('ja', { granularity: 'word' })` で日本語テキストをトークナイズして検索インデックスを再生成し、mdbook が出力した `searchindex-*.js` を上書きする
- **クライアント側**: `Intl.Segmenter` を使う `lunr.ja.js` を生成し、elasticlunr.js のパイプラインに組み込む

トークナイズのロジックは以下の通り（両側で共通）：

```js
const segmenter = new Intl.Segmenter('ja', { granularity: 'word' });
const tokens = [...segmenter.segment(text)]
  .filter(s => s.isWordLike)
  .map(s => s.segment);
```

`isWordLike === false` のセグメント（助詞・記号・句読点など）は除去する。これにより lindera が品詞フィルタで除去していた助詞・助動詞に相当する処理をトークナイズ側で実現する。

## 代替案

**elasticlunr-rs（`ja` feature）+ kuromoji.js**

- ビルド時: mdbook をフォークして lindera（IPADIC）でインデックス生成
- クライアント側: 同じ IPADIC ベースの kuromoji.js でクエリ処理
- 採用しない理由: mdbook 本体のフォーク管理が必要。kuromoji.js の出力は lindera と概ね一致するが完全同一ではなく、辞書バージョン差に起因するトークン不一致が潜在的に残る

**elasticlunr-rs（`ja` feature）+ lindera-wasm**

- ビルド時: lindera でインデックス生成
- クライアント側: lindera を WebAssembly にコンパイルしてブラウザで実行
- 採用しない理由: IPADIC 辞書を含む WASM バイナリのサイズが数十 MB に及び、ページ初回ロードのコストが高い

**tinyseg.js ベースの既存 lunr.jp.js**

- elasticlunr.js の非公式日本語プラグインとして使われている実装
- 採用しない理由: 統計ベースの分割で精度が低く、またビルド時のインデックス生成側との対応物が存在しない（インデックスは英語トークナイザーのまま）

**fzf による検索エンジン置き換え（Issue #2052 の提案）**

- elasticlunr をクライアント側で fzf に差し替えて全文検索を実現
- 採用しない理由: インデックス形式が elasticlunr 互換でなくなり、mdbook の検索 UI との統合が複雑になる。また検索精度の制御が困難

**n-gram（bi-gram）インデックス**

- ビルド時・クライアント側ともに bi-gram で分割することで一致を保証
- 採用しない理由: インデックスサイズが大幅に増加し、短い単語（1〜2文字）での誤検索が増える

## 影響

**メリット**

- ブラウザネイティブ API（`Intl.Segmenter`）を使用するためクライアント側に追加ライブラリが不要
- mdbook 本体のフォークや Dockerfile への Rust 追加ビルドが不要
- Chrome 87+、Firefox 98+、Safari 14.1+ 以降でサポートされており、現代的なブラウザ環境を広くカバーする
- lunr-languages（MihaiValentin 版）がすでに中国語に `Intl.Segmenter` を採用しており、実績がある

**トレードオフ・制約**

- Node.js（ビルド時）とブラウザ（検索時）が保持する ICU データのバージョンが異なる場合、同一テキストへの `Intl.Segmenter` 出力が異なる可能性がある（[Node.js issue #51563](https://github.com/nodejs/node/issues/51563)）。ビルド環境で `full-icu` を使用することで差異を最小化できる
- lindera（形態素解析）と比べると `Intl.Segmenter` は Unicode UAX 29 ルールベースであり、複合名詞の分割精度が劣る場合がある（例: "東京都" を lindera は "東京" + "都" に分割するが、`Intl.Segmenter` は "東京都" のまま返す場合がある）。ただし両側で同じ処理を行うためインデックスとクエリの一貫性は保たれる
- Dockerfile に Node.js のインストールが必要になる（インデックス再生成スクリプトの実行環境として）

## 経過

（実装後に記録する）
