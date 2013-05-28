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

app.post '/', (req, res) ->
  res.sendfile(__dirname + '/public/index.html');
