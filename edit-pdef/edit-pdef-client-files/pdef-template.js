
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
var types = ({ '[object Array]':'Array collection', '[object Object]':'Dictionary collection', '[object Boolean]':'Boolean primitive', '[object Number]':'Number primitive', '[object String]':'String primitive' });
var parse_mixin = function(key, val, level){
var block = this.block, attributes = this.attributes || {}, escaped = this.escaped || {};
var indent = (40 * (level || 0));
var type = (types[Object.prototype.toString.call(val)]);
var primitive = (!type.match(/collection$/));
var items = (!primitive && Object.keys(val).length);
buf.push('<div');
buf.push(attrs({ 'data-type':(type), 'data-key':(key) }, {"data-type":true,"data-key":true}));
buf.push('><span');
buf.push(attrs({ 'style':("margin-left:" + (indent) + "px;"), "class": ('expand-collapse') }, {"style":true}));
buf.push('></span><span data-field="key">');
var __val__ = key
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</span><span data-controls="data-controls">');
// iterate ["copy", "paste", "ins", "del"]
;(function(){
  if ('number' == typeof ["copy", "paste", "ins", "del"].length) {
    for (var $index = 0, $$l = ["copy", "paste", "ins", "del"].length; $index < $$l; $index++) {
      var action = ["copy", "paste", "ins", "del"][$index];

buf.push('<input');
buf.push(attrs({ 'type':("button"), 'value':(action), 'data-action':(action) }, {"type":true,"value":true,"data-action":true}));
buf.push('/>');
    }
  } else {
    for (var $index in ["copy", "paste", "ins", "del"]) {
      var action = ["copy", "paste", "ins", "del"][$index];

buf.push('<input');
buf.push(attrs({ 'type':("button"), 'value':(action), 'data-action':(action) }, {"type":true,"value":true,"data-action":true}));
buf.push('/>');
   }
  }
}).call(this);

buf.push('</span><span data-field="type"><select');
buf.push(attrs({ 'disabled':(level==0) }, {"disabled":true}));
buf.push('>');
// iterate types
;(function(){
  if ('number' == typeof types.length) {
    for (var $index = 0, $$l = types.length; $index < $$l; $index++) {
      var t = types[$index];

buf.push('<option');
buf.push(attrs({ 'value':(t), 'selected':(t==type) }, {"value":true,"selected":true}));
buf.push('>');
var __val__ = t.match(/^(\S+)/)[1]
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</option>');
    }
  } else {
    for (var $index in types) {
      var t = types[$index];

buf.push('<option');
buf.push(attrs({ 'value':(t), 'selected':(t==type) }, {"value":true,"selected":true}));
buf.push('>');
var __val__ = t.match(/^(\S+)/)[1]
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</option>');
   }
  }
}).call(this);

buf.push('</select></span><span data-field="value">');
if ( type == 'Boolean primitive')
{
buf.push('<select><option');
buf.push(attrs({ 'value':("1"), 'selected':(val) }, {"value":true,"selected":true}));
buf.push('>YES</option><option');
buf.push(attrs({ 'value':("0"), 'selected':(!val) }, {"value":true,"selected":true}));
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