//  TO DO:   stop default scroll-to behaviour when visiting a link
//  http://james.padolsey.com/javascript/special-scroll-events-for-jquery/
//
//  =================== depends on rh-status.js first ================
//
//  Red Hat Javascript -  Views Navigation
//
//
//  Finds the element with the id from the /# url hash and gives that element an "active" class
//  If the element was a section, removeClass any .active from immediate neighbours of the same parent only
//  Traverse the parent <section>s of the anchorID and ensure they are active and their neighbours are not
//
//  it _SHOULD_ also check if there is a <section with no neighbouring <section's set to active and make the first one active >
//  ==================================================================
//
//  Concept     //  Andy Fitzsimon <andy.fitzsimon@redhat.com>
//  Code        //  Tomas Sedovic <tsedovic@redhat.com>
//
//  ==================================================================
//
//  # Example usage :
//
//  <article>
//  <section></section>
//  </article>

function activateFirstSections($root) {
    var $sections = $root.children('section');
    if ($sections.length === 0) {
        return;
    }
    if ($sections.filter('.active').length > 0) {
        return;
    }
    var $first_section = $sections.first().addClass('active');
    activateFirstSections($first_section);
}

function activateElement($elem) {
    $elem.addClass('active');
    $elem.siblings().removeClass('active');
}

function activateTab(id) {
    var $current_section = $('#content');
    if (id) {
        var $elem = $('#' + id);
        activateElement($elem);
        activateElement($elem.parents('section'));

        if ($elem[0].tagName === 'SECTION' && $current_section.has($elem).length > 0) {
            $current_section = $elem;
        }
    }

    if ($current_section.find('section.active').length === 0) {
        activateFirstSections($current_section.children('article:first'));
    }

    $('section.active').removeClass('hidden');
    $('section').not('.active').addClass('hidden');
    ensureConsistency();
}

$(window).bind('hashchange', function() {
    if (window.location.hash === "") {
        // activate the default section
        activateTab();
    } else {
        //Grab what is after the # from the url bar and remove the #
        var anchorid = window.location.hash.replace("#", "");
        activateTab(anchorid);
    }
});

$(document).ready(function() {
    $(window).trigger('hashchange');
});
