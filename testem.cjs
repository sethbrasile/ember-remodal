'use strict';

// Chrome suspends requestAnimationFrame, throttles timers and stops advancing
// CSS animations in a window it considers occluded or backgrounded. This addon's
// open/close transitions wait on frames and on `animation.finished`, so a
// backgrounded window turns every animated transition into a test that hangs
// until `QUnit.config.testTimeout` fires — the classic "only fails on someone
// else's machine" failure. Needed in headless CI (where the window is never
// foregrounded) and in an interactive run (where the developer switches away).
const keepFramesRunning = [
  '--disable-backgrounding-occluded-windows',
  '--disable-renderer-backgrounding',
  '--disable-background-timer-throttling',
];

if (typeof module !== 'undefined') {
  module.exports = {
    test_page: 'tests/index.html?hidepassed',
    cwd: 'dist-tests',
    disable_watching: true,
    launch_in_ci: ['Chrome'],
    launch_in_dev: ['Chrome'],
    browser_start_timeout: 120,
    ...(process.env.CHROME_BIN
      ? { browser_paths: { Chrome: process.env.CHROME_BIN } }
      : {}),
    browser_args: {
      Chrome: {
        ci: [
          // --no-sandbox is needed when running Chrome inside a container;
          // a custom CHROME_BIN almost always means exactly that.
          process.env.CI || process.env.CHROME_BIN ? '--no-sandbox' : null,
          '--headless=new',
          '--disable-dev-shm-usage',
          '--disable-software-rasterizer',
          '--mute-audio',
          '--remote-debugging-port=0',
          '--window-size=1440,900',
          ...keepFramesRunning,
        ].filter(Boolean),
        // Without a `dev:` key, `testem` (and `testem launchers`) starts an
        // unflagged Chrome for interactive debugging — which is exactly the run
        // where a backgrounded window matters, because the developer is looking
        // at their editor while the suite runs.
        dev: [...keepFramesRunning],
      },
    },
  };
}
