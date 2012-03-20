Conductor.Models = Conductor.Models || {}


Conductor.Models.Pool = Backbone.Model.extend({
  initialize: function() {
    this.deployments = new Conductor.Models.Deployments().filter(function(attributes) {
      return attributes.pool.id == this.id;
    });
  },
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/pools/'  + this.id);
    return Conductor.parameterizedPath(path, this.queryParams);
  }
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
  urlRoot: Conductor.prefixedPath('/instances')
});

Conductor.Models.Instances = Backbone.Collection.extend({
  model: Backbone.Model.Instance,
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/instances');
    return Conductor.parameterizedPath(path, this.queryParams);
  }
});

Conductor.Models.Deployable = Backbone.Model.extend({
  initialize: function(options) {
    this.catalog_id = options['catalog_id']
  },

  url: function() {
    if( this.catalog_id == null ){
      return Conductor.prefixedPath('/deployables/' + this.id);
    }
    else{
      return Conductor.prefixedPath('/catalogs/' + this.catalog_id + '/deployables/' + this.id);
    }
  }
});

Conductor.Models.Deployment = Backbone.Model.extend({
  urlRoot: Conductor.prefixedPath('/deployments'),

  initialize: function() {
    this.instances = new Conductor.Models.Instances();
    this.instances.url = this.urlRoot + '/' + this.id + '/instances';
  }

});

Conductor.Models.Deployments = Backbone.Collection.extend({
  model: Backbone.Model.Deployment,
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/deployments');
    return Conductor.parameterizedPath(path, this.queryParams);
  }
});

Conductor.Models.Image = Backbone.Model.extend({
  queryParams: {},
  url: function() {
    var path = Conductor.prefixedPath('/images/' + this.id);
    return Conductor.parameterizedPath(path, this.queryParams);
  }
});
