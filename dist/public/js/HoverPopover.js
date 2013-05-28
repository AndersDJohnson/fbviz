(function(root, name, deps, factory) {
  if (typeof define === 'function' && define.amd) {
    return define(deps, factory);
  } else {
    return root[name] = factory.apply(root, deps.map(function(dep) {
      return root[dep];
    }));
  }
})(this, 'HoverPopover', ['jQuery'], function($) {
  var HoverPopover;

  HoverPopover = (function() {
    function HoverPopover(el, options) {
      if (options == null) {
        options = {};
      }
      this.el = el;
      this.$el = $(el);
      this.options = $.extend({}, {
        showTime: 250,
        hideTime: 1000
      }, options);
      this._showing = false;
      this._initTipped = false;
      this.init();
    }

    HoverPopover.prototype.init = function() {
      var _base, _ref;

      if ((_ref = (_base = this.options).popover) == null) {
        _base.popover = {};
      }
      return this.$el.popover(this.options.popover);
    };

    HoverPopover.prototype._initTip = function() {
      var $tip, me, popoverData;

      me = this;
      popoverData = this.$el.data('popover');
      $tip = popoverData != null ? popoverData.tip() : void 0;
      $tip.on('mouseenter', function(e) {
        return me.$el.doTimeout('hoverPopover.try');
      });
      $tip.on('mouseleave', function(e) {
        return me.$el.doTimeout('hoverPopover.try', me.options.hideTime, $.proxy(me.hide, me));
      });
      if (typeof this.options.onInitTip === 'function') {
        this.options.onInitTip($tip, popoverData);
      }
      return this._initTipped = true;
    };

    HoverPopover.prototype.showing = function() {
      return this._showing;
    };

    HoverPopover.prototype.show = function() {
      this.cancel();
      if (!this._showing) {
        this.$el.popover('show');
        this._showing = true;
      }
      if (!this._initTipped) {
        return this._initTip();
      }
    };

    HoverPopover.prototype.hide = function() {
      this.cancel();
      if (this._showing) {
        this.$el.popover('hide');
        return this._showing = false;
      }
    };

    HoverPopover.prototype.cancel = function() {
      return this.$el.doTimeout('hoverPopover.try');
    };

    HoverPopover.prototype.tryhide = function() {
      return this.$el.doTimeout('hoverPopover.try', this.options.hideTime, $.proxy(this.hide, this));
    };

    HoverPopover.prototype.tryshow = function() {
      return this.$el.doTimeout('hoverPopover.try', this.options.showTime, $.proxy(this.show, this));
    };

    return HoverPopover;

  })();
  $.fn.hoverPopover = function(option) {
    return this.each(function() {
      var $this, data, options;

      $this = $(this);
      data = $this.data('hoverPopover');
      if (typeof option === 'object') {
        options = option;
      }
      if (data == null) {
        data = new HoverPopover(this, options);
        $this.data('hoverPopover', data);
      }
      if (typeof option === 'string') {
        data[option]();
      }
    });
  };
  return HoverPopover;
});
