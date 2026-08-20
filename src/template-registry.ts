// Easily allow apps, which are not yet using strict mode templates, to consume your Glint types, by importing this file.
// Add all your components, helpers and modifiers to the template registry here, so apps don't have to do this.
// See https://typed-ember.gitbook.io/glint/environments/ember/authoring-addons

import type EmberRemodal from './components/ember-remodal.gts';
import type ErButton from './components/ember-remodal/er-button.gts';

export default interface Registry {
  EmberRemodal: typeof EmberRemodal;
  'ember-remodal': typeof EmberRemodal;
  'EmberRemodal::ErButton': typeof ErButton;
  'ember-remodal/er-button': typeof ErButton;
}
