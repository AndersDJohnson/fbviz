var addPopover, app, bindControls, binder, cachedFBapi, dataMaps, elements, force, forceOnTick, getLinks, getMutualFriends, getNodes, getOrSet, getPopovers, graph, height, hidePopovers, makeLink, makeNodeFromUser, onClick, padding, svg, templates, update, width, zoom;

window.app = app = {};

cachedFBapi = (function() {
  var cache;

  cache = window.localStorage.getItem('friendsgraph');
  if (cache == null) {
    cache = {};
  } else {
    cache = JSON.parse(cache);
  }
  return function(url, callback) {
    if (cache[url] != null) {
      return callback(cache[url].data);
    } else {
      return FB.api(url, function(response) {
        cache[url] = {
          data: response,
          time: Date.now()
        };
        window.localStorage.setItem('friendsgraph', JSON.stringify(cache));
        return callback(response);
      });
    }
  };
})();

makeNodeFromUser = function(user) {
  return {
    name: user.name,
    id: user.id,
    link: user.link,
    group: 1,
    strength: 1
  };
};

makeLink = function(node1, node2) {
  return {
    id: "" + node1.id + "_" + node2.id,
    source: node1,
    target: node2,
    strength: 1
  };
};

binder = function($el, getter, setter, throttle) {
  var throttled;

  if (throttle == null) {
    throttle = 200;
  }
  throttled = _.throttle((function(value) {
    return setter(value);
  }), throttle);
  $el.on('change', function(e) {
    var $this, value;

    $this = $(this);
    value = parseFloat($this.val());
    throttled(value);
    return app.update();
  });
  return $el.val(getter());
};

bindControls = (function() {
  var bound;

  bound = false;
  return function() {
    var force;

    if (bound) {
      return;
    }
    bound = true;
    force = app.force;
    binder($('#gravity'), (function() {
      return force.gravity();
    }), function(val) {
      return force.gravity(val);
    });
    return binder($('#charge'), (function() {
      return force.charge();
    }), (function(val) {
      return force.charge(val);
    }));
  };
})();

width = 500;

height = 500;

padding = 100;

app.force = force = d3.layout.force().linkDistance((function(d) {
  var s, t, w;

  if ((d.strength != null) && !isNaN(d.strength)) {
    t = (width - padding) * 0.5;
    s = d.strength;
    w = t * (1 - s);
  } else {
    w = 1;
  }
  return w;
})).size([width, height]);

app.zoom = zoom = d3.behavior.zoom();

zoom.on('zoom', function() {
  var $svg, scale, value, x, xs, y, ys, _ref;

  hidePopovers();
  scale = d3.event.scale;
  _ref = d3.event.translate, x = _ref[0], y = _ref[1];
  xs = x / scale;
  ys = y / scale;
  $svg = $(svg[0]);
  value = 'scale(' + scale + ') translate(' + xs + 'px, ' + ys + 'px)';
  return $svg.css('transform', value);
});

graph = d3.select("#graph");

graph.call(zoom);

svg = graph.append("svg").attr("width", width).attr("height", height);

app.dataMaps = dataMaps = {
  links: d3.map(),
  nodes: d3.map()
};

app.elements = elements = {
  $nodes: [],
  $links: []
};

getLinks = function() {
  return svg.selectAll(".link");
};

getNodes = function() {
  return svg.selectAll(".node");
};

getPopovers = function() {
  return $('.popover');
};

hidePopovers = function($except) {
  var $popovers;

  if ($except == null) {
    $except = [];
  }
  $popovers = $('.node');
  return $popovers.not($except).hoverPopover('hide');
};

forceOnTick = function() {
  getLinks().attr("x1", function(d) {
    return d.source.x;
  }).attr("y1", function(d) {
    return d.source.y;
  }).attr("x2", function(d) {
    return d.target.x;
  }).attr("y2", function(d) {
    return d.target.y;
  });
  return getNodes().attr("cx", function(d) {
    return d.x;
  }).attr("cy", function(d) {
    return d.y;
  });
};

force.on("tick", forceOnTick);

getMutualFriends = function(friend, callback) {
  var uri;

  uri = '/me/mutualfriends/' + friend.id;
  return cachedFBapi(uri, function(response) {
    return callback(response);
  });
};

app.templates = templates = {
  me: _.template($('script#tooltip-me').html()),
  friend: _.template($('script#tooltip-friend').html())
};

addPopover = function(d, index, fixed) {
  var $this, content, data, friend, template;

  $this = $(this);
  friend = d;
  if (friend.isMe) {
    return;
  } else {
    template = templates.friend;
  }
  data = {
    friend: friend
  };
  content = template(data);
  $this.hoverPopover({
    popover: {
      trigger: 'manual',
      container: 'body',
      html: true,
      content: content
    },
    onInitTip: function($tip, popoverData) {
      return cachedFBapi('/' + friend.id + '?fields=id,name,link,picture', function(response) {
        var $content, link, src, _ref, _ref1;

        $this.data('facebookData', response);
        link = response.link;
        src = (_ref = response.picture) != null ? (_ref1 = _ref.data) != null ? _ref1.url : void 0 : void 0;
        $content = $('<div>' + popoverData.options.content + '</div>');
        $content.find('.picture img').attr('src', src);
        $content.find('.name a, .picture a').attr('href', link);
        content = $content.html();
        popoverData.options.content = content;
        return $tip.find('.popover-content').html(content);
      });
    }
  });
  $this.on('mouseenter', function(e) {
    if ($this.hoverPopover('showing')) {
      hidePopovers($this);
    }
    return $this.hoverPopover('tryshow');
  });
  return $this.on('mouseleave', function(e) {
    return $this.hoverPopover('tryhide');
  });
};

onClick = function(d) {
  var $this, data;

  $this = $(this);
  data = $this.data('facebookData');
  console.log(data);
  if (data.link != null) {
    return window.open(data.link, '_blank');
  }
};

app.update = update = function() {
  var $links, $nodes, links, nodes;

  force.stop();
  links = dataMaps.links.values();
  nodes = dataMaps.nodes.values();
  elements.$links = $links = getLinks().data(links, function(d) {
    return d.id;
  });
  $links.enter().append('line').attr('class', 'link');
  elements.$nodes = $nodes = getNodes().data(nodes, function(d) {
    return d.id;
  });
  $nodes.enter().append('circle').classed('node', true).classed('me', function(d) {
    return d.isMe;
  }).attr("r", function(d) {
    return (d.strength * 4) + 4;
  }).each(addPopover).on("click", onClick);
  $nodes.append("title").text(function(d) {
    return d.name;
  });
  $links.exit().remove();
  $nodes.exit().remove();
  force.links(links).nodes(nodes).start();
  return bindControls();
};

getOrSet = function(map, key, value) {
  if (map.has(key)) {
    value = dataMaps.nodes.get(key);
  } else {
    map.set(key, value);
  }
  return value;
};

window.fbPostInit = function() {
  var options;

  options = {
    cluster: false
  };
  return FB.login(function(response) {
    return cachedFBapi('/me/friends', function(response) {
      var friends, maxMutualFriendCount, me, meNode;

      friends = response.data;
      me = {
        name: 'Me',
        id: '-1000'
      };
      meNode = makeNodeFromUser(me);
      meNode.group = 0;
      meNode.index = 0;
      meNode.isMe = true;
      meNode.mutualFriendCount = friends.length;
      dataMaps.nodes.set(meNode.id, meNode);
      maxMutualFriendCount = 1;
      return async.each(friends, (function(item, callback) {
        var fLink, fNode, friend;

        friend = item;
        fNode = makeNodeFromUser(friend);
        fNode = getOrSet(dataMaps.nodes, fNode.id, fNode);
        fLink = makeLink(meNode, fNode);
        return getMutualFriends(friend, function(response) {
          var mutualFriendCount, mutualFriends;

          mutualFriends = response.data;
          mutualFriendCount = mutualFriends.length;
          fNode.mutualFriendCount = mutualFriendCount;
          fLink.mutualFriendCount = mutualFriendCount;
          if (mutualFriendCount > maxMutualFriendCount) {
            maxMutualFriendCount = mutualFriendCount;
          }
          dataMaps.nodes.set(fNode.id, fNode);
          dataMaps.links.set(fLink.id, fLink);
          if (options.cluster) {
            mutualFriends.forEach(function(mItem) {
              var mLink, mNode;

              mNode = makeNodeFromUser(mItem);
              if (fNode.id === mNode.id) {
                return;
              }
              mNode = getOrSet(dataMaps.nodes, mNode.id, mNode);
              mLink = makeLink(fNode, mNode);
              mLink.strength = 0.5;
              return dataMaps.links.set(mLink.id, mLink);
            });
          }
          return callback();
        });
      }), function(err) {
        dataMaps.links.forEach(function(key, link) {
          if (link.mutualFriendCount != null) {
            link.strength = link.mutualFriendCount / maxMutualFriendCount;
            return link.target.strength = link.strength;
          }
        });
        return update();
      });
    });
  }, {});
};
