express = require('express')

app = express()

app.configure ->
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));

app.configure 'development', ->
  app.use(express.errorHandler({
    dumpExceptions: true
    showStack: true
  }))

app.configure 'production', ->
  app.use(express.errorHandler())

port = process.env.PORT || 5000
app.listen port, ->
  console.log("Listening on " + port);

APP_ID = '233015833395244'
CANVAS_PAGE = 'http://apps.facebook.com/facebook-viz'
DIALOG_URL = 'https://www.facebook.com/dialog/oauth?client_id=' + encodeURIComponent(APP_ID) + '&redirect_uri=' + encodeURIComponent(CANVAS_PAGE);

base64 = require('./base64')

app.post '/', (req, res) ->
  res.sendfile(__dirname + '/public/index.html');

app.post '/canvas', (req, res) ->
  signed_request = req.body.signed_request
  [sig, data] = signed_request.split('.').map((e) -> base64.decode(e))
  res.write(sig)
  res.write(data)
  res.end()
  return
  signed_request = JSON.parse(signed_request)
  res.write signed_request
  res.send(JSON.stringify(signed_request, null, '\t'));
  #res.sendfile(__dirname + '/public/auth.html')
  #res.sendfile(__dirname + '/public/index.html');

