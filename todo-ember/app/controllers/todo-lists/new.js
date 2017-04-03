import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    createList() {
      let title = this.get('title');
      let description = this.get('description');
      if (!title.trim()) { return; }

      let list = this.store.createRecord('todo-list', {
        title: title,
        description: description
      });

      list.save().then(this.transitionToRoute('todo-lists'));
    }
  }
});
