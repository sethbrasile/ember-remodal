import { pageTitle } from 'ember-page-title';
import { htmlSafe } from '@ember/template';
import type { SafeString } from '@ember/template';
import migrationSrc from '../../MIGRATION.md?highlight';

function trustedHtml(html: string): SafeString {
  return htmlSafe(html);
}

<template>
  {{pageTitle "Migrating from 2.x"}}

  <h1>Migrating from 2.x</h1>
  <p class="docs-lede">The full 2.x → 3.0 migration guide, rendered from
    <a
      href="https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md"
    >MIGRATION.md</a>.</p>

  <article class="docs-markdown">{{trustedHtml migrationSrc.html}}</article>
</template>
