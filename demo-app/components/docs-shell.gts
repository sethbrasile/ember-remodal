import { LinkTo } from '@ember/routing';
import type { TOC } from '@ember/component/template-only';
import SidebarNav from './sidebar-nav.gts';

const version = import.meta.env.DEMO_VERSION;

interface DocsShellSignature {
  Blocks: { default: [] };
}

const DocsShell: TOC<DocsShellSignature> = <template>
  <header class="docs-topbar">
    <LinkTo @route="index" class="docs-brand">ember-remodal</LinkTo>
    <span class="docs-version">v{{version}}</span>
    <a
      href="https://github.com/sethbrasile/ember-remodal"
      target="_blank"
      rel="noopener noreferrer"
    >GitHub</a>
    <a
      href="https://www.npmjs.com/package/ember-remodal"
      target="_blank"
      rel="noopener noreferrer"
    >npm</a>
  </header>

  <div class="docs-layout">
    <SidebarNav />
    <main class="docs-main">{{yield}}</main>
  </div>

  <footer class="demo-footer">
    <p>
      MIT licensed. Styles ported from
      <a href="https://github.com/vodkabears/Remodal">Remodal</a>
      by Ilya Makarov.
    </p>
  </footer>
</template>;

export default DocsShell;
