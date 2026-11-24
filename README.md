# ember-remodal

[![Build Status](https://travis-ci.org/sethbrasile/ember-remodal.svg?branch=master)](https://travis-ci.org/sethbrasile/ember-remodal) [![npm version](https://badge.fury.io/js/ember-remodal.svg)](http://badge.fury.io/js/ember-remodal) [![Code Climate](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/gpa.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal) [![Dependencies](https://david-dm.org/sethbrasile/ember-remodal.svg)](https://david-dm.org/sethbrasile/ember-remodal) [![Test Coverage](https://codeclimate.com/github/sethbrasile/ember-remodal/badges/coverage.svg)](https://codeclimate.com/github/sethbrasile/ember-remodal/coverage) [![Ember Observer Score](http://emberobserver.com/badges/ember-remodal.svg)](http://emberobserver.com/addons/ember-remodal) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QDPUK852HN9U2)

#### [Interactive Demo/Documentation](http://sethbrasile.github.io/ember-remodal)

Under the hood, ember-remodal uses a jQuery-based modal library called
[remodal](http://vodkabears.github.io/remodal/).

## Compatibility

| ember-remodal |     Ember    |
| :-----------: | :----------: |
| less than 1.0 | 1.13+        |
| 1.0 or greater| 2.3+         |
| 1.2 or greater| adds fastboot|
| 2.0 or greater| adds engines |

The 2.18.1 candidate passed the full addon suite on Ember 2.12.2, 2.16.4
and 2.18.2. Separate apps exercised the packed addon's block trigger and
modal service on Ember 2.3.2 (jQuery 2.2.4), 2.18.2 and 3.28.12. On
Ember 3.28, the app needs `@ember/jquery` and the `jquery-integration`
optional feature enabled. Ember 3.28 emits deprecations for classic APIs
used by the addon and its dependencies.

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

## Building

* `ember build`

For more information on using ember-cli, visit [http://www.ember-cli.com/](http://www.ember-cli.com/).
