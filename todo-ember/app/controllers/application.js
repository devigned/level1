import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    deleteList() {
      this.model.delete().then(this.transitionToRoute('todo-lists'));
    }
  }
});
