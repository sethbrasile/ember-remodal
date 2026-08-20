import { pageTitle } from 'ember-page-title';
import DocsShell from '../components/docs-shell.gts';

<template>
  {{pageTitle "ember-remodal"}}

  <DocsShell>{{outlet}}</DocsShell>
</template>
