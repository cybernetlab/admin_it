// bootstrap 3 switch support:
// http://www.bootply.com/92189

(function($) {
  function parseOptions(element, options) {
    if (!$.isPlainObject(options)) options = {};
    var opts = $.extend({}, $.fn.switch.defaults, element.data(), options);
    if (opts.onValue == undefined) opts.onValue = true
    if (opts.offValue == undefined) opts.offValue = false
    return opts;
  };

  function toggle(element, options) {
    var buttons = element.find('.btn');

    if (element.find('.btn-primary').length > 0) buttons.toggleClass('btn-primary');
    if (element.find('.btn-danger').length > 0) buttons.toggleClass('btn-danger');
    if (element.find('.btn-success').length > 0) buttons.toggleClass('btn-success');
    if (element.find('.btn-info').length > 0) buttons.toggleClass('btn-info');

    buttons.toggleClass('btn-default').toggleClass('active');

    var value = element.data('value') == options.onValue ? options.offValue : options.onValue
    if (element.data('value') != undefined) element.data('value', value);
    var input = element.find('input')
    if (input.length > 0 && input.attr('value') != undefined) input.attr('value', value)
    if ($.isFunction(options.change)) options.change(value);
    element.trigger('change', [value]);
  };

  function set(element, options) {
    if (element.data('value') == undefined) element.data('value', options.offValue);
    if (options.value == undefined) options.value = options.offValue;
    if (element.data('value') == options.value) return;
    toggle(element, options);
  };

  $.fn.switch = function(action, options) {
    if ($.isPlainObject(action)) options = action;
    if (typeof action !== 'string') action = 'init';
    return this.each(function() {
      var $this = $(this);
      if (!$.isPlainObject(options)) options = { value: options }
      var opts = parseOptions($this, options);
      if (action === 'init') {
        if ($this.hasClass('switch-initialized')) return;
        $this.addClass('switch-initialized');
        if ($this.data('value') == undefined) $this.data('value', opts.offValue);
        if ($this.find('.btn-primary,.btn-danger,.btn-success,.btn-info').length == 0) {
          var btn = $this.find('.btn').removeClass('active btn-default');
          var off = $this.data('value') == opts.onValue ? btn.last() : btn.first();
          btn = $this.data('value') == opts.onValue ? btn.first() : btn.last();
          btn.addClass('btn-primary active');
          off.addClass('btn-default');
        }
        $this.on('click', function(evt) {
          evt.preventDefault()
          toggle($this, opts);
        });
      } else if (action === 'toggle') {
        toggle($this, opts);
      } else if (action === 'set' || action === 'val') {
        set($this, opts);
      } else if (action === 'on') {
        opts.value = opts.onValue;
        set($this, opts);
      } else if (action === 'off') {
        opts.value = opts.offValue;
        set($this, opts);
      }
    });
  };

  $.fn.switch.defaults = {};
})(jQuery);
