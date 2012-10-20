var http = require('http')
  , filed = require('filed')
  , exec = require('child_process').exec
  , util = require('util')
  , clientjade = require('clientjade')


http.createServer(function(req,res) {
  var date = new Date()
  console.log('hit:', date)

  var sendError = function(e) {
    if (!e) return false
    console.log('error:', date, e)
    res.writeHead(500)
    res.end(e.toString())
    return true
  }

  exec('../node_modules/clientjade/bin/clientjade parse-pdef-template.jade > pdef-template.js', { cwd: __dirname+'/edit-pdef-client-files/' }, function(e, stdout, stderr) {
    if (!sendError(e || stderr)) {
      var zipfile = __dirname + '/tmp/' + new Date().toJSON().replace(/:/g, '_') + '.zip'

      exec('zip ' + zipfile + ' -r ../edit-pdef-client-files/*', { cwd: __dirname + '/tmp' }, function(e, stdout, stderr) {
        if (!sendError(e || stderr)) filed(zipfile).pipe(res)
      })
    }
  })
}).listen(1234)

