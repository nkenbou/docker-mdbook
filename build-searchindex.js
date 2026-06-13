import elasticlunr from 'elasticlunr';
import stemmerSupport from 'lunr-languages/lunr.stemmer.support.js';
import ja from 'lunr-languages/lunr.ja.js';
import { createContext, runInContext } from 'vm';
import { readdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

stemmerSupport(elasticlunr);
ja(elasticlunr);
elasticlunr.tokenizer = elasticlunr.ja.tokenizer;

const bookDir = process.argv[2];
if (!bookDir) {
  console.error('Usage: node build-searchindex.js <book-output-dir>');
  process.exit(1);
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
    this.use(elasticlunr.ja);
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
