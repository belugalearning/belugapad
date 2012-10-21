var ios = navigator.userAgent.match(/iphone|ipad|ipod/i) !== null
  , pdef
  , changeStack = []
  , currStackIndex = 0
  , lastSaveStackIndex = 0

$(function() {
  $('#pdef-wrapper').height($(window).height() - $('#pdef-wrapper').offset().top - 10)
  setEnableExpandCollapse(true)
  setEnableEditKey(true)
  setEnableEditValue(true)

  // TODO: restore insert
  // TODO: What should cancel button really do?
  
  $(document)
    // if input focues and touching outside input, blur input
    .on('click', function(e) {
      var focusedInput = $('input:focus')[0]
      focusedInput && e.target !== focusedInput && $(focusedInput).blur()
    })
    .on('click', 'div[data-type]', function(e) {
      if (e.currentTarget !== $(e.target).closest('div[data-type]')[0]) return false
      if ($(e.currentTarget).hasClass('selected')) return false

      $('div[data-type].selected').removeClass('selected')
      $(e.currentTarget).addClass('selected')
    })
    .on('click', 'div[data-type].selected > span > input[type="button"][value="del"]', deleteKey)
    .on('change', 'div[data-type~="primitive"] > span[data-field="value"] > select', valueOptionChanged)

  // test-edits button listener
  $('input[type="button"][value="test"]').on('click', function() {
    var $form = $('<form action="test-edits" method="POST"><input type="text" name="pdef" /></form>')
    $form.children('[name="pdef"]').val(JSON.stringify(getJSON()))
    if (ios) $form.submit()
  })
  // cancel edits button listener
  $('input[type="button"][value="cancel"]').on('click', function() {
    if (ios) self.location = "cancel"
  })
  // undo / redo
  $('input[type="button"][value="undo"]').on('click', undo)
  $('input[type="button"][value="redo"]').on('click', redo)
  

  ios ? self.location = "ready": appInterface.loadPDef(testJSON)
})

var appInterface = {
  loadPDef: function(pDef) {
    pdef = pDef

    // TODO: investigate - wihout delay some images don't load, arbitrary time delay hardly reliable
    setTimeout(function() {
      jade.render($('#pdef-wrapper')[0], 'parse-pdef-template', { key:'root', value:pdef, level:0 })
    }, 100)
    /*

      var maxCol1Right = Math.max.apply(null, $('[data-field="key"]').map(function() {
        return $(this).offset().left + $(this).outerWidth(true)
      }))
      var col2Left = 50 + maxCol1Right
      var col3Left = 150 + col2Left

      alert(maxCol1Right + '  ' + col2Left + '  ' + col3Left)

      $('span[data-field="type"]').css('left', col2Left)
      $('span[data-field="value"]').css('left', col3Left)
     */
    return 'ok'
  }
  , getState: function() {
    return JSON.stringify({
      pdef: pdef
      , changeStack: changeStack
      , currStackIndex: currStackIndex
      , lastSaveStackIndex: lastSaveStackIndex
    })
  }
}

function setEnableExpandCollapse(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $p = $(this).parent()
    $p.hasClass('collapsed') ? $p.removeClass('collapsed') : $p.addClass('collapsed')
  }
  $(document)[on ? 'on' : 'off']('click', 'div[data-type~="collection"] > span.expand-collapse', fn)
}

function deleteKey(e) {
  var path = pathToElement(e.target)
  var $el = $(this).closest('[data-type]')
  var r = recordChange({
    type:'delete-key'
    , key: path[0]
    , parentPath:path.splice(1)
    , index: $el.siblings('[data-type]').andSelf().index($el)
  }) && $el.remove()
}

function setEnableEditKey(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $span = $(this)
    , oldKey = $span.text()
    , $input = $('<input type="text"/>').val(oldKey)

    $span.html($input)
    $input.focus()

    $input.on('focusout', function() {
      var newKey = $input.val().trim()
      if (!newKey || newKey === oldKey) {
        $span.html(oldKey)
      } else if ($span.parent().siblings('[data-key="' + newKey + '"]').length) {
        $span.html(oldKey)
        alert('error: duplicate key')
      } else {
        var path = pathToElement($span)
        $span
          .html(newKey)
          .closest('[data-key]').attr('data-key', newKey)

        recordChange({
          type: 'edit-key'
          , parentPath: path.slice(1)
          , oldKey: oldKey
          , newKey: newKey
        })
      }
    })
    return false
  }

  $(document)[on ? 'on' : 'off']('click', 'div[data-type]:not([data-type~="Array"]) > div[data-type].selected > span[data-field="key"]:not(:has(>input))', fn)
}

function setEnableEditValue(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $span = $(this)
      , oldVal = $span.text()
      , w = $('#pdef-wrapper').width() - $span.offset().left
      , $dt = $span.closest('[data-type]')
      , isNumber = $dt.is('[data-type~="Number"]')
      , inputType = isNumber ? 'number' : 'text'
      , $input = $('<input type="'+inputType+'"/>').val(oldVal).width(w)

    $span.html($input)
    $input.focus()

    $input.on('change focusout', function(e) {
      $input.off('change focusout', arguments.callee)

      var newVal = $input.val()

      if (newVal === '' || e.type == 'focusout') {
        $span.html(oldVal)
        return
      }

      if (isNumber) newVal = Number(newVal)
      var path = pathToElement($span)
      $span.html(newVal)
      recordChange({
        type: 'edit-value'
        , parentPath: path.splice(1)
        , key: path[0]
        , oldVal: oldVal
        , newVal: newVal
      })
    })
    return false
  }

  $(document)[on ? 'on' : 'off']('click', 'div[data-type] > div[data-type~="primitive"].selected:not([data-type~="Boolean"]) > span[data-field="value"]:not(:has(>input))', fn)
}

function valueOptionChanged() {
  var $dt = $(this).closest('[data-type]')
  var path = pathToElement(this)
  recordChange({
    type: 'edit-value'
    , parentPath: path.splice(1)
    , key: path[0]
    , oldVal: objAtPath(path)
    , newVal: $dt.is('[data-type~="Boolean"]') ? Boolean(Number($(this).val())) : $dt.is('[data-type~="Number"]') ? Number($(this).val()) : $(this).val()
  })
}

function updateColWidths() {
    var maxCol1Right = Math.max.apply(null, $('[data-field="key"]').map(function() {
      return $(this).offset().left + $(this).outerWidth(true)
    }))
    var col2Left = 50 + maxCol1Right
    var col3Left = 150 + col2Left

    $('span[data-field="type"]').css('left', col2Left)
    $('span[data-field="value"]').css('left', col3Left)
}

function getJSON() {
  return (function rec($el) {
    if ($el.is('[data-type~="Dictionary"]')) {
      var o = {}
      $.each($el.children('[data-type]'), function(i, child) {
        var $c = $(child)
        var key = $c.children('[data-field="key"]').text()
        o[key] = rec($c)
      })
      return o
    } else if ($el.is('[data-type~="Array"]')) {
      var a = []
      $.each($el.children('[data-type]'), function(i, child) {
        a[i] = rec($(child))
      })
      return a
    } else if ($el.is('[data-type~="Boolean"]')) {
      return $el.children('[data-field="value"]').children('select').val() == '1'
    } else if ($el.is('[data-type~="Number"]')) {
      return Number($el.children('span[data-field="value"]').text())
    } else {
      return $el.children('[data-field~="value"]').text()
    }
  })($('[data-type]:first'))
}

function pathToElement(el) {
  var stack = $(el).parents('[data-type][data-key!="root"]').toArray()
  if ($(el).is('[data-type]')) stack.unshift(el)

  return stack
    .map(function(dt, i) {
      return $(stack[i+1]).is('[data-type~="Array"]')
        ? $(dt).siblings('[data-type]').andSelf().index(dt)
        : $(dt).attr('data-key')
    })
}

function elementSelectorFromPath(path) {
  var sel = '#pdef-wrapper > [data-type][data-key="root"]'
  for (var i=path.length; i--;) {
    var part = path[i]
    if (typeof part == 'number') {
      sel += ' > [data-type]:eq(' + part + ')'
    } else {
      sel += ' > [data-type][data-key="' + part + '"]'
    }
  }
  return sel
}

function objAtPath(path) {
  var o = pdef
    , i = path.length
  while (i-- && o) o = o[path[i]]
  return o
}

function recordChange(change) {
  switch(change.type) {
    case 'edit-key':
      var parent = objAtPath(change.parentPath)
      if (!parent) {
        var path = Object.prototype.toString.call(change.parentPath) == '[object Array]' ? change.parentPath.join(' < ') : '[BAD PATH]'
        alert('parent not found at path:' + path)
        return false
      }
      parent[change.newKey] = parent[change.oldKey]
      delete parent[change.oldKey]
      break
    case 'delete-key':
      var parent = objAtPath(change.parentPath)
      if (!parent) {
        var path = Object.prototype.toString.call(change.parentPath) == '[object Array]' ? change.parentPath.join(' < ') : '[BAD PATH]'
        alert('parent not found at path:' + path)
        return false
      }
      change.value = parent[change.key]
      delete parent[change.key]
      break
    case 'edit-value':
      var parent = objAtPath(change.parentPath)
      if (!parent) {
        var pathString = Object.prototype.toString.call(change.parentPath) == '[object Array]' ? change.parentPath.join(' < ') : '[BAD PATH]'
        alert('parent not found at path:' + pathString)
        return false
      }
      if (typeof parent[change.key] == 'undefined') {
        alert('key not found at path:' + change.key + ' < ' + change.parentPath.join(' < '))
        return false
      }
      parent[change.key] = change.newVal
      break
    default:
      alert('unhandled change type: ' + change.type)
      return false
  }
  changeStack[currStackIndex++] = change
  if (lastSaveStackIndex > currStackIndex) lastSaveStackIndex = null
  changeStack.splice(currStackIndex)
  updateUndoRedoEnabled()
  return true
}

function undo() {
  var change = changeStack[--currStackIndex]
  switch(change.type) {
    case 'edit-key':
      var $el = $(elementSelectorFromPath([change.newKey].concat(change.parentPath)))
      $el
        .attr('data-key', change.oldKey)
        .children('span[data-field="key"]').html(change.oldKey)
      var parent = objAtPath(change.parentPath)
      parent[change.oldKey] = parent[change.newKey]
      delete parent[change.newKey]
      break
    case 'delete-key':
      var parent = objAtPath(change.parentPath)
      parent[change.key] = change.value

      var $temp = $('<span/>')
      jade.render($temp[0], 'parse-pdef-template', { key:change.key, value:change.value, level:change.parentPath.length+1 })

      var $parent = $(elementSelectorFromPath(change.parentPath))
      var $next = $parent.children('[data-type]:eq('+change.index+')')
      if ($next.length) $next.before($temp.children())
      else $parent.append($temp.children())
      break
    case 'edit-value':
      var $span = $(elementSelectorFromPath([change.key].concat(change.parentPath))).children('[data-field="value"]')
        , $sel = $span.children('select')
        , oldVal = $span.closest('[data-type]').is('[data-type~="Boolean"]') ? Number(change.oldVal) : change.oldVal
      $sel.length ? $sel.val(oldVal) : $span.html(oldVal)
      objAtPath(change.parentPath)[change.key] = change.oldVal
      break
  }
  updateUndoRedoEnabled()
}

function redo() {
  var change = changeStack[currStackIndex++]
  switch(change.type) {
    case 'edit-key':
      var $el = $(elementSelectorFromPath([change.oldKey].concat(change.parentPath)))
      $el
        .attr('data-key', change.newKey)
        .children('span[data-field="key"]').html(change.newKey)
      var parent = objAtPath(change.parentPath)
      parent[change.newKey] = parent[change.oldKey]
      delete parent[change.oldKey]
      break
    case 'delete-key':
      var parent = objAtPath(change.parentPath)
      delete parent[change.key]
      $(elementSelectorFromPath([change.key].concat(change.parentPath))).remove()
      break
    case 'edit-value':
      var $span = $(elementSelectorFromPath([change.key].concat(change.parentPath))).children('[data-field="value"]')
        , $sel = $span.children('select')
        , newVal = $span.closest('[data-type]').is('[data-type~="Boolean"]') ? Number(change.newVal) : change.newVal
      $sel.length ? $sel.val(newVal) : $span.html(newVal)
      objAtPath(change.parentPath)[change.key] = change.newVal
      break
  }
  updateUndoRedoEnabled()
}

function updateUndoRedoEnabled() {
  $('input[type="button"][value="undo"]').prop('disabled', currStackIndex == 0)
  $('input[type="button"][value="redo"]').prop('disabled', currStackIndex == changeStack.length)
}
