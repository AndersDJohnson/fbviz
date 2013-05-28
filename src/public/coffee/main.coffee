

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


window.app = app = {}


cachedFBapi = do ->
  cache = window.localStorage.getItem('friendsgraph')
  unless cache?
    cache = {}
  else
    cache = JSON.parse(cache)

  return (url, callback) ->
    if cache[url]?
      callback(cache[url].data)
    else
      FB.api url, (response) ->
        cache[url] = {
          data: response,
          time: Date.now()
        }
        window.localStorage.setItem('friendsgraph', JSON.stringify(cache))
        callback(response)



makeNodeFromUser = (user) ->
  return {
    name: user.name
    id: user.id
    link: user.link
    group: 1
    strength: 1
  }

makeLink = (node1, node2) ->
  return {
    id: "#{node1.id}_#{node2.id}"
    source: node1
    target: node2
    strength: 1
  }




binder = ($el, getter, setter, throttle = 200) ->
  throttled = _.throttle(((value)->
    setter(value)
  ), throttle)
  $el.on 'change', (e) ->
    $this = $(this)
    value = parseFloat($this.val())
    throttled(value)
    app.update()

  $el.val(getter())


bindControls = do ->
  bound = false
  return ->
    return if bound
    bound = true

    force = app.force
    binder($('#gravity'), (-> force.gravity()), (val) -> force.gravity(val))
    binder($('#charge'), (-> force.charge()), ((val) -> force.charge(val)))
    #binder($('#distance'), (-> force.linkDistance()), ((val) -> force.linkDistance(val)))


#color = d3.scale.category20();

width = 500
height = 500
padding = 100

app.force = force = d3.layout.force()
  .linkDistance(((d) ->
    if d.strength? and not isNaN(d.strength)
      t = (width - padding) * 0.5
      s = d.strength
      w = t * (1 - s)
    else
      w = 1
    return w
  ))
  #.linkStrength((d) -> Math.pow(d.strength, 2) || 1 )
  .size([width, height])

app.zoom = zoom = d3.behavior.zoom()

zoom.on 'zoom', ->

  hidePopovers()

  scale = d3.event.scale
  [x, y] = d3.event.translate
  xs = x / scale
  ys = y / scale
  $svg = $(svg[0])
  value = 'scale(' + scale + ') translate(' + xs + 'px, ' + ys + 'px)'
  $svg.css('transform', value)

graph = d3.select("#graph")
graph
  .call(zoom)

svg = graph.append("svg")
  .attr("width", width)
  .attr("height", height)

app.dataMaps = dataMaps =
  links: d3.map()
  nodes: d3.map()

app.elements = elements =
  $nodes: []
  $links: []

getLinks = ->
  svg.selectAll(".link")

getNodes = ->
  svg.selectAll(".node")

getPopovers = ->
  $('.popover')

hidePopovers = ($except = []) ->
  # hide all popovers
  $popovers = $('.node')
  $popovers
    .not($except)
    .hoverPopover('hide')

forceOnTick = ->
  getLinks().attr("x1", (d) -> d.source.x; )
      .attr("y1", (d) -> d.source.y; )
      .attr("x2", (d) -> d.target.x; )
      .attr("y2", (d) -> d.target.y; );

  getNodes().attr("cx", (d) -> d.x; )
      .attr("cy", (d) -> d.y; )


force.on "tick", forceOnTick


getMutualFriends = (friend, callback) ->
  uri = '/me/mutualfriends/' + friend.id
  cachedFBapi uri, (response) ->
    callback(response)

app.templates = templates =
  me: _.template($('script#tooltip-me').html())
  friend: _.template($('script#tooltip-friend').html())

addPopover = (d, index, fixed) ->

  $this = $(this)

  friend = d

  if friend.isMe
    return
  else
    template = templates.friend

  data = {friend: friend}

  content = template(data)

  $this.hoverPopover({
    #showTime: 100
    #hideTime: 10000
    popover: {
      trigger: 'manual'
      container: 'body'
      html: true
      content: content
    }
    onInitTip: ($tip, popoverData) ->
      cachedFBapi '/' + friend.id + '?fields=id,name,link,picture', (response) ->

        $this.data('facebookData', response)

        link = response.link
        src = response.picture?.data?.url

        $content = $('<div>' + popoverData.options.content + '</div>')

        $content.find('.picture img')
          .attr('src', src)

        $content.find('.name a, .picture a')
          .attr('href', link)

        content = $content.html()
        popoverData.options.content = content
        $tip.find('.popover-content').html(content)
  })

  $this.on 'mouseenter', (e) ->
    if $this.hoverPopover('showing')
      hidePopovers($this)
    $this.hoverPopover('tryshow')
  
  $this.on 'mouseleave', (e) ->
    $this.hoverPopover('tryhide')


onClick = (d) ->
  $this = $(this)
  data = $this.data('facebookData')
  console.log data
  if data.link?
    window.open(data.link, '_blank')


app.update = update = ->
  force.stop()

  links = dataMaps.links.values()
  nodes = dataMaps.nodes.values()

  elements.$links = $links = getLinks().data(links, (d) -> d.id)
  
  $links.enter()
    .append('line')
    .attr('class', 'link')
    #.style('stroke-width', 1 )

  elements.$nodes = $nodes = getNodes().data(nodes, (d) -> d.id)

  $nodes.enter()
    .append('circle')
    .classed('node', true)
    .classed('me', (d) -> d.isMe)
    .attr("r", (d) -> (d.strength * 4) + 4)
    #.style("fill", (d) -> color(d.group))
    .each(addPopover)
    .on("click", onClick)
    #.on("mouseover", onMouseOver)
    #.on("mouseout", onMouseOut)
    #.call(force.drag);

  $nodes.append("title")
    .text((d) -> d.name );
  
  $links.exit().remove()
  $nodes.exit().remove()

  force
    .links(links)
    .nodes(nodes)
    .start()

  bindControls()


getOrSet = (map, key, value) ->
  if map.has(key)
    value = dataMaps.nodes.get(key)
  else
    map.set(key, value)
  return value

window.fbPostInit = ->
  #FB.api '/me', (response) ->
  #  alert('Your name is ' + response.name);

  options =
    cluster: false

  FB.login((response) ->

    cachedFBapi '/me/friends', (response) ->

      friends = response.data

      me = {
        name: 'Me'
        id: '-1000'
      }

      meNode = makeNodeFromUser(me)
      meNode.group = 0
      meNode.index = 0
      meNode.isMe = true

      meNode.mutualFriendCount = friends.length

      dataMaps.nodes.set(meNode.id, meNode)

      maxMutualFriendCount = 1

      async.each(friends, ((item, callback) ->

        friend = item

        fNode = makeNodeFromUser(friend)
        fNode = getOrSet(dataMaps.nodes, fNode.id, fNode)

        fLink = makeLink(meNode, fNode)

        getMutualFriends friend, (response) ->
          mutualFriends = response.data
          mutualFriendCount = mutualFriends.length

          fNode.mutualFriendCount = mutualFriendCount
          fLink.mutualFriendCount = mutualFriendCount

          if mutualFriendCount > maxMutualFriendCount
            maxMutualFriendCount = mutualFriendCount

          dataMaps.nodes.set(fNode.id, fNode)
          dataMaps.links.set(fLink.id, fLink)

          if options.cluster
            mutualFriends.forEach (mItem) ->
              mNode = makeNodeFromUser(mItem)

              return if fNode.id is mNode.id

              mNode = getOrSet(dataMaps.nodes, mNode.id, mNode)

              mLink = makeLink(fNode, mNode)
              mLink.strength = 0.5

              dataMaps.links.set(mLink.id, mLink)

          callback()

      ), (err) ->

        dataMaps.links.forEach (key, link) ->
          
          if link.mutualFriendCount?
            link.strength = link.mutualFriendCount / maxMutualFriendCount
            link.target.strength = link.strength

        update()
      )

  , {})

