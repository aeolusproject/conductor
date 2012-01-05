Conductor.Models = Conductor.Models || {}


Conductor.Models.Pool = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/pools'),
});

Conductor.Models.Pools = Backbone.Collection.extend({
  model: Backbone.Model.Pool,
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/pools');
    return Conductor.parameterizedPath(path, this.queryParams);
  }
});

Conductor.Models.Instance = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/instances'),
});

Conductor.Models.Instances = Backbone.Collection.extend({
  model: Backbone.Model.Instance,
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/instances');
    return Conductor.parameterizedPath(path, this.queryParams);
  }
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
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/deployments');
    return Conductor.parameterizedPath(path, this.queryParams);
  }
});
