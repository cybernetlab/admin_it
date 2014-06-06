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
  $form = $('[data-sign-url]');
  $form.fileupload({
    url: $form.attr('action'),
    autoUpload: true,
    dataType: 'xml',
    add: function(evt, data) {
      $.ajax({
        url: $form.data('signUrl') + '/',
        type: 'GET',
        dataType: 'json',
        data: { doc: { title: data.files[0].name } },
        async: false,
        success: function(data) {
          // Now that we have our data, we update the form so it contains all
          // the needed data to sign the request
          $form.find('input[name=key]').val(data.key)
          $form.find('input[name=policy]').val(data.policy)
          $form.find('input[name=signature]').val(data.signature)
        }
      });
      data.submit();
    }
  });
})
}

$(document).on('ready page:load', function() {
  initPartials();
  // initDialogs();
  initTiles();
  initTabs();
  initPopups();
  initLinks();
  initImageUploads();
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
             })
});
