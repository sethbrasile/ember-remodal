import { pageTitle } from 'ember-page-title';
import DemoExample from '../../components/demo-example.gts';
import PromiseChain from '../../examples/service/promise-chain.gts';
import promiseChainSrc from '../../examples/service/promise-chain.gts?highlight';
import PromiseStacked from '../../examples/service/promise-stacked.gts';
import promiseStackedSrc from '../../examples/service/promise-stacked.gts?highlight';
import PromiseAwaitThenMutate from '../../examples/service/promise-await-then-mutate.gts';
import promiseAwaitThenMutateSrc from '../../examples/service/promise-await-then-mutate.gts?highlight';

<template>
  {{pageTitle "Promises"}}

  <h1>Promises</h1>
  <p class="docs-lede">A promise playground: open-then-close chains, stacked
    modals, and awaiting an open before mutating state.</p>

  <DemoExample
    @title="Open, then auto-close"
    @component={{PromiseChain}}
    @source={{promiseChainSrc}}
  />

  <DemoExample
    @title="Open over open"
    @description="Stacked modals work naturally via the browser's top layer, and the scroll lock is reference-counted across them."
    @component={{PromiseStacked}}
    @source={{promiseStackedSrc}}
  />

  <DemoExample
    @title="Await open, then mutate"
    @description="await this.remodal.open(name), then set tracked state the open modal re-renders with."
    @component={{PromiseAwaitThenMutate}}
    @source={{promiseAwaitThenMutateSrc}}
  />
</template>
