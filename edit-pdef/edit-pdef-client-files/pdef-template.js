
jade = (function(exports){
/*!
 * Jade - runtime
 * Copyright(c) 2010 TJ Holowaychuk <tj@vision-media.ca>
 * MIT Licensed
 */

/**
 * Lame Array.isArray() polyfill for now.
 */

if (!Array.isArray) {
  Array.isArray = function(arr){
    return '[object Array]' == Object.prototype.toString.call(arr);
  };
}

/**
 * Lame Object.keys() polyfill for now.
 */

if (!Object.keys) {
  Object.keys = function(obj){
    var arr = [];
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        arr.push(key);
      }
    }
    return arr;
  }
}

/**
 * Merge two attribute objects giving precedence
 * to values in object `b`. Classes are special-cased
 * allowing for arrays and merging/joining appropriately
 * resulting in a string.
 *
 * @param {Object} a
 * @param {Object} b
 * @return {Object} a
 * @api private
 */

exports.merge = function merge(a, b) {
  var ac = a['class'];
  var bc = b['class'];

  if (ac || bc) {
    ac = ac || [];
    bc = bc || [];
    if (!Array.isArray(ac)) ac = [ac];
    if (!Array.isArray(bc)) bc = [bc];
    ac = ac.filter(nulls);
    bc = bc.filter(nulls);
    a['class'] = ac.concat(bc).join(' ');
  }

  for (var key in b) {
    if (key != 'class') {
      a[key] = b[key];
    }
  }

  return a;
};

/**
 * Filter null `val`s.
 *
 * @param {Mixed} val
 * @return {Mixed}
 * @api private
 */

function nulls(val) {
  return val != null;
}

/**
 * Render the given attributes object.
 *
 * @param {Object} obj
 * @param {Object} escaped
 * @return {String}
 * @api private
 */

exports.attrs = function attrs(obj, escaped){
  var buf = []
    , terse = obj.terse;

  delete obj.terse;
  var keys = Object.keys(obj)
    , len = keys.length;

  if (len) {
    buf.push('');
    for (var i = 0; i < len; ++i) {
      var key = keys[i]
        , val = obj[key];

      if ('boolean' == typeof val || null == val) {
        if (val) {
          terse
            ? buf.push(key)
            : buf.push(key + '="' + key + '"');
        }
      } else if (0 == key.indexOf('data') && 'string' != typeof val) {
        buf.push(key + "='" + JSON.stringify(val) + "'");
      } else if ('class' == key && Array.isArray(val)) {
        buf.push(key + '="' + exports.escape(val.join(' ')) + '"');
      } else if (escaped && escaped[key]) {
        buf.push(key + '="' + exports.escape(val) + '"');
      } else {
        buf.push(key + '="' + val + '"');
      }
    }
  }

  return buf.join(' ');
};

/**
 * Escape the given string of `html`.
 *
 * @param {String} html
 * @return {String}
 * @api private
 */

exports.escape = function escape(html){
  return String(html)
    .replace(/&(?!(\w+|\#\d+);)/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
};

/**
 * Re-throw the given `err` in context to the
 * the jade in `filename` at the given `lineno`.
 *
 * @param {Error} err
 * @param {String} filename
 * @param {String} lineno
 * @api private
 */

exports.rethrow = function rethrow(err, filename, lineno){
  if (!filename) throw err;

  var context = 3
    , str = require('fs').readFileSync(filename, 'utf8')
    , lines = str.split('\n')
    , start = Math.max(lineno - context, 0)
    , end = Math.min(lines.length, lineno + context);

  // Error context
  var context = lines.slice(start, end).map(function(line, i){
    var curr = i + start + 1;
    return (curr == lineno ? '  > ' : '    ')
      + curr
      + '| '
      + line;
  }).join('\n');

  // Alter exception message
  err.path = filename;
  err.message = (filename || 'Jade') + ':' + lineno
    + '\n' + context + '\n\n' + err.message;
  throw err;
};

  return exports;

})({});

jade.templates = {};
jade.render = function(node, template, data) {
  var tmp = jade.templates[template](data);
  node.innerHTML = tmp;
};

jade.templates["parse-pdef-template"] = function(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
var parse_mixin = function(key, val, level){
var block = this.block, attributes = this.attributes || {}, escaped = this.escaped || {};
switch (Object.prototype.toString.call(val)){
case '[object Array]':
var type = ('Array');
  break;
case '[object Object]':
var type = ('Dictionary');
  break;
case '[object Boolean]':
var type = ('Boolean');
  break;
case '[object Number]':
var type = ('Number');
  break;
case '[object String]':
var type = ('String');
  break;
}
var indent = (40 * (level || 0));
var primitive = (type != 'Dictionary' && type != 'Array');
var items = (!primitive && Object.keys(val).length);
buf.push('<div');
buf.push(attrs({ 'data-type':("" + (type) + " " + (primitive ? 'primitive' : 'collection') + "") }, {"data-type":true}));
buf.push('><span');
buf.push(attrs({ 'style':("margin-left:" + (indent) + "px;"), "class": ('expand-collapse') }, {"style":true}));
buf.push('></span><span data-field="key">');
var __val__ = key
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><span data-control="del"><input type="button" value="del"/></span><span data-control="ins"><input type="button" value="ins" disabled="disabled"/></span><span data-field="type"><select disabled="disabled"><option');
buf.push(attrs({ 'value':("Array"), 'selected':(type=="Array") }, {"value":true,"selected":true}));
buf.push('>Array</option><option');
buf.push(attrs({ 'value':("Dictionary"), 'selected':(type=="Dictionary") }, {"value":true,"selected":true}));
buf.push('>Dictionary</option><option');
buf.push(attrs({ 'value':("Boolean"), 'selected':(type=="Boolean") }, {"value":true,"selected":true}));
buf.push('>Boolean</option><option');
buf.push(attrs({ 'value':("Number"), 'selected':(type=="Number") }, {"value":true,"selected":true}));
buf.push('>Number</option><option');
buf.push(attrs({ 'value':("String"), 'selected':(type=="String") }, {"value":true,"selected":true}));
buf.push('>String</option></select></span><span data-field="value">');
if ( type == 'Boolean')
{
buf.push('<select><option');
buf.push(attrs({ 'value':("true"), 'selected':(val) }, {"value":true,"selected":true}));
buf.push('>YES</option><option');
buf.push(attrs({ 'value':("false"), 'selected':(!val) }, {"value":true,"selected":true}));
buf.push('>NO</option></select>');
}
else if ( primitive)
{
buf.push('' + escape((interp = val) == null ? '' : interp) + '');
}
else
{
buf.push('(' + escape((interp = items) == null ? '' : interp) + ' ' + escape((interp = items == 1 ? "item" : "items") == null ? '' : interp) + ')');
}
buf.push('</span><br/>');
if ( !primitive)
{
// iterate val
;(function(){
  if ('number' == typeof val.length) {
    for (var k = 0, $$l = val.length; k < $$l; k++) {
      var v = val[k];

parse_mixin(k, v, level+1);
    }
  } else {
    for (var k in val) {
      var v = val[k];

parse_mixin(k, v, level+1);
   }
  }
}).call(this);

}
buf.push('</div>');
};
parse_mixin(key, value, level);
}
return buf.join("");
}