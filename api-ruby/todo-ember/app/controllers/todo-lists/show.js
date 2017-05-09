import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    deleteList() {
      this.model.destroyRecord().then(this.transitionToRoute('todo-lists'));
    },
    createTodo(content) {
      let todo = this.store.createRecord('todo-item', {
        content: content,
        list: this.model
      });
      todo.save().then(this.model.get('todoItems').pushObject(todo));
    },
    completeTodo(item) {
      item.set('completed', !item.get('completed'));
      item.save();
    },
    deleteTodo(item) {
      item.destroyRecord();
    }
  }
});
