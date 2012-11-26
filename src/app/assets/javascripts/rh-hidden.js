// Things that we hide in our apps

$(document).ready(function() {
  // these are the static form controls including a submit button and a top link which stay fixed on the page.
  // with javascript enabled, we don't need them
  $('.no-js-controls').hide();

  // hiding areas referenced by javascript but not meant to be visible.
  $('.#global-tips').hide(); // this is an index of help that does not belong to any one section
});
