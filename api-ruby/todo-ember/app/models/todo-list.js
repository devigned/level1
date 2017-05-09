import DS from 'ember-data';
const { attr, hasMany } = DS;

export default DS.Model.extend({
  title: attr('string'),
  description: attr('string'),

  todoItems: hasMany('todo-item')
});
