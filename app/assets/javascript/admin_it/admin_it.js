var prepareHeaders = function(hash) {
  result = {};
  var re = /^AdminIt-/;
  $.each(hash, function(key, value) {
    if (!re.test(key)) {
      key = 'AdminIt-' + key.charAt(0).toUpperCase() + key.slice(1);
    }
    result[key] = value;
  });
  return(result);
}

var initPartials = function() {
  $('[data-toggle="partial"][data-target]').on('click', function(evt) {
    data = $(this).data();
    href = data.remote || $(this).attr('href');
    if (href) {
      var options = {
        dataType: 'html',
        headers: prepareHeaders(data.params)
      }
      $.ajax(href).success(function(html) {
        $(data.target).innerHtml(html);
      });
      evt.preventDefault();
    }
  });
}

var initTiles = function() {
  $('.admin-tile')
    .mouseenter(function() {
      $(this).find('.admin-tile-actions').addClass('in');
    })
    .mouseleave(function() {
      $(this).find('.admin-tile-actions').removeClass('in');
    });
}

$(document).on('ready page:load', function() {
  initPartials();
  initTiles();
});
