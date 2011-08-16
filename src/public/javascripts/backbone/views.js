Conductor.Views = Conductor.Views || {}


Conductor.Views.PoolsShow = Backbone.View.extend({
  el: '#content',

  render: function() {
    this.$('h1.pools').text(this.model.get('name') + ' Pool');
    return this;
  },
});


Conductor.Views.DeploymentsShow = Backbone.View.extend({

  el: '#content',

  render: function() {
    var $instances = this.$('ul.instances_list');
    if($instances.length === 0) {
      $instances = this.$('table.checkbox_table > tbody');
    }
    if($instances.length === 0) return;

    var checked_instances = Conductor.saveCheckboxes('td :checkbox', $instances);
    $instances.empty();
    $('#instanceTemplate').tmpl(this.collection.toJSON()).appendTo($instances);
    Conductor.restoreCheckboxes(checked_instances, 'td :checkbox', $instances);
    $instances.find('tr:even').addClass('nostripe');
    $instances.find('tr:odd').addClass('stripe');
  },

});
