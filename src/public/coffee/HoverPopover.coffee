((root, name, deps, factory) ->
  if typeof define is 'function' && define.amd
    define(deps, factory)
  else
    root[name] = factory.apply(root, deps.map((dep) -> root[dep]))
)(this, 'HoverPopover', ['jQuery'], ($) ->

  class HoverPopover
    constructor: (el, options = {}) ->
      @el = el
      @$el = $(el)
      @options = $.extend {}, {
        showTime: 250
        hideTime: 1000
      }, options
      @_showing = false
      @_initTipped = false

      @init()

    init: ->
      @options.popover ?= {}
      @$el.popover(@options.popover)

    _initTip: ->
      me = @
      popoverData = @$el.data('popover')
      $tip = popoverData?.tip()
      $tip.on 'mouseenter', (e) ->
        me.$el.doTimeout 'hoverPopover.try'
      $tip.on 'mouseleave', (e) ->
        me.$el.doTimeout 'hoverPopover.try', me.options.hideTime, $.proxy(me.hide, me)
      @options.onInitTip($tip, popoverData) if typeof @options.onInitTip is 'function'
      @_initTipped = true

    showing: ->
      return @_showing

    show: ->
      @cancel()
      unless @_showing
        @$el.popover('show')
        @_showing = true
      unless @_initTipped
        @_initTip()

    hide: ->
      @cancel()
      if @_showing
        @$el.popover('hide')
        @_showing = false

    cancel: ->
      @$el.doTimeout 'hoverPopover.try'

    tryhide: ->
      @$el.doTimeout 'hoverPopover.try', @options.hideTime, $.proxy(@hide, @)

    tryshow: ->
      @$el.doTimeout 'hoverPopover.try', @options.showTime, $.proxy(@show, @)


  
  $.fn.hoverPopover = (option) ->
    return this.each ->
      $this = $(this)
      data = $this.data('hoverPopover')
      options = option if typeof option is 'object'
      unless data?
        data = new HoverPopover(this, options)
        $this.data('hoverPopover', data)
      if typeof option is 'string'
        data[option]()
      return



  return HoverPopover
)
