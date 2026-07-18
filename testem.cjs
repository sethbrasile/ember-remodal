'use strict';

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
        ].filter(Boolean),
      },
    },
  };
}
