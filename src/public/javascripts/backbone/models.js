Conductor.Models = Conductor.Models || {}


Conductor.Models.Pool = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/pools'),
});

Conductor.Models.Pools = Backbone.Collection.extend({
  model: Backbone.Model.Pool,
  url: Conductor.prefixedPath('/pools'),
});


Conductor.Models.Instance = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/instances'),
});

Conductor.Models.Instances = Backbone.Collection.extend({
  model: Backbone.Model.Instance,
  url: Conductor.prefixedPath('/instances'),
});

Conductor.Models.Deployment = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/deployments'),

  initialize: function() {
    this.instances = new Conductor.Models.Instances();
    this.instances.url = this.urlRoot + '/' + this.id + '/instances';
  },

});

Conductor.Models.Deployments = Backbone.Collection.extend({
  model: Backbone.Model.Deployment,
  url: Conductor.prefixedPath('/deployments'),
});
