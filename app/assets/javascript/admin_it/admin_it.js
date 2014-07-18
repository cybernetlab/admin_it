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
    var data = $(this).data();
    var href = data.remote || $(this).attr('href');
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

var initDialogs = function() {
/*  $('[data-toggle="dialog"]').on('click', function(evt) {
    var data = $(this).data();
    evt.preventDefault();
    if (data.target) {
      $(data.target).modal('show');
    } else if ($(this).attr('href'))
  });*/
}

var initTiles = function() {
  $('.admin-tile')
    .mouseenter(function() {
      $(this).find('.admin-tile-actions').addClass('in');
    })
    .mouseleave(function() {
      $(this).find('.admin-tile-actions').removeClass('in');
    });
  $('.admin-tile-actions').each(function() {
    var $this = $(this);
    var $parent = $this.parent();
    var pos = $parent.position();
    $this.css({
      position: 'absolute',
      top: pos.top + 10,
      left: pos.left + $parent.outerWidth() - $this.outerWidth() - 10
    });
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
    $('form input[type="hidden"][name="section"]').val($(this).attr('href').substr(1));
    initTiles();
  });
  var active = $('.active > [data-toggle="tab"]');
  if (active.length > 0) {
    active = active.first().attr('href');
    $('[data-tab="' + active + '"]').addClass('fade').addClass('in');
    $('[data-tab][data-tab!="' + active + '"]').addClass('fade').removeClass('in');
    $('form input[type="hidden"][name="section"]').val(active.substr(1));
  }
}

var initLinks = function() {
  $('[data-link]').on('click', function(evt) {
    evt.preventDefault();
    location = $(this).data().link;
  });
}

var initImageUploads = function() {
  $('[data-toggle="file-upload"]').fileUpload({
    success: function(el, response) {
      $(el.data('image')).attr('src', response.small_url);
    }
  });
}

var initSelects = function() {
  $('.select2:not(.select2-container)').select2({
    minimumResultsForSearch: -1 // disable search
  });
}

var initGeoPickers = function() {
  $('[data-geo-picker]').each(function() {
    var $this = $(this);
    var $input = $($this.data('geoPicker'));
    var arr = $input.val().split(',');
    var lon = parseFloat(arr[0]);
    var lat = parseFloat(arr[1]);
    $this.geoLocationPicker({
      gMapZoom: 13,
      gMapMapTypeId: google.maps.MapTypeId.ROADMAP,
      gMapMarkerTitle: 'Выбирите местоположение',
      showPickerEvent: 'click',
      defaultLat: lat || 55.751607, // center
      defaultLng: lon || 37.617159, // of Moscow
      defaultLocationCallback: function(lat, lon) {
        $input.val(lon + ', ' + lat);
        $input.parent().find('.x').text(lon);
        $input.parent().find('.y').text(lat);
      }
    });
  });
}

var initControls = function() {
  initImageUploads();
  initSelects();
  initGeoPickers();
  initTiles();
}

$(document).on('ready page:load', function() {
  initPartials();
  // initDialogs();
  initTabs();
  initPopups();
  initLinks();
  initControls();
  // allow dialog content reloading
  $('.modal').on('hidden.bs.modal', function() { $(this).removeData(); })
             .on('loaded.bs.modal', function() {
               var active = $('.active > [data-toggle="tab"]');
               if (active.length > 0) {
                 active = active.first().attr('href');
                 $('form input[type="hidden"][name="section"]').val(active.substr(1));
               }
               var $form = $(this).find('form');
               if ($form.length > 0) {
                 $(this).find('button[type="submit"]').on('click', function(evt) {
                   evt.preventDefault();
                   $form.submit();
                 });
               }
               initControls();
             })
});
