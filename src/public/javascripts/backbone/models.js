Conductor.Models = Conductor.Models || {}


Conductor.Models.Pool = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/pools'),
});


Conductor.Models.Instance = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/instances'),
});

Conductor.Models.Instances = Backbone.Collection.extend({
  model: Backbone.Model.Instance,
});

Conductor.Models.Deployment = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/deployments'),

  initialize: function() {
    this.instances = new Conductor.Models.Instances();
    this.instances.url = this.urlRoot + '/' + this.id + '/instances';
  },

});
