import Ember from 'ember';

const {
  assert,
  Service
} = Ember;

export default Service.extend({
  modal: null,

  open(name='ember-remodal', opts=null) {
    let modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      return modal.open();
    } else {
      this._modalNotSetError(name);
    }
  },

  close(name='ember-remodal') {
    let modal = this.get(name);

    if (modal) {
      return modal.close();
    } else {
      this._modalNotSetError(name);
    }
  },

  _modalNotSetError(name) {
    assert(`The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`);
  }
});
