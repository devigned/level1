import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    updateList() {
      this.model.save().then(this.transitionToRoute('todo-lists'));
    }
  }
});
