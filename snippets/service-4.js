openMyAwesomeModal() {
  this.get('remodal').open('my-awesome-modal', {
    title: 'A Modal',
    text: 'Text in a modal'
  });
},

openMySecondModal() {
  const modal = this.get('remodal.my-second-modal');

  modal.setProperties({
    title: 'A Modal',
    text: 'Text in a modal'
  });

  modal.set('text', 'Other text in a modal');

  modal.open();
}
