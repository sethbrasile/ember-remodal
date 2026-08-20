import { modifier } from 'ember-modifier';

const COPY_LABEL_RESET_MS = 1500;

export default modifier((element: HTMLElement) => {
  const timeouts: ReturnType<typeof setTimeout>[] = [];
  const cleanups: Array<() => void> = [];

  const flashCopyLabel = (button: HTMLButtonElement, label: string): void => {
    button.textContent = label;
    timeouts.push(
      setTimeout(() => {
        button.textContent = 'Copy';
      }, COPY_LABEL_RESET_MS),
    );
  };

  for (const pre of element.querySelectorAll('pre')) {
    if (pre.parentElement?.classList.contains('demo-example-source')) {
      continue;
    }

    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'demo-copy';
    button.textContent = 'Copy';

    const onClick = (): void => {
      const text = pre.textContent ?? '';
      if (!navigator.clipboard) {
        flashCopyLabel(button, 'Copy failed');
        return;
      }
      navigator.clipboard
        .writeText(text)
        .then(() => flashCopyLabel(button, 'Copied'))
        .catch(() => flashCopyLabel(button, 'Copy failed'));
    };

    button.addEventListener('click', onClick);

    const toolbar = document.createElement('div');
    toolbar.className = 'demo-example-toolbar';
    toolbar.append(button);

    const wrapper = document.createElement('div');
    wrapper.className = 'demo-example-source';
    pre.replaceWith(wrapper);
    wrapper.append(toolbar, pre);

    cleanups.push(() => {
      button.removeEventListener('click', onClick);
      wrapper.replaceWith(pre);
    });
  }

  return () => {
    for (const timeout of timeouts) {
      clearTimeout(timeout);
    }
    for (const cleanup of cleanups) {
      cleanup();
    }
  };
});
