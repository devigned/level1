import DS from 'ember-data';
const { attr, belongsTo } = DS;

export default DS.Model.extend({
  title: attr('string'),
  content: attr('string'),
  completed: attr('boolean'),
  order: attr('number'),
  url: attr('string'),

  todoList: belongsTo('todo-list')
});
