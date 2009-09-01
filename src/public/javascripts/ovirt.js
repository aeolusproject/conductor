// ovirt-specific javascript functions are defined here

// helper functions for dialogs and action links


// returns an array of selected values for flexigrid checkboxes
function get_selected_checkboxes(formid)
{
  var selected_array = new Array();
  var selected_index = 0;
  var selected = $('#'+formid+' .grid_checkbox:checkbox:checked');
  selected.each(function(){
    selected_array.push(this.value);
  })
  return selected_array;
}


// make sure that at least one item is selected to continue
function validate_selected(selected_array, name)
{
  if (selected_array.length == 0) {
    $.jGrowl("Please select at least one " + name + "  to continue");
    return false;
  } else {
    return true;
  }
}

function getAverage(val) {
    if (isNaN(val)) return 0;
    //FIXME: currently using a magic number of 5 which should be replaced
    //with comething more meaningful.
    return (val/5 < 1) ? ((val/5) * 100) : 100;
}

function add_hosts(url)
{
    hosts= get_selected_checkboxes("addhosts_grid_form");
    if (validate_selected(hosts, "host")) {
      $.post(url,
             { resource_ids: hosts.toString() },
              function(data,status){
                $(document).trigger('close.facebox');
	        grid = $("#hosts_grid");
                if (grid.size()>0 && grid != null) {
                  grid.flexReload();
                } else {
		  $tabs.tabs("load",$tabs.data('selected.tabs'));
                }
		if (data.alert) {
		  $.jGrowl(data.alert);
                }
               }, 'json');
    }
}
function add_storage(url)
{
    storage= get_selected_checkboxes("addstorage_grid_form");
    if (validate_selected(storage, "storage pool")) {
      $.post(url,
             { resource_ids: storage.toString() },
              function(data,status){
                if (data.success) {
                  $(document).trigger('close.facebox');
                  if ($("#storage_tree").size() > 0) {
                    $('ul.ovirt-tree').trigger('STORAGE_VOLUME', [response.storage]);
                  } else {
                    $tabs.tabs("load",$tabs.data('selected.tabs'));
                  }
                }
		if (data.alert) {
		  $.jGrowl(data.alert);
                }
               }, 'json');
    }
}
function add_hosts_to_smart_pool(url)
{
    hosts= get_selected_checkboxes("add_smart_hosts_grid_form");
    if (validate_selected(hosts, "host")) {
      $.post(url,
             { resource_ids: hosts.toString() },
              function(data,status){
                $(document).trigger('close.facebox');
	        grid = $("#smart_hosts_grid");
                if (grid.size()>0 && grid != null) {
                  grid.flexReload();
                } else {
		  $tabs.tabs("load",$tabs.data('selected.tabs'));
                }
		if (data.alert) {
		  $.jGrowl(data.alert);
                }
               }, 'json');
    }
}
function add_storage_to_smart_pool(url)
{
    storage= get_selected_checkboxes("add_smart_storage_grid_form");
    if (validate_selected(storage, "storage pool")) {
      $.post(url,
             { resource_ids: storage.toString() },
              function(data,status){
                $(document).trigger('close.facebox');
	        grid = $("#smart_storage_grid");
                if (grid.size()>0 && grid != null) {
                  grid.flexReload();
                } else {
		  $tabs.tabs("load",$tabs.data('selected.tabs'));
                }
		if (data.alert) {
		  $.jGrowl(data.alert);
                }
               }, 'json');
    }
}
function add_vms_to_current_smart_pool(url)
{
    vms= get_selected_checkboxes("add_smart_vms_grid_form");
    if (validate_selected(vms, "vm")) {
      $.post(url,
             { resource_ids: vms.toString() },
              function(data,status){
                $(document).trigger('close.facebox');
	        grid = $("#smart_vms_grid");
                if (grid.size()>0 && grid != null) {
                  grid.flexReload();
                } else {
		  $tabs.tabs("load",$tabs.data('selected.tabs'));
                }
		if (data.alert) {
		  $.jGrowl(data.alert);
                }
               }, 'json');
    }
}
// deal with ajax form response, filling in validation messages where required.
function ajax_validation(response, status)
{
  $(".fieldWithErrors").removeClass("fieldWithErrors");
  $("div.errorExplanation").remove();
  if (!response.success && response.errors ) {
    for(i=0; i<response.errors.length; i++) {
      var element = $("div.form_field:has(#"+response.object + "_" + response.errors[i][0]+")");
      if (element) {
        element.addClass("fieldWithErrors");
        for(j=0; j<response.errors[i][1].length; j++) {
          element.append('<div class="errorExplanation">'+response.errors[i][1][j]+'</div>');
        }
      }
    }
  }
  if (response.alert) {
    $.jGrowl(response.alert);
  }
}

// callback actions for dialog submissions
function afterHwPool(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      // this is for reloading the host/storage grid when
      // adding hosts/storage to a new HW pool
      if (response.resource_type) {
        grid = $('#' + response.resource_type + '_grid');
        if (grid.size()>0 && grid != null) {
          grid.flexReload();
        } else {
          $tabs.tabs("load",$tabs.data('selected.tabs'));
        }
      }

      //FIXME: point all these refs at a widget so we dont need the functions in here
      processTree();

      if ((response.resource_type == 'hosts' ? get_selected_hosts() : get_selected_storage()).indexOf($('#'+response.resource_type+'_selection_id').html()) != -1){
	  empty_summary(response.resource_type +'_selection', (response.resource_type == 'hosts' ? 'Host' : 'Storage Pool'));
      }
      // do we have HW pools grid?
      //$("#vmpools_grid").flexReload()
    }
}
function afterVmPool(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      grid = $("#vmpools_grid");
      if (grid.size()>0 && grid != null) {
        grid.flexReload();
      } else {
        $tabs.tabs("load",$tabs.data('selected.tabs'));
      }
      processTree();
    }
}
function afterSmartPool(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      processTree();
    }
}
function afterStoragePool(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      if ($("#storage_tree").size() > 0) {
        $('ul.ovirt-tree').trigger('STORAGE_VOLUME', [response.new_pool]);
      } else {
        $tabs.tabs("load",$tabs.data('selected.tabs'));
      }
    }
}
function afterPermission(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      grid = $("#users_grid");
      if (grid.size()>0 && grid!= null) {
        grid.flexReload();
      } else {
        $tabs.tabs("load",$tabs.data('selected.tabs'));
      }
    }
}
function afterVm(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      grid = $("#vms_grid");
      if (grid.size()>0 && grid != null) {
        grid.flexReload();
      } else {
        $tabs.tabs("load",$tabs.data('selected.tabs'));
      }
    }
}

//selection detail refresh
function refresh_summary(element_id, url, obj_id){
  $('#'+element_id+'').load(url, { id: obj_id})
}
function refresh_summary_static(element_id, content){
    $('#'+element_id+'').html(content)
}
function empty_summary(element_id, label){
    refresh_summary_static(element_id, '<div class="selection_left"> \
    <div>Select a '+label+' above.</div> \
  </div>')
}


function get_selected_storage()
{
    return get_selected_checkboxes("storage_tree_form");
}
function validate_storage_for_move()
{
    if (validate_selected(get_selected_storage(), 'storage pool')) {
        $('#move_link_hidden').click();
    }
}
function validate_storage_for_remove()
{
    if (validate_selected(get_selected_storage(), 'storage pool')) {
        $('#remove_link_hidden').click();
    }
}
function delete_or_remove_storage()
{
    var selected = $('#remove_storage_selection :radio:checked');
    if (selected[0].value == "remove") {
        remove_storage();
    } else if (selected[0].value == "delete") {
        delete_storage();
    }
    $(document).trigger('close.facebox');
}
function delete_pool(delete_url, id)
{
  $(document).trigger('close.facebox');

  if (delete_url==='') {
    $.jGrowl("Invalid Pool Type");
    return;
  }
  $.post(delete_url,
         {id: id},
          function(data,status){
            //no more flex reload?
            processTree();
            if (data.alert) {
              $.jGrowl(data.alert);
            }
           }, 'json');
}


function get_selected_networks()
{
    return get_selected_checkboxes("networks_grid_form");
}

function afterNetwork(response, status){
    ajax_validation(response, status);
    if (response.success) {
      $(document).trigger('close.facebox');
      grid = $("#networks_grid");
      if (grid.size()>0 && grid != null) {
        grid.flexReload();
      } else {
        $tabs.tabs("load",$tabs.data('selected.tabs'));
      }
    }
}

function handleTabsAndContent(data) {
  $('#side-toolbar').html($(data).find('div.toolbar'));
  $('#tabs-and-content-container').html($(data).not('div#side-toolbar'));
}

var VmCreator = {
  checkedBoxesFromTree : [],
  buildCheckboxList: function(id) {
      var rawList = $('#'+ id + ' :checkbox:checked').parent('div');
      if (rawList.length >0) {
          rawList.each(function(i) {
            VmCreator.checkedBoxesFromTree.push(rawList.get(i).id);
          });
      } else {
          VmCreator.checkedBoxesFromTree.splice(0);
      }
  },
  clickCheckboxes: function() {
      $.each(VmCreator.checkedBoxesFromTree, function(n, curBox){
          $('#' + curBox).children(':checkbox').click();
      });
      VmCreator.checkedBoxesFromTree = [];
  },
  recreateTree: function(o){
      $('#storage_volumes_tree').tree({
        content: o.content,
        template: "storage_volumes_template",
        selectedNodes: o.selectedNodes,
        clickHandler: VmCreator.goToCreateStorageHandler,
        channel: 'STORAGE_VOLUME',
        refresh: VmCreator.returnToVmForm
      });
  },
  goToCreateStorageHandler: function goToCreateStorageHandler(e,elem){
    if ($(e.target).is('img') && $(e.target).parent().is('div')){
        //remove the temp form in case there is one hanging around for some reason
        $('temp_create_vm_form').remove();
        VmCreator.buildCheckboxList(elem.element.get(0).id);
        var storedOptions = $('#storage_volumes_tree').data('tree').options;
        // copy/rename form
        $('#window').clone(true).attr({style: 'display:none', id: 'temp_window'}).appendTo('body');
        $('#temp_window #vm_form').attr({id: 'temp_create_vm_form'});
        // continue standard calls to go to next step (create storage)
        $('#window').fadeOut('fast');
        $("#window").empty().load($(e.target).siblings('a').attr('href'));
        $('#window').fadeIn('fast');
        // empty tree
        $('#temp_create_vm_form #storage_volumes_tree').empty();
        // reinitialize tree so it has data and is subscribed
        VmCreator.recreateTree(storedOptions);
    }
  },
  returnToVmForm: function returnToVmForm(e,elem) {
      //The item has now been added to the tree, now copy it into a facebox
      var storedOptions = $('#storage_volumes_tree').data('tree').options;
      $('#window').fadeOut('fast');
      $('#window').remove();
      $('#temp_window').clone(true).attr({style: 'display:block', id: 'window'})
        .appendTo('td.body > div.content').end().remove();
      $('#window #temp_create_vm_form').attr({id: 'vm_form'});
      $('#window').fadeIn('fast');
      VmCreator.recreateTree(storedOptions);
      VmCreator.clickCheckboxes();
  }
}

function get_server_from_url()
{
   var regexS = "https.*"
   var regex  = new RegExp(regexS);
   var results = regex.exec( window.location.href );
   var start = 8;
   if(results == null){
     start = 7;
   }
   var end = window.location.href.indexOf('/', 8) - start;
   return window.location.href.substr(start, end);
}
