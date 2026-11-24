# ember-remodal

[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg?branch=master)](https://travis-ci.org/sethbrasile/ember-remodal) [![npm version](https://badge.fury.io/js/ember-remodal.svg)](http://badge.fury.io/js/ember-remodal) [![Code Climate](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/gpa.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal) [![Dependencies](https://david-dm.org/sethbrasile/ember-remodal.svg)](https://david-dm.org/sethbrasile/ember-remodal) [![Test Coverage](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/coverage.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal/coverage) [![Ember Observer Score](http://emberobserver.com/badges/ember-remodal.svg)](http://emberobserver.com/addons/ember-remodal) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QDPUK852HN9U2)

#### [Interactive Demo/Documentation](http://sethbrasile.github.io/ember-remodal)

Under the hood, ember-remodal uses a jQuery-based modal library called
[remodal](http://vodkabears.github.io/remodal/).

## Compatibility

2.18.1 is tested on the configurations below, and [CI](https://github.com/sethbrasile/ember-remodal/actions/workflows/compatibility.yml) runs all of them on every push.

The addon's own test suite, on Node 8.17.0 with Ember CLI 2.18.2:

| Ember  | What runs                         |
| :----- | :-------------------------------- |
| 2.12.2 | full suite                        |
| 2.16.4 | full suite                        |
| 2.18.2 | full suite and a production build |

Separate apps that install the packed tarball (the same file that gets published) and run in headless Chrome:

| App     | Ember   | jQuery | Setup                                                                                              |
| :------ | :------ | :----- | :------------------------------------------------------------------------------------------------- |
| `floor` | 2.3.2   | 2.2.4  | Ember CLI 2.18.2 app on Node 8.17.0, with the Ember 2.3.2 runtime and template compiler swapped in |
| `2.18`  | 2.18.2  | 3.3.1  | the same app, untouched                                                                            |
| `3.28`  | 3.28.12 | 3.8.0  | Ember CLI 3.28.6 app on Node 24.21.0, with `@ember/jquery` 0.5.2                                   |

Each app opens the modal from a block trigger (`{{#modal.open}}`), opens and closes it through the `remodal` service, and checks that closing a modal that was never opened still resolves to the component.

On Ember 3.28 your app needs `@ember/jquery` and the `jquery-integration` optional feature turned on. Ember warns about that flag at build time. The app then logs these deprecations from ember-remodal and ember-wormhole: `ember-global`, `this-property-fallback`, `ember-component.send-action`, `ember-views.curly-components.jquery-element`, `has-block-and-has-block-params` and `deprecated-run-loop-and-computed-dot-access`.

Nothing else is tested for this release. That includes every other Ember version (Ember 4 and later too), FastBoot, engines, and browsers other than Chrome.

## Installation
`ember install ember-remodal`

## Upgrading to 1.0.0+

If you are on Ember 2.3+, you can upgrade to ember-remodal 1.0.0+. To upgrade,
just upgrade ember-remodal to the newest less-than-1.0 version, make sure all
deprecations are gone, then you're all set to upgrade.

##### Buy Seth Brasile a Beer!
With the paypal donation link above^ :D

# Collaborating

PRs are welcome, please contribute! If you have a use-case which this does not suit,
please feel free to fix it and PR or open an issue.

## Installation

* `git clone` this repository
* Use Node 8.17.0 and Yarn Classic 1.22 to reproduce the historical dependency tree.
* `yarn install --frozen-lockfile --ignore-engines --ignore-optional`

## Running

* `ember server`
* Visit the 'dummy' app at http://localhost:4200

## Running Tests

* `yarn test`
* `ember test --server`
* `npm pack`, then `scripts/test-consumer.sh 2.18 ember-remodal-2.18.1.tgz`, to test the packed tarball in one of the apps from the Compatibility table. `floor` and `3.28` pick the other two (CI runs `3.28` on Node 24.21.0).

## Building

* `ember build`

For more information on using ember-cli, visit [http://www.ember-cli.com/](http://www.ember-cli.com/).
