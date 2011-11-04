// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


$.extend(Conductor, {
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
      $('#tab').html('<span class="loading_tabs"></span>');
      $.get(url, function(data) {
        $('#tab').html(data)
          .show();
      });

      Conductor.tabRemoveActiveClass();
      $(this).addClass('active');
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

  bind_pretty_toggle: function() {
    Conductor.nicelyHookAjaxClick($("#pretty_view"), function() {
      var link_element = this;
      $.get($(this).attr("href"), $(this).serialize(), function(result) {
        $('#content .toggle-view').html(result);
        $(link_element).addClass('active');
        $("#filter_view").removeClass('active');
      });
    });
    Conductor.nicelyHookAjaxClick($("#filter_view"), function() {
      var link_element = this;
      $.get($(this).attr("href"), $(this).serialize(), function(result) {
        $('#content .toggle-view').html(result);
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
    $.ajaxSetup({accepts: acceptsSettings, dataType: 'html'})
  },

  multiDestroyValidation: function() {
    $('#delete_button').live('click', function(e) {
      if ($(".checkbox_table input[@type=radio]:checked").length == 0) {
        alert('Please make a selection before clicking Delete button.');
        e.preventDefault();
      } else {
        if (!confirm("Are you sure you want to proceed with deletion?")) {
          e.preventDefault();
        }
      }
    });
  },

  multiRevokeValidation: function() {
    $('#revoke_button').live('click', function(e) {
      if ($(".checkbox_table input[@type=radio]:checked").length == 0) {
        alert('Please make a selection before clicking Revoke Access button.');
        e.preventDefault();
      } else {
        if (!confirm("Are you sure you want to proceed?")) {
          e.preventDefault();
        }
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


  prefixedPath: function(path) {
    var prefix = this.PATH_PREFIX;
    if(path.length === 0) return prefix;
    if(prefix.length === 0) return path;

    if(prefix[prefix.length-1] !== '/') prefix += '/';
    if(path[0] === '/') path = path.slice(1);

    return prefix + path;
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

  enhanceUserMenu: function() {
    var $userDropdown = $('#system a.user-dropdown');
    if($userDropdown.length == 0) return;

    var offset = $userDropdown.offset()
    offset.top = offset.top + 40;
    $('#user-menu').offset(offset)
    $userDropdown.click(function(ev) {
      ev.preventDefault();
      $('#user-menu').toggle();
    });
  },

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
  $.fn.buttonSensitivity = function () {
    var $checkboxes = $(this),
      $edit = $('.actionsidebar .edit'),
      $delete = $('.actionsidebar .delete'),
      $rename = $('.actionsidebar .rename'),
      $copy = $('.actionsidebar .copy'),
      $build = $('.actionsidebar .build');
    return $checkboxes.change(function () {
      var $checked = $checkboxes.filter(':checked');
      if ($checked.length === 0) {
        //disable the build, edit and delete action if there is none selected
        $build.addClass("disabled");
        $edit.addClass("disabled");
        $delete.addClass("disabled");
        $("input", $build).attr("disabled","disabled");
        $("input", $edit).attr("disabled","disabled");
        $("input", $delete).attr("disabled","disabled");
      } else if ($checked.length > 1) {
        //disable the build and edit if there is more than one
        $edit.addClass("disabled");
        $build.addClass("disabled");
        $delete.removeClass("disabled");
        $("input", $build).attr("disabled","disabled");
        $("input", $edit).attr("disabled","disabled");
        $("input", $delete).removeAttr("disabled");
      } else {
        $("input", $build).removeAttr("disabled");
        $("input", $edit).removeAttr("disabled");
        $("input", $delete).removeAttr("disabled");
        $build.removeClass("disabled");
        $edit.removeClass("disabled");
        $delete.removeClass("disabled");
      }
    });
  };
  $.fn.positionAncestor = function(selector) {
    var left = 0;
    var top = 0;
    this.each(function(index, element) {
        // check if current element has an ancestor matching a selector
        // and that ancestor is positioned
        var $ancestor = $(this).closest(selector);
        if ($ancestor.length && $ancestor.css("position") !== "static") {
            var $child = $(this);
            var childMarginEdgeLeft = $child.offset().left - parseInt($child.css("marginLeft"), 10);
            var childMarginEdgeTop = $child.offset().top - parseInt($child.css("marginTop"), 10);
            var ancestorPaddingEdgeLeft = $ancestor.offset().left + parseInt($ancestor.css("borderLeftWidth"), 10);
            var ancestorPaddingEdgeTop = $ancestor.offset().top + parseInt($ancestor.css("borderTopWidth"), 10);
            left = childMarginEdgeLeft - ancestorPaddingEdgeLeft;
            top = childMarginEdgeTop - ancestorPaddingEdgeTop;
            // we have found the ancestor and computed the position
            // stop iterating
            return false;
        }
    });
    return {
        left:    left,
        top:    top
    }
  };
})(jQuery);

/* Conductor JS */

$(document).ready(function () {
  Conductor.setAjaxHeadersForRails();

  $(window).scroll(Conductor.positionFooter).resize(Conductor.positionFooter).scroll();
  $("#notification").enhanceInteraction();
  Conductor.enhanceListView();
  Conductor.enhanceDetailsTabs();
  Conductor.bind_pretty_toggle();
  Conductor.multiDestroyValidation();
  Conductor.multiRevokeValidation();
  Conductor.closeNotification();
  Conductor.toggleCollapsible();
  Conductor.selectAllCheckboxes();
  Conductor.enhanceUserMenu();
  Conductor.tabAjaxRequest();
  Conductor.initializeBackbone();
});
