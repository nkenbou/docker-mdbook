import elasticlunr from 'elasticlunr';
import stemmerSupport from 'lunr-languages/lunr.stemmer.support.js';
import { createContext, runInContext } from 'vm';
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';

const bookDir = process.argv[2];
if (!bookDir) {
  console.error('Usage: node build-searchindex.js <book-output-dir>');
  process.exit(1);
}

// 優先順位: LUNR_LANG 環境変数 > book.toml の language > "ja"
function detectLang() {
  if (process.env.LUNR_LANG) return process.env.LUNR_LANG.split('-')[0];
  const bookTomlPath = join(dirname(bookDir), 'book.toml');
  if (existsSync(bookTomlPath)) {
    const match = readFileSync(bookTomlPath, 'utf8').match(/^\s*language\s*=\s*"([^"]+)"/m);
    if (match) return match[1].split('-')[0];
  }
  return 'en';
}

const lang = detectLang();
if (lang === 'en') process.exit(0);

stemmerSupport(elasticlunr);
const { default: langModule } = await import(`lunr-languages/lunr.${lang}.js`);
langModule(elasticlunr);
if (elasticlunr[lang]?.tokenizer) {
  elasticlunr.tokenizer = elasticlunr[lang].tokenizer;
}

const files = readdirSync(bookDir).filter(f => /^searchindex.*\.js$/.test(f));
if (files.length === 0) {
  console.error('No searchindex files found in', bookDir);
  process.exit(1);
}

for (const file of files) {
  const filePath = join(bookDir, file);
  const src = readFileSync(filePath, 'utf8');

  const ctx = createContext({ window: { search: {} } });
  runInContext(src, ctx);
  const data = ctx.window.search;

  const idx = elasticlunr(function () {
    this.use(elasticlunr[lang]);
    this.setRef(data.index.ref);
    for (const field of data.index.fields) {
      this.addField(field);
    }
    this.saveDocument(data.index.documentStore.save);
  });

  const docs = data.index.documentStore.docs;
  for (const id of Object.keys(docs)) {
    idx.addDoc(docs[id]);
  }

  data.index = idx.toJSON();

  const escaped = JSON.stringify(data)
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'");
  writeFileSync(filePath, `window.search = Object.assign(window.search, JSON.parse('${escaped}'));\n`);
  console.log('Updated:', file);
}
