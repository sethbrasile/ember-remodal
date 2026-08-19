/**
 * Debugging:
 *   https://eslint.org/docs/latest/use/configure/debug
 *  ----------------------------------------------------
 *
 *   Print a file's calculated configuration
 *
 *     npx eslint --print-config path/to/file.js
 *
 *   Inspecting the config
 *
 *     npx eslint --inspect-config
 *
 */
import babelParser from '@babel/eslint-parser/experimental-worker';
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import prettier from 'eslint-config-prettier';
import ember from 'eslint-plugin-ember/recommended';
import importPlugin from 'eslint-plugin-import';
import n from 'eslint-plugin-n';
import qunit from 'eslint-plugin-qunit';
import globals from 'globals';
import ts from 'typescript-eslint';

const esmParserOptions = {
  ecmaFeatures: { modules: true },
  ecmaVersion: 'latest',
};

const tsParserOptions = {
  projectService: true,
  tsconfigRootDir: import.meta.dirname,
};

export default defineConfig([
  globalIgnores([
    'dist/',
    'dist-*/',
    'declarations/',
    'coverage/',
    // Sources for the throwaway consumer project that
    // `scripts/verify-published-package.mjs` builds. They are compiled and run
    // THERE, against the packed tarball, where `ember-remodal` resolves to
    // `dist/`. Linting them here judges them against this repo's tsconfig,
    // which maps those same specifiers back to `src/` — so the rules that fire
    // ("do not import test-support into production code") are answering a
    // question about a file that is not part of this package.
    'scripts/publish-gate/',
    '!**/.*',
  ]),
  js.configs.recommended,
  prettier,
  ember.configs.base,
  ember.configs.gjs,
  ember.configs.gts,
  /**
   * https://eslint.org/docs/latest/use/configure/configuration-files#configuring-linter-options
   */
  {
    linterOptions: {
      reportUnusedDisableDirectives: 'error',
    },
  },
  {
    files: ['**/*.js'],
    languageOptions: {
      parser: babelParser,
    },
  },
  {
    files: ['**/*.{js,gjs}'],
    languageOptions: {
      parserOptions: esmParserOptions,
      globals: {
        ...globals.browser,
      },
    },
  },
  {
    files: ['**/*.{ts,gts}'],
    languageOptions: {
      parser: ember.parser,
      parserOptions: tsParserOptions,
      globals: {
        ...globals.browser,
      },
    },
    extends: [
      ...ts.configs.recommendedTypeChecked,
      // https://github.com/ember-cli/ember-addon-blueprint/issues/119
      {
        ...ts.configs.eslintRecommended,
        files: undefined,
      },
      ember.configs.gts,
    ],
  },
  {
    files: ['src/**/*'],
    plugins: {
      import: importPlugin,
    },
    rules: {
      // require relative imports use full extensions
      'import/extensions': ['error', 'always', { ignorePackages: true }],
    },
  },
  /**
   * Tests. `eslint-plugin-qunit` catches the failure modes that make a suite
   * lie: an assertion the test never reaches, an `assert.ok(a && b)` that
   * reports one result for two facts, a `test.only` left behind, a duplicated
   * test name that shadows another test.
   */
  {
    files: ['tests/**/*.{js,ts,gjs,gts}'],
    // `qunit.configs.recommended` is still eslintrc-shaped (`plugins` as an
    // array of names), so take its rules and register the plugin ourselves.
    plugins: { qunit },
    rules: {
      ...qunit.configs.recommended.rules,
      // Off deliberately: `setupRemodal`'s teardown pushes an extra assertion
      // when (and only when) it catches a leaked scroll lock, so a hardcoded
      // `assert.expect(n)` in every test would turn one real failure into two
      // confusing ones. The suite has no dynamically-skipped assertions that
      // `expect` would otherwise be protecting.
      'qunit/require-expect': 'off',
    },
  },

  /**
   * demo-app/examples/testing/example-test.ts is a documentation exhibit, not
   * production code or a real suite member: it lives outside tests/, is never
   * executed, and exists solely to be shown (via `?highlight`) on the Testing
   * page as a realistic `ember-remodal/test-support` consumer. `no-test-support-import`
   * exists to catch a real addon importing its own test helpers into
   * production code, which is not what this file does — it just doesn't live
   * under a tests/ or test-support/ directory, which is the rule's only signal.
   */
  {
    files: ['demo-app/examples/testing/example-test.ts'],
    rules: {
      'ember/no-test-support-import': 'off',
    },
  },

  /**
   * CJS node files
   */
  {
    files: ['**/*.cjs'],
    plugins: {
      n,
    },

    languageOptions: {
      sourceType: 'script',
      ecmaVersion: 'latest',
      globals: {
        ...globals.node,
      },
    },
  },
  /**
   * ESM node files
   */
  {
    files: ['**/*.mjs'],
    plugins: {
      n,
    },

    languageOptions: {
      sourceType: 'module',
      ecmaVersion: 'latest',
      parserOptions: esmParserOptions,
      globals: {
        ...globals.node,
      },
    },
  },
]);
