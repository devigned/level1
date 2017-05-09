import Ember from 'ember';

export default Ember.Component.extend({
  actions: {
    deleteList: function() {
      this.get('deleteList')(this.model);
    },
    createTodo: function() {
      this.get('createTodo')(this.get('newContent'));
      this.set('newContent', '');
    }
  }
});
