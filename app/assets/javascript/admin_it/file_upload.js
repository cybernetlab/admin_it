(function($) {
  function parseOptions(element, options) {
    var opts = $.extend({}, $.fn.fileUpload.defaults, element.data(), options);
    opts.target = $(opts.target).first();
    if (opts.target.length == 0) opts.target = null;
    return opts;
  };

  function getCss(target) {
    var pos = (target) ? target.position() : { top: 0, left: 0 };
    if (target) {
      pos.top -= parseInt(target.css('border-top-width'));
      pos.left -= parseInt(target.css('border-left-width'));
      pos.width = target.outerWidth();
      pos.height = target.outerHeight();
    }
    return pos;
  };

  function completed(opts, success, response) {
    // replace file input element to preven file uploading while form submitting
    var input = opts.input
      .clone()
      .on('change', function() { addFile.apply(this, [opts]); });
    opts.input.remove();
    opts.input = input.appendTo(opts.wrapper);
    if (!success) {
      alert('Ошибка загрузки файла');
      return;
    }
    if ($.isFunction(opts.success)) opts.success(input, response);
  };

  function addFile(opts) {
    if (opts.started) {
      alert('В данный момент загружается другой файл. ' +
            'Дождитесь окончания загрузки');
      return;
    }
    opts.started = true;
    var xhr = new XMLHttpRequest();
    var uploaded = false;

    if (xhr.upload) {
      xhr.upload.addEventListener("load", function(e) { uploaded = true; }, false);
    } else {
      uploaded = true;
    }

    xhr.onreadystatechange = function() {
      if (this.readyState == 4) {
        opts.started = false;
        if (this.status < 400) {
          completed(
            opts,
            uploaded,
            (uploaded) ? $.parseJSON(this.responseText) : null
          );
        } else {
          completed(opts, false, null);
        }
      }
    };

    var el = opts.input.get(0);
    var filename = el.files[0].name;
    var method = (opts.method || opts.uploadMethod || 'POST').toUpperCase();
    xhr.open(method, opts.url || opts.uploadUrl);
    xhr.setRequestHeader('Accept', 'application/json');

    // W3C (IE9, Chrome, Safari, Firefox 4+)
    var formData = new FormData();
    formData.append(opts.fieldName || 'file', el.files[0], filename);
    if (opts.token) {
      formData.append(opts.tokenName || 'token', opts.token);
    }
    xhr.send(formData);
  };

  function init(element, opts) {
    if (!opts.target) return;
    if (element.parent().hasClass('file-upload-wrapper')) return;
    opts.wrapper = $('<div class="file-upload-wrapper"></div>').append(element);
    // small timeout needed to take effect in DOM model
    setTimeout(function() {
      opts.css = getCss(opts.target);
      opts.wrapper
        .css(opts.css)
        .appendTo(opts.target);
      opts.input = element.on('change', function() { addFile.apply(this, [opts]); });
    }, 100);
    return opts;
  };

  $.fn.fileUpload = function(action, options) {
    if ($.isPlainObject(action)) options = action;
    if (typeof action !== 'string') action = 'init';
    return this.each(function() {
      var $this = $(this);
      var opts = parseOptions($this, options);
      if (action === 'init') {
        init($this, opts);
      }
    });
  };

  $.fn.fileUpload.defaults = {
  }
})(jQuery);
