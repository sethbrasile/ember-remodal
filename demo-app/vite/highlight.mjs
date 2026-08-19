// Vite plugin: `import source from './example.gts?highlight'` yields
// `{ html, text, lang }` — Shiki-highlighted HTML and the raw (marker-stripped)
// source of the SAME file a page renders as a live example. Registered only in
// vite.config.mjs; never part of the addon's rollup/publish build.
import { readFileSync } from 'node:fs';
import { extname } from 'node:path';
import { createHighlighter } from 'shiki';
import { marked } from 'marked';

const VIRTUAL_PREFIX = '\0demo-highlight:';

const LANGS = [
  'glimmer-ts',
  'glimmer-js',
  'typescript',
  'javascript',
  'css',
  'bash',
  'handlebars',
  'json',
  'diff',
  'html',
  'markdown',
];

const EXTENSION_LANGS = {
  '.gts': 'glimmer-ts',
  '.gjs': 'glimmer-js',
  '.ts': 'typescript',
  '.js': 'javascript',
  '.css': 'css',
};

// Aliases accepted inside MIGRATION.md's fenced code blocks — the guide
// predates this plugin and uses the names a reader (not Shiki) expects.
const FENCE_LANG_ALIASES = {
  hbs: 'handlebars',
  gjs: 'glimmer-js',
  gts: 'glimmer-ts',
  sh: 'bash',
  shell: 'bash',
};

let highlighterPromise;

function getHighlighter() {
  highlighterPromise ??= createHighlighter({
    themes: ['github-dark'],
    langs: LANGS,
  });
  return highlighterPromise;
}

// Strips every `// demo-hide` … `// demo-show` block (both markers inclusive)
// from the source shown on the site. The code still runs — only the string
// passed to the highlighter/exported as `text` is trimmed.
function stripDemoMarkers(source, filePath) {
  const lines = source.split('\n');
  const kept = [];
  let hiding = false;
  for (const line of lines) {
    const trimmed = line.trim();
    if (!hiding && trimmed === '// demo-hide') {
      hiding = true;
      continue;
    }
    if (hiding && trimmed === '// demo-show') {
      hiding = false;
      continue;
    }
    if (!hiding) {
      kept.push(line);
    }
  }
  if (hiding) {
    throw new Error(
      `demo-highlight: "${filePath}" has an unterminated "// demo-hide" block (no matching "// demo-show").`,
    );
  }
  return kept.join('\n');
}

function langForFile(filePath) {
  const ext = extname(filePath);
  const lang = EXTENSION_LANGS[ext];
  if (!lang) {
    throw new Error(
      `demo-highlight: "${filePath}" has no supported language mapping for extension "${ext}".`,
    );
  }
  return lang;
}

async function highlightCode(filePath) {
  const raw = readFileSync(filePath, 'utf8');
  const text = stripDemoMarkers(raw, filePath);
  const lang = langForFile(filePath);
  const highlighter = await getHighlighter();
  const html = highlighter.codeToHtml(text, { lang, theme: 'github-dark' });
  return { html, text, lang };
}

async function highlightMarkdown(filePath) {
  const text = readFileSync(filePath, 'utf8');
  const highlighter = await getHighlighter();
  const renderer = {
    code(token) {
      const requested = (token.lang ?? '').trim().split(/\s+/)[0] ?? '';
      const lang = FENCE_LANG_ALIASES[requested] ?? requested;
      if (lang && LANGS.includes(lang)) {
        return highlighter.codeToHtml(token.text, {
          lang,
          theme: 'github-dark',
        });
      }
      const escaped = token.text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
      return `<pre><code>${escaped}</code></pre>`;
    },
  };
  marked.use({ renderer });
  const html = await marked.parse(text);
  return { html, text, lang: 'markdown' };
}

export default function demoHighlight() {
  return {
    name: 'demo-highlight',
    enforce: 'pre',
    async resolveId(source, importer) {
      if (!source.endsWith('?highlight')) {
        return null;
      }
      const stripped = source.slice(0, -'?highlight'.length);
      const resolved = await this.resolve(stripped, importer, {
        skipSelf: true,
      });
      if (!resolved) {
        return null;
      }
      return VIRTUAL_PREFIX + resolved.id;
    },
    async load(id) {
      if (!id.startsWith(VIRTUAL_PREFIX)) {
        return null;
      }
      const filePath = id.slice(VIRTUAL_PREFIX.length);
      this.addWatchFile(filePath);
      const { html, text, lang } =
        extname(filePath) === '.md'
          ? await highlightMarkdown(filePath)
          : await highlightCode(filePath);
      return `export const html = ${JSON.stringify(html)};
export const text = ${JSON.stringify(text)};
export const lang = ${JSON.stringify(lang)};
export default { html, text, lang };
`;
    },
  };
}
