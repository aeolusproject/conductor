Conductor.Views = Conductor.Views || {}


Conductor.Views.PoolsIndex = Backbone.View.extend({
  el: '#content',

  currentView: function() {
    if ($('form.filterable-data').length > 0) {
      return 'table'
    }
    else if ($('#pools-list').length > 0) {
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
    else {
      return '';
    }
  },

  template: function() {
    if (this.currentView() == 'table') {
      switch(this.currentTab()) {
        case 'pools': return $('#poolRowTemplate');
        case 'deployments': return $('#deploymentRowTemplate');
        case 'instances': return $('#instanceRowTemplate');
      }
    }
    else if (this.currentView() == 'pretty') {
      return $('#deploymentCardTemplate');
    }
  },

  queryParams: function() {
    var paramsToInclude = [this.currentTab() + '_preset_filter', this.currentTab() + '_search', 'page'];
    var result = Conductor.extractQueryParams(paramsToInclude);

    result['details_tab'] = this.currentTab();

    // If there is no URL param for the preset filter, we still need to merge in the preset filter
    var filter = this.currentTab() + '_preset_filter';
    if(result[filter] == undefined) {
      var filter_selector = '#' + filter + ':enabled';
      if($(filter_selector).val() != undefined) {
        result[filter] = $(filter_selector).val();
      }
    };

    return result;
  },

  render: function() {
    var $template = this.template();

    if (this.currentView() == 'table') {
      var $table = this.$('table.checkbox_table > tbody');
      if($table.length === 0 || $template.length === 0) return;
      var checkboxes = Conductor.saveCheckboxes('td :checkbox', $table);

      var rowsHtml = '';
      $.each(this.collection.toJSON(), function(index, value) {
        rowsHtml += Mustache.to_html($template.html(), value);
      });

      $table.empty().append(rowsHtml);
      Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);
      $table.find('tr:even').addClass('nostripe');
      $table.find('tr:odd').addClass('stripe');
    }
    else if (this.currentView() == 'pretty') {
      var cardsPerRow = 5;

      var self = this;
      var headerTemplate = $('#poolPrettyListHeaderTemplate');
      $.each(this.collection.models, function(index, value) {
        var poolId = value.attributes.id;
        var $rows = self.$('#deployment-arrays-' + poolId).empty();
        var poolDeployments = value.attributes.user_deployments;
        for(var i = 0; i < poolDeployments.length; i += cardsPerRow) {
          var deploymentCardsHtml = '';
          $.each(poolDeployments.slice(i, i + cardsPerRow), function(deploymentIndex, deployment) {
            deploymentCardsHtml += Mustache.to_html($template.html(), deployment);
          });

          var $row = self.make('ul', {'class': 'deployment-array small'}, deploymentCardsHtml);
          $rows.append($row);
        }

        var $header = $('header.pool-header-' + poolId);
        $header.html(Mustache.to_html(headerTemplate.html(), value.toJSON()));
      });
    }

    var scoreboardTemplate = $('#poolScoreboardIndexTemplate');
    var $scoreboard = $('div.scoreboard');
    $scoreboard.html(Mustache.to_html(scoreboardTemplate.html(), this.collection.userInfo.toJSON()));
  }
});

Conductor.Views.PoolsShow = Backbone.View.extend({
  el: '#content',
  currentView: function() {
    if ($('form.filterable-data').length > 0) {
      return 'table'
    }
    else if ($('ul.deployable-cards').length > 0) {
      return 'pretty'
    }
  },

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

  template: function() {
    if (this.currentView() == 'table') {
      return $('#deploymentRowTemplate');
    }
    else if (this.currentView() == 'pretty') {
      return $('#deploymentCardTemplate');
    }
  },

  queryParams: function() {
    var paramsToInclude = ['deployments_preset_filter', 'deployments_search', 'page'];
    var result = Conductor.extractQueryParams(paramsToInclude);

    // If there is no URL param for the preset filter, we still need to merge in the preset filter
    var filter = 'deployments_preset_filter';
    if(result[filter] == undefined) {
      var filter_selector = '#deployments_preset_filter:enabled';
      if($(filter_selector).val() != undefined) {
        result[filter] = $(filter_selector).val();
      }
    };

    return result;
  },

  render: function() {
    this.$('h1.pools').text(this.model.get('name'));

    var $template = this.template();
    if($template.length === 0) return;

    var $table = this.$('table.checkbox_table > tbody');
    var deployments = this.model.get('deployments');
    if(this.currentView() == 'table') {
      var checkboxes = Conductor.saveCheckboxes('td :checkbox', $table);

      var deplyomentRowsHtml = '';
      $.each(deployments, function(deploymentIndex, deployment) {
        deplyomentRowsHtml += Mustache.to_html($template.html(), deployment);
      });

      $table.empty().append(deplyomentRowsHtml);
      Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);

      $('tr:odd').addClass('stripe');
      $('tr:even').addClass('nostripe');

      Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);
    }
    else {
      var $cards = this.$('ul.deployable-cards').empty()
      var cardsPerRow = 5;
      for(var i = 0; i < deployments.length; i += cardsPerRow) {
        var deploymentCardHtml = '';
        $.each(deployments.slice(i, i + cardsPerRow), function(deploymentIndex, deployment) {
          deploymentCardHtml += Mustache.to_html($template.html(), deployment);
        });

        var $row = this.make('ul',
          {'class': 'deployment-array large'},
          deploymentCardHtml);
        $cards.append($row);
      }
    }
  }
});

Conductor.Views.DeployablesShow = Backbone.View.extend({

  el: '#content',

  render: function() {
    var $template = this.$('#imageStatusTemplate');
    if($template.length === 0) return;

    var $builds = this.$('ul#providers-list');
    if($builds.length === 0) return;
    $builds.empty();

    var imageStatus = this.model.get('image_status');
    var imageStatusHtml = '';
    $.each(imageStatus, function(imageStatusIndex, imageStatusForAccount) {
      imageStatusHtml += Mustache.to_html($template.html(), imageStatusForAccount);
    });

    $builds.html(imageStatusHtml);

    // get values of all build results
    var build_results_values = _.flatten(_.values(this.model.get("image_status")));
    var enable_launch_button = _.any(build_results_values, function(build_results){
      return build_results.build_status === "pushed";
    });

    // toggle "disabled" class
    $("#launch_deployment_button").toggleClass("disabled", !enable_launch_button);
    // create or remove href attribute with value from data-path
    if(enable_launch_button) {
      $("#launch_deployment_button").attr("href", $("#launch_deployment_button").data("path"));
    }
    else{
      $("#launch_deployment_button").removeAttr("href");
    }
  }
});

Conductor.Views.DeploymentsShow = Backbone.View.extend({

  el: '#content',

  currentTab: function() {
    if($('#details_instances.active').length > 0) {
      return 'instances';
    }
  },

  queryParams: function() {
    var paramsToInclude = ['instances_preset_filter', 'instances_search', 'page'];
    var result = Conductor.extractQueryParams(paramsToInclude);

    // If there is no URL param for the preset filter, we still need to merge in the preset filter
    var filter = 'instances_preset_filter';
    if(result[filter] == undefined) {
      var filter_selector = '#instances_preset_filter:enabled';
      if($(filter_selector).val() != undefined) {
        result[filter] = $(filter_selector).val();
      }
    };

    return result;
  },

  render: function() {
    $template = $('#instanceCardTemplate');
    if($template.length === 0) return;

    var $instances = this.$('ul.instances-array');
    if($instances.length === 0) {
      $instances = this.$('table.checkbox_table > tbody');
    }
    if($instances.length === 0) return;

    $instances.empty();

    var instanceCardsHtml = '';
    $.each(this.collection.toJSON(), function(instanceIndex, instance) {
      instanceCardsHtml += Mustache.to_html($template.html(), instance);
    });
    $instances.html(instanceCardsHtml);

    var $alerts = this.$('#deployment-alerts');
    var alertsVisible = $alerts.find('.collapsible').length == 0 || $alerts.find('.collapsible').is(":visible")
    var failedInstances = _.compact(_.map(this.collection.models, function(model) {
      if(model.get('failed')) {
        return model.toJSON();
      }
      else {
        return null;
      }
    }));

    // Render alerts
    $alerts.empty();
    if(failedInstances.length == 0) return;

    var $deploymentAlertTemplate = $('#deploymentAlertTemplate');
    $alerts.html(Mustache.to_html($deploymentAlertTemplate.html(), {
      'failed_instance_exists' : failedInstances.length > 0,
      'failed_instances_count' : failedInstances.length,
      'failed_instances' : failedInstances
    }));

    // Add callback to Toggle link
    $alerts.find('a.collapse').click(function(e) {
      e.preventDefault();
      $(this).parents('.collapse_entity').find('.collapsible').slideToggle(80);
    });

    // Restore toggle state on alerts table
    if(!alertsVisible) {
      $alerts.find('.collapsible').hide();
    }
  }

});

Conductor.Views.ImagesIndex = Backbone.View.extend({
  el: '#content',

  queryParams: function() {
    var paramsToInclude = ['page'];
    var result = Conductor.extractQueryParams(paramsToInclude);

    return result;
  },

  render: function() {
    var $template = $('#imageRowTemplate');

    var $table = this.$('table.checkbox_table > tbody');
    if($table.length === 0 || $template.length === 0) return;

    var checkboxes = Conductor.saveCheckboxes('td :checkbox', $table);

    var rowsHtml = '';
    $.each(this.collection.toJSON(), function(index, value) {
      rowsHtml += Mustache.to_html($template.html(), value);
    });

    $table.empty().append(rowsHtml);
    Conductor.restoreCheckboxes(checkboxes, 'td :checkbox', $table);
    $table.find('tr:even').addClass('nostripe');
    $table.find('tr:odd').addClass('stripe');
  }
});

Conductor.Views.ImagesShow = Backbone.View.extend({
  el: '#content',

  queryParams: function() {
    var paramsToInclude = ['build'];
    var result = Conductor.extractQueryParams(paramsToInclude);

    return result;
  },

  render: function() {
    var $builds = this.$('ul.image_builds');
    if($builds.length === 0) return;

    $template = $('#imageStatusTemplate');
    if($template.length === 0) return;

    $builds.html(Mustache.to_html($template.html(), this.model.toJSON()));

    // Enable/Disable Push All button
    var $buttonTemplate = $('#pushAllButtonTemplate');
    var $pushAllBtn = $('#push-all-btn');

    if (this.model.get('push_all_enabled')) {
      $pushAllBtn.html(Mustache.to_html($buttonTemplate.html(), this.model.toJSON()));
    }
    else {
      $pushAllBtn.empty();
    }
  }
});
