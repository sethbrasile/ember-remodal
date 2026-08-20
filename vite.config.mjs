import { createRequire } from 'node:module';
import { defineConfig } from 'vite';
import { extensions, ember, classicEmberSupport } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import demoHighlight from './demo-app/vite/highlight.mjs';

const require = createRequire(import.meta.url);
const pkg = require('./package.json');

// For scenario testing
const isCompat = Boolean(process.env.ENABLE_COMPAT_BUILD);

export default defineConfig(({ mode }) => ({
  plugins: [
    demoHighlight(),
    ...(isCompat ? [classicEmberSupport()] : []),
    ember(),
    babel({
      babelHelpers: 'inline',
      extensions,
    }),
  ],
  define: {
    'import.meta.env.DEMO_VERSION': JSON.stringify(pkg.version),
  },
  ...(mode === 'demo'
    ? {
        base: '/ember-remodal/',
        build: {
          rollupOptions: {
            input: 'index.html',
          },
        },
      }
    : {
        build: {
          rollupOptions: {
            input: {
              tests: 'tests/index.html',
            },
          },
        },
      }),
}));
