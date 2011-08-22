Conductor.Routers = Conductor.Routers || {}


Conductor.Routers.Pools = Backbone.Router.extend({
  routes: {
    '': 'index',
    'pools': 'index',
    'pools/:id': 'show',
  },

  index: function() {
  },

  show: function(id) {
    id = Conductor.idFromURLFragment(id);
    if(! _.isNumber(id)) return;

    var pool = new Conductor.Models.Pool({ id: id });
    var view = new Conductor.Views.PoolsShow({ model: pool });
    pool.bind('change', function() { view.render() });

    setInterval(function() { pool.fetch() }, Conductor.AJAX_REFRESH_INTERVAL);
  },
});


Conductor.Routers.Deployments = Backbone.Router.extend({
  routes: {
    'deployments': 'index',
    'deployments/:id': 'show',
  },

  index: function() {
  },

  show: function(id) {
    id = Conductor.idFromURLFragment(id);
    if(! _.isNumber(id)) return;

    var deployment = new Conductor.Models.Deployment({ id: id });
    var view = new Conductor.Views.DeploymentsShow({ model: deployment,
        collection: deployment.instances });
    deployment.bind('change', function() { view.render() });

    setInterval(function() {
      deployment.instances.fetch({success: function(instances) {
        deployment.change();
      } })
    }, Conductor.AJAX_REFRESH_INTERVAL);
  },
});
