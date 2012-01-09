Conductor.Views = Conductor.Views || {}


Conductor.Views.PoolsIndex = Backbone.View.extend({
  el: '#content',

  currentView: function() {
    if ($('form.filterable-data').length > 0) {
      return 'table'
    }
    else if ($('.deployment-array').length > 0) {
      return 'pretty'
    }
  },

  currentTab: function() {
    if($('#details_pools.active').length > 0) {
      return 'pools';
    }
    else if ($('#details_deployments.active').length > 0) {
      return 'deployments';
    }
    else if ($('#details_instances.active').length > 0) {
      return 'instances';
    }
  },

  template: function() {
    if (this.currentView() == 'table') {
      switch(this.currentTab()) {
        case 'pools': return $('#poolTemplate');
        case 'deployments': return $('#deploymentTemplate');
        case 'instances': return $('#instanceTemplate');
      }
    }
    else if (this.currentView() == 'pretty') {
      return $('#deploymentPrettyTemplate');
    }
  },

  urlParams: function() {
    var paramsData = window.location.search.slice(1).split('&');
    var params = {};
    $.each(paramsData, function(index, value){
      var eqSign = value.search('=');
      if(eqSign != -1) {
        params[value.substring(0, eqSign)] = value.substring(eqSign+1);
      }
    });

    return params;
  },

  queryParams: function() {
    var result = {};
    var paramsToInclude = [this.currentTab() + '_preset_filter', this.currentTab() + '_search'];
    var urlParams = this.urlParams();

    $.each(paramsToInclude, function(paramIndex, paramValue) {
      for (var urlParamName in urlParams) {
        if (urlParamName == paramValue) {
          result[urlParamName] = urlParams[urlParamName];
          break;
        }
      };
    });

    return result;
  },

  render: function() {
    var $template = this.template();

    if (this.currentView() == 'table') {
      var $table = this.$('table.checkbox_table > tbody');
      if($table.length === 0 || $template.length === 0) return;
      var checkboxes = Conductor.saveCheckboxes('td :checkbox', $table);
      $table.empty().append($template.tmpl(this.collection.toJSON()))
      Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);
      $table.find('tr:even').addClass('nostripe');
      $table.find('tr:odd').addClass('stripe');
    }
    else if (this.currentView() == 'pretty') {
      var cardsPerRow = 5;
      var poolIds = this.collection.models.map(function(model) {
        return model.attributes.pool.id;
      });
      $.unique(poolIds);
      var deployments = this.collection.models.map(function(model) {
        return model.attributes;
      });

      for(var j = 0; j < poolIds.length; j++) {
        var poolId = poolIds[j];
        var $rows = this.$('#deployment-arrays-' + poolId).empty();
        var poolDeployments = deployments.filter(function(attributes) {
          return attributes.pool.id == poolId;
        });
        for(var i = 0; i < poolDeployments.length; i += cardsPerRow) {
          var $row = this.make('ul',
            {class: 'deployment-array small'},
            $template.tmpl(poolDeployments.slice(i, i + cardsPerRow)));
          $rows.append($row);
        }
      }
    }
  },
});

Conductor.Views.PoolsShow = Backbone.View.extend({
  el: '#content',

  currentTab: function() {
    if($('#details_deployments.active').length > 0) {
      return 'deployments';
    }
    else if ($('#details_properties.active').length > 0) {
      return 'properties';
    }
    else if ($('#details_images.active').length > 0) {
      return 'images';
    }
  },

  render: function() {
    this.$('h1.pools').text(this.model.get('name') + ' Pool');

    var $template = $('#deploymentTemplate');
    if($template.length === 0) return;

    var $table = this.$('table.checkbox_table > tbody');
    var deployments = this.model.get('deployments');
    if($table.length !== 0) {
      var checkboxes = Conductor.saveCheckboxes('td :checkbox', $table);
      $table.empty().append($template.tmpl(deployments))
      Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);
    }
    else {
      var $cards = this.$('ul.deployable-cards').empty()
      var cardsPerRow = 5;
      for(var i = 0; i < deployments.length; i += cardsPerRow) {
        var $row = this.make('ul',
          {class: 'deployment-array large'},
          $template.tmpl(deployments.slice(i, i + cardsPerRow)));
        $cards.append($row);
      }
    }
  },
});


Conductor.Views.DeploymentsShow = Backbone.View.extend({

  el: '#content',

  currentTab: function() {
    if($('#details_instances.active').length > 0) {
      return 'instances';
    }
  },

  render: function() {
    var $instances = this.$('ul.instances-array');
    if($instances.length === 0) {
      $instances = this.$('table.checkbox_table > tbody');
    }
    if($instances.length === 0) return;

    $instances.empty();
    $('#instanceTemplate').tmpl(this.collection.toJSON()).appendTo($instances);
  },

});
