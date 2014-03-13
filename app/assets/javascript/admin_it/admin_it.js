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

var initPopups = function() {
  $('[data-toggle="popup"]')
    .mouseenter(function() {
      $(this).find('[data-toggle="popup-target"]').addClass('in');
    })
    .mouseleave(function() {
      $(this).find('[data-toggle="popup-target"]').removeClass('in');
    });
}

var initTabs = function() {
  $('[data-toggle="tab"]').on('shown.bs.tab', function(e) {
    $('[data-tab="' + $(e.relatedTarget).attr('href') + '"]').removeClass('in');
    $('[data-tab="' + $(e.target).attr('href') + '"]').addClass('in');
  });
  var active = $('.active > [data-toggle="tab"]');
  if (active) {
    active = active.first();
  }
  if (active) {
    active = active.attr('href');
    $('[data-tab="' + active + '"]').addClass('fade').addClass('in');
    $('[data-tab][data-tab!="' + active + '"]').addClass('fade').removeClass('in');
  }
}

var initLinks = function() {
  $('[data-link]').on('click', function(evt) {
    evt.preventDefault();
    location = $(this).data().link;
  });
}

var initFilters = function() {
  $('[data-filter-values]').each(function(idx, container) {
    $.each($(container).data().filterValues, function(i, v) {
      var html = "<a class='label label-success' href='#'>" + v.value + ' ' + "<span class='badge'>" + v.count + "</span></a>";
      $(container).append(html);
    });
  });
}

$(document).on('ready page:load', function() {
  initPartials();
  initTiles();
  initTabs();
  initPopups();
  initLinks();
//  initFilters();
});
