// ==================================================================

// # Red Hat Javascript -  Status broadcasting

// Inspects elements for a specified list of classes then propagates
// those classes to any other elements linked via href= or referenced
// with a classname matching the elements id

// ==================================================================
// ## Authors

// __Concept__
// Andy Fitzsimon <andy.fitzsimon@redhat.com>

// __Initial Code__
// Tomas Sedovic <tsedovic@redhat.com>

// __Finishing Code__
// Ryan Lerch <rlerch@redhat.com>

// ==================================================================

// # Example usage :

//     <div id="coffee" class="alert"> . . . <div>
//     <a href="#coffee"> how's your coffee doing</a>
//     <span> I would also like to know </span>

// Becomes :

//     <div id="coffee" class="alert"> . . . <div>
//     <a href="#coffee" class="alert"> how's your coffee doing</a>
//     <span class="alert"> I would also like to know </span>

// Both the a and the span get class="alert" added



function copyClass($section, cls) {
    var id = $section.attr('id');
    if (!id) {
        return;
    }
    var has_class = $section.hasClass(cls);
    $('a[href="#' + id + '"]').toggleClass(cls, has_class);
    $('.' + id).toggleClass(cls, has_class);
}

function ensureConsistency() {

    // We specify which classes are okay to clone
    // (classes that will never be used as an ID)
    var classes = ['disabled', 'disabling', 'active', 'alert', 'online'];
    var copyAllClasses = function() {
        var $section = $(this);
        jQuery.each(classes, function(ix, cls) {
            copyClass($section, cls);
        });
    };

    // We set which elements to listen to the ID/Status of
    $('section').each(copyAllClasses);
    // how can we do this without specifying all elements?
    $('div').each(copyAllClasses);
    $('a').each(copyAllClasses);
    $('span').each(copyAllClasses);
    $('td').each(copyAllClasses);
    $('table').each(copyAllClasses);
}

ensureConsistency(); // now we pull the trigger
