// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


$.extend(Conductor, {
  tabIsClickedResetFilters: false,

  positionFooter: function () {
    var $footer = $('footer');
    if ($(document.body).height() < $(window).height()) {
      $footer.addClass('fixed');
    } else {
      $footer.removeClass('fixed');
    }
  },

  tabAjaxRequest: function () {
    $('#tab-container-1-nav a').live("click",function(e) {
      if (e.which==2||e.metaKey||e.ctrlKey||e.shiftKey) return true;

      e.preventDefault();
      var url = $(this).attr('href');
      $('#tab').html('<div class="loading_tabs"></div>');
      $.get(url, function(data) {
        $('#tab').html(data).show();
      })
      .error(function(data) {
        // If our session has timed out, redirect to the login page:
        if(data.status == 401) {
          window.location = Conductor.PATH_PREFIX + "login";
        } else {
          $('#tab').html(data.responseText).show();
        }
      });

      Conductor.tabRemoveActiveClass();
      $(this).addClass('active');

      var visible = $(this).data('pretty_view_toggle') == 'enabled';
      $('.button-group > .view-toggle').each(function(index, $element) {
        $($element).toggle(visible);
      });
    });
  },

  setupPrettyFilterURL: function (filter_url,pretty_url) {
    $(".section-controls span.view-toggle a#pretty_view").attr('href', pretty_url);
    $(".section-controls span.view-toggle a#filter_view").attr('href', filter_url);
  },

  tabRemoveActiveClass: function () {
    $('#tab-container-1-nav a').each(function(index) {
        $(this).removeClass('active');
    });
  },

  enhanceListView: function () {
    $('#list-view table tbody a').live("click",function(e) {
      if (e.which==2||e.metaKey||e.ctrlKey||e.shiftKey) return true;

      e.preventDefault();
      var url = $(this).attr('href') + '?details_pane=true';
      $.get(url, function(data) {
        $('#list-view').removeClass('full').addClass('part');
        $('#details-view').html(data)
          .show();
        Conductor.enhanceDetailsTabs();
      });
    });
  },

  enhanceDetailsTabs: function () {
    $('#details-selected').hide();
    $('#details-view').tabs('destroy').tabs();
  },

  /* This hooks the specified callback to the jQuery element's click action in
     a non-evil manner: it will not hijack middle-click, ctrl+click or
     shift+click actions because these already have a defined behaviour in
     most browsers. */
  nicelyHookAjaxClick: function($element, callback) {
    $element.live('click', function(ev) {
      if(ev.which == 2 || ev.metaKey || ev.ctrlKey || ev.shiftKey) return true;

      ev.preventDefault();
      callback.call($(this), ev);
    });
  },

  bindPrettyToggle: function() {
    Conductor.nicelyHookAjaxClick($("#pretty_view"), function() {
      var link_element = this;
      $('#content .toggle-view').html('<div class="loading_tabs"></div>');
      $.get($(this).attr("href"), $(this).serialize(), function(result) {
        $('.toggle-view').html(result);
        $(link_element).addClass('active');
        $("#filter_view").removeClass('active');
      });
    });
    Conductor.nicelyHookAjaxClick($("#filter_view"), function() {
      var link_element = this;
      $('#content .toggle-view').html('<div class="loading_tabs"></div>');
      $.get($(this).attr("href"), $(this).serialize(), function(result) {
        $('.toggle-view').html(result);
        $('#details-selected').hide();
        $('#details-view').tabs();
        $(link_element).addClass('active');
        $("#pretty_view").removeClass('active');
      });
    });
  },

  setAjaxHeadersForRails: function() {
    /* In the Rails' respond_to block, there is no distinction between
       the regular browser request and jQuery AJAX.

       This sets the accept headers for the ajax requests in a way that will
       match format.js in Rails. Vanilla browser requests still match format.html.
    */
    var acceptsSettings = $.extend({}, $.ajaxSettings.accepts)
    acceptsSettings.html = "text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"
    $.ajaxSetup({accepts: acceptsSettings, dataType: 'html', cache: false})
  },

  multiActionValidation: function() {
    $('#delete_button, #revoke_button, #stop_button, #stop_selected_instances, #reboot_selected_instances').live('click', function(e) {

      var $checkbox_table = $(this).closest("form.filterable-data").find("table.checkbox_table");
      var confirm_message = $checkbox_table.data('confirm');
      var none_selected_message = $checkbox_table.data('none_selected');

      //if needed, override default messages with messages defined explicitly on button
      if ($(this).data('confirm')){ confirm_message = $(this).data('confirm'); }
      if ($(this).data('none_selected')){ none_selected_message = $(this).data('none_selected'); }

      if ($checkbox_table.find("input[@type=radio]:checked").length == 0) {
        alert(none_selected_message);
        e.preventDefault();
      }
      else if (!confirm(confirm_message)) {
        e.preventDefault();
      }
    });
  },

  closeNotification: function() {
    $('.control').click(function(e) {
      e.preventDefault();
      $('#flash-hud').slideUp(100).fadeOut(100);
    });
  },

  toggleCollapsible: function() {
    $('.collapse').click(function(e) {
      e.preventDefault();
      $(this).parents('.collapse_entity').find('.collapsible').slideToggle(80);
    });
  },

  selectAllCheckboxes: function() {
    $('.select_all').live('click', function(source) {
      checkboxes = $(this).parents('table').find("tbody input[type=checkbox]");
      for(var i in checkboxes){
        checkboxes[i].checked = source.target.checked;
      }
    });
  },

  urlParams: function() {
    if(Conductor.tabIsClickedResetFilters == false){
      var paramsData = window.location.search.slice(1).split('&');
    } else {
      var paramsData = [];
    }

    var params = {};
    $.each(paramsData, function(index, value){
      var eqSign = value.search('=');
      if(eqSign != -1) {
        params[value.substring(0, eqSign)] = value.substring(eqSign+1);
      }
    });

    return params;
  },

  extractQueryParams: function(paramsToInclude) {
    var result = {};
    var urlParams = Conductor.urlParams();

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

  prefixedPath: function(path) {
    var prefix = this.PATH_PREFIX;
    if(path.length === 0) return prefix;
    if(prefix.length === 0) return path;

    if(prefix[prefix.length-1] !== '/') prefix += '/';
    if(path[0] === '/') path = path.slice(1);

    return prefix + path;
  },

  parameterizedPath: function(url, queryParams) {
    var result = url;

    if (!$.isEmptyObject(queryParams)) {
      var params = $.map(queryParams, function(value, key) {
        return key + '=' + value;
      });
      result += '?' + params.join('&');
    }

    return result;
  },

  AJAX_REFRESH_INTERVAL: 30 * 1000,

  initializeBackbone: function() {
    for(router in Conductor.Routers) {
      if(Conductor.Routers.hasOwnProperty(router) &&
            router[0] === router.toUpperCase()[0]) {
        new Conductor.Routers[router]();
      }
    }
    Backbone.history.start({pushState: true, root: Conductor.PATH_PREFIX})
  },

  idFromURLFragment: function(urlFragment) {
    return parseInt(urlFragment.split('?')[0]);
  },

  uuidFromURLFragment: function(urlFragment) {
    return urlFragment.split('?')[0];
  },

  saveCheckboxes: function(checkboxSelector, $scope) {
    if(!$scope) $scope = $;

    var result = [];
    $scope.find(checkboxSelector + ':checked').each(function() {
      result.push(this.value)
    });
    return result;
  },

  restoreCheckboxes: function(checkedIds, checkboxSelector, $scope) {
    if(!$scope) $scope = $;

    $.each(checkedIds, function(index, id) {
      var $checkbox = $scope.find(checkboxSelector + '[value="' + id + '"]');
      $checkbox.prop('checked', true);
    });
  },

  clickOnEnterKeypress: function($textField, $button) {
    $textField.live('keypress', function(e) {
      if((e.keyCode || e.which) == 13) {
        e.preventDefault();
        $button.click();
      }
    });
  },

  fetchAjaxDescription: function(selector_box, description_field, base_url) {
    selector_box.live("change", function(e) {
      var realm_id = $(e.target).val();
      if(realm_id != "") {
        $.getJSON(base_url + realm_id, function(json) {
          description_field.html(json.description);
        });
      } else {
        description_field.html('');
      }
    });
  }

});

/* custom methods */
(function($){
  /* add close button to a div */
  $.fn.enhanceInteraction = function() {
    var $block = $(this).hide().fadeIn(400);
    return $block.each(function () {
      var $message = $("div",this);
      if ($message.length > 0) {
        $("ul",$message).addClass('padforicon')
          .append('<a class="close">')
          .find('a')
          .click(function () {
            $block.hide(200);
          });
        }
    });
  };
})(jQuery);

/* Conductor JS */

$(document).ready(function () {
  Conductor.setAjaxHeadersForRails();

  $(window).scroll(Conductor.positionFooter).resize(Conductor.positionFooter).scroll();
  $("#notification").enhanceInteraction();
  Conductor.enhanceListView();
  Conductor.enhanceDetailsTabs();
  Conductor.bindPrettyToggle();
  Conductor.multiActionValidation();
  Conductor.closeNotification();
  Conductor.toggleCollapsible();
  Conductor.selectAllCheckboxes();
  Conductor.tabAjaxRequest();
  Conductor.initializeBackbone();
});
