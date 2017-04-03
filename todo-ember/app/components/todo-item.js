import Ember from 'ember';

export default Ember.Component.extend({
  actions: {
    complete: function() {
      this.get('complete')(this.get('todo_item'));
    },
    delete: function() {
      this.get('delete')(this.get('todo_item'));
    }
  }
});
