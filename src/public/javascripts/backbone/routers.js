Conductor.Routers = Conductor.Routers || {}


Conductor.Routers.Pools = Backbone.Router.extend({
  routes: {
    '': 'index',
    'pools:query': 'index',
    'pools/:id': 'show'
  },

  index: function() {
    setInterval(function() {
      var view = new Conductor.Views.PoolsIndex();

      view.collection = new Conductor.Models.Pools();
      view.collection.queryParams = view.queryParams();
      view.collection.bind('change', function() { view.render() });

      view.collection.fetch({ success: function() {
        view.collection.trigger('change');
      }})

    }, Conductor.AJAX_REFRESH_INTERVAL);
  },

  show: function(id) {
    id = Conductor.idFromURLFragment(id);
    if(! _.isNumber(id)) return;

    setInterval(function() {
      var pool = new Conductor.Models.Pool({ id: id });
      var view = new Conductor.Views.PoolsShow({ model: pool });
      pool.queryParams = view.queryParams();

      if(view.currentTab() !== 'deployments') return;

      pool.fetch({ success: function() { view.render(); } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  }
});


Conductor.Routers.Deployments = Backbone.Router.extend({
  routes: {
    'deployments': 'index',
    'deployments/:id': 'show'
  },

  index: function() {
  },

  show: function(id) {
    id = Conductor.idFromURLFragment(id);
    if(! _.isNumber(id)) return;

    setInterval(function() {
      var deployment = new Conductor.Models.Deployment({ id: id });
      var view = new Conductor.Views.DeploymentsShow({ model: deployment,
        collection: deployment.instances });

      if(view.currentTab() !== 'instances') return;

      deployment.bind('change', function() { view.render() });

      deployment.instances.fetch({success: function(instances) {
        deployment.change();
      } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  }
});

Conductor.Routers.Deployables = Backbone.Router.extend({
  routes: {
    'catalogs/:catalog_id/deployables/:id': 'show_nested',
    'deployables/:id': 'show'
  },

  show: function(id) {
    id = Conductor.idFromURLFragment(id);

    if(! _.isNumber(id) ) return;

    setInterval(function() {
      var deployable = new Conductor.Models.Deployable({ id: id });
      var view = new Conductor.Views.DeployablesShow({ model: deployable });
      deployable.fetch({ success: function() { view.render(); } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  },

  show_nested: function(catalog_id, id) {
    id = Conductor.idFromURLFragment(id);
    var catalogId = Conductor.idFromURLFragment(catalog_id);

    if(! _.isNumber(id) || ! _.isNumber(catalogId)) return;

    setInterval(function() {
      var deployable = new Conductor.Models.Deployable({ catalog_id: catalogId, id: id });
      var view = new Conductor.Views.DeployablesShow({ model: deployable });
      deployable.fetch({ success: function() { view.render(); } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  }
});

Conductor.Routers.Images = Backbone.Router.extend({
  routes: {
    'images/:id': 'show'
  },

  show: function(id) {
    id = Conductor.uuidFromURLFragment(id);
    if ( id == "edit_xml" || id == "overview" || id == "import" || id == "new" ) return;

    setInterval(function() {
      var image = new Conductor.Models.Image({ id: id });

      var view = new Conductor.Views.ImagesShow({ model: image });
      view.model.queryParams = view.queryParams();

      image.fetch({ success: function() { view.render(); } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  }
});
