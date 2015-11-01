export function initialize(container, app) {
  app.inject('controller', 'remodal', 'service:remodal');
  app.inject('route', 'remodal', 'service:remodal');
  app.inject('component', 'remodal', 'service:remodal');
}

export default {
  initialize,
  name: 'remodal'
};
