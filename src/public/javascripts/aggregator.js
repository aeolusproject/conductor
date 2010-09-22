/* Aggregator JS */

$(document).ready(function () {
  $(window).scroll(positionFooter).resize(positionFooter).scroll();
  $("form").html5form();
});


function positionFooter() {
  var $footer = $('footer');
  if ($(document.body).height() < $(window).height()) {
    $footer.addClass('fixed');
  } else {
    $footer.removeClass('fixed');
  }
}
