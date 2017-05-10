import DS from 'ember-data';
import Ember from 'ember';
import config from '../config/environment';

export default DS.JSONAPIAdapter.extend({
  host: config.APP.ApiHost,
  namespace: 'api/v1',
  pathForType: function(type) {
    return Ember.String.pluralize(Ember.String.underscore(type));
  }
});
