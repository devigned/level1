import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function () {
  this.route('todo-lists', {path: '/'}, function () {
    this.route('new');
    this.route('index', {path: '/'});
    this.route('edit', {path: '/:list_id/edit'});
    this.route('show', {path: '/:list_id'});
  });
});

export default Router;
