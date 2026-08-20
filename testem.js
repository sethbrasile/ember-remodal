module.exports = {
  test_page: 'tests/index.html?hidepassed&coverage',
  disable_watching: true,
  launch_in_ci: [
    'Chrome'
  ],
  launch_in_dev: [
  ],
  browser_args: {
    Chrome: {
      mode: 'ci',
      args: [
        // --no-sandbox is needed when running Chrome inside a container
        process.env.TRAVIS ? '--no-sandbox' : null,

        '--disable-gpu',
        '--headless=new', '--no-sandbox', '--user-data-dir=/tmp/testem-chrome-profile', '--disable-dev-shm-usage',
        '--remote-debugging-port=0',
        '--window-size=1440,900'
      ].filter(Boolean)
    }
  }
};
