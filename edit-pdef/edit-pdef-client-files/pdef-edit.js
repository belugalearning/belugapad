var ios = navigator.userAgent.match(/iphone|ipad|ipod/i) !== null
  , pdef
  , changeStack = []
  , currStackIndex = 0
  , lastSaveStackIndex = 0
  , clipboard

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
    .on('change', 'div[data-type] > span[data-field="type"] > select', onTypeSelectChange)
    .on('click', 'div[data-type].selected > span[data-controls] > [data-action="del"]', deleteKey)
    .on('click', 'div[data-type].selected > span[data-controls] > [data-action="ins"]', insertKey)
    .on('click', 'div[data-type].selected > span[data-controls] > [data-action="copy"]', copyKey)
    .on('click', 'div[data-type].selected > span[data-controls] > [data-action="paste"]', pasteKey)
    .on('change', 'div[data-type~="primitive"] > span[data-field="value"] > select', valueOptionChanged)
    .on('touchstart', 'div#modal-bg', function() { return false }) // disable scrolling when modal popup showing

  $('input[type="button"][value="test"]').on('click', function() { if (ios) self.location = 'test-edits' })
  $('input[type="button"][value="cancel"]').on('click', function() { if (ios) self.location = "cancel" })

  // undo / redo / save
  $('input[type="button"][value="undo"]').on('click', undo)
  $('input[type="button"][value="redo"]').on('click', redo)
  $('input[type="button"][value="save"]').on('click', save)
  

  ios ? self.location = "ready": appInterface.loadPDef(testJSON)
})

var appInterface = {
  loadPDef: function(pdef_, changeStack_, currStackIndex_, lastSaveStackIndex_) {
    pdef = pdef_
    changeStack = changeStack_
    currStackIndex = currStackIndex_
    lastSaveStackIndex = lastSaveStackIndex_
    updateControlStripButtonsEnabled()

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
  , serverSaveCallback: function(e, statusCode, b) {
    if (statusCode == 409) {
      buttonModalDialog('Version conflict. Do you want to overwrite the version saved on the server?', 'yes', 'no', function(val) {
        if (val == 'yes') self.location = 'save-override-conflict?rev=' + JSON.parse(b).rev
      })
    } else {
      var errorString = 'Error saving pdef.\nStatus Code: ' + statusCode
      if (e) errorString += '\nDescription: ' + e
      if (b) errorString += '\nResponse Body: ' + b
      alert(errorString)
    }
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
    , $el = $(this).closest('[data-type]')

  recordChange({
    type:'delete-key'
    , key: path[0]
    , parentPath:path.splice(1)
    , index: $el.siblings('[data-type]').andSelf().index($el)
  }) && $el.remove()
}

function insertKey(e, paste) {
  var $temp = $('<span/>')
    , $selected = $(e.target).closest('[data-key]')
    , $parent = $(e.target).closest('[data-type~="collection"]:not(.collapsed)')
    , insertAsFirstChildOfSelected = $selected[0] === $parent[0]
    , index = insertAsFirstChildOfSelected ? 0 : $parent.children('[data-key]').index($selected) + 1
    , parentPath = pathToElement($parent)
    , key
    , value = paste ? clipboard.value : ''

  if ($parent.is('[data-type~="Array"]')) {
    key = index
  } else {
    var i = 0
      , defaultKeyStem = 'New Item'
      , keyStem
      , key

    var nextKey = function(i) {
      if (i == 0) {
        key = keyStem = paste && clipboard.key && typeof clipboard.key != 'number' ? clipboard.key.replace(/^(.*?)(-\d)?$/, '$1') : defaultKeyStem
      } else {
        key = keyStem + '-' + i
      }
      return true
    }
    while (nextKey(i) && $parent.children('[data-key="' + key + '"]').length) i++
  }

  jade.render($temp[0], 'parse-pdef-template', { key:key, value:value, level:parentPath.length + 1 })
  console.log(key, value, parentPath.length+1, $temp)

  var $el = $temp.children()
    , $next = $parent.children('[data-key]:eq(' + index + ')')

  if ($el.is('[data-type~="collection"]')) $el.addClass('collapsed')

  $next.length ? $next.before($el) : $parent.append($el)

  var elTop = $el.offset().top
    , elBottom = elTop + $el.height()
    , $wrapper = $('#pdef-wrapper')
    , wrapTop = $wrapper.offset().top
    , wrapBottom = wrapTop + $wrapper.height()
    , wrapScrollTop = $wrapper.scrollTop()
    , scrolled = false

  // ensure new key in view
  if (elTop < wrapTop) {
    scrolled = true
    $wrapper.scrollTop(wrapScrollTop - wrapTop + elTop)
  } else if (elBottom > wrapBottom) {
    scrolled = true
    $wrapper.scrollTop(10 + wrapScrollTop + elBottom - wrapBottom)
  }

  var selectNewKey = function() { $el.click() }
  selectNewKey()
  setTimeout(function() { selectNewKey() }, 0)

  // TODO: record change - include index to protect against future non-append inserts 
  recordChange({
    type: 'insert-key'
    , parentPath: parentPath
    , key: key
    , value: value
    , index: index
  })
}

function copyKey(e) {
  var path = pathToElement(e.target)
    , key = path[0]
    , value = JSON.parse(JSON.stringify(objAtPath(path)))
  clipboard = { key:key, value:value }

  $('#pdef-wrapper').attr('data-clipboard', '')
  console.log(clipboard)
}

function pasteKey(e) {
  insertKey(e, true)
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

function onTypeSelectChange(e) {
  var path = pathToElement(e.target)
    , $el = $(this).closest('[data-type]')

  // Boolean store nothing
  // Number store number
  // String store string
  // 
  var oldType = $el.attr('data-type')
    , newType = $el.children('[data-field="type"]').children('select').val()
    , val = objAtPath(path)
    , newVal

  switch (newType) {
    case 'Array collection':
      if (oldType == 'Dictionary collection') {
        newVal = Object.keys(val).map(function(k) { return val[k] })
      } else {
        newVal = []
      }
      break
    case 'Dictionary collection':
      newVal = {}
      if (oldType == 'Array collection') val.forEach(function(item, i) { newVal['item'+i] = item })
      break
    case 'Boolean primitive':
      newVal = (typeof val == 'string' &&  val.toLowerCase() == 'true') || (!isNaN(val) && Number(val) === 1)
      break
    case 'Number primitive':
      newVal = !isNaN(val) && Number(val) || 0
      break
    case 'String primitive':
      newVal = !isNaN(val) && Number(val).toString() || ''
      break
  }

  recordChange({
    type:'change-type'
    , key: path[0]
    , parentPath:path.slice(1)
    , oldType: oldType
    , newType: newType
    , oldVal: JSON.parse(JSON.stringify(val))
    , newVal: newVal
  })
}

function changeType(change, reverse) {
  var parent = objAtPath(change.parentPath)
    , path = [change.key].concat(change.parentPath)
    , $temp = $('<span/>')

  parent[change.key] = reverse ? change.oldVal : change.newVal

  jade.render($temp[0], 'parse-pdef-template', { key:change.key, value:parent[change.key], level:path.length })

  $(elementSelectorFromPath(path)).replaceWith($temp.children())
  $(elementSelectorFromPath(path)).click()
}

function setEnableEditValue(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $span = $(this)
      , oldVal = $span.text()
      , w = $('#pdef-wrapper').width() - $span.offset().left
      , $dt = $span.closest('[data-type]')
      , isNumberField = $dt.is('[data-type~="Number"]')
      , inputType = isNumberField ? 'number' : 'text'
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

      if (isNumberField) newVal = Number(newVal)
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
  if (!$(el).parents('[data-type]').length) return []

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
  var parent = change.parentPath && objAtPath(change.parentPath)
    , parentIsArray = parent && Object.prototype.toString.call(parent) == '[object Array]'

  switch(change.type) {
    case 'change-type':
      changeType(change, false)
      break
    case 'insert-key':
      if (parentIsArray) {
        $(elementSelectorFromPath(change.parentPath))
          .children('[data-key]:gt('+change.key+')')
          .each(function(i, el) {
            var ix = change.key + i + 1
            $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
          })

        for (var i=parent.length; i > change.key; i--) {
          parent[i] = parent[--i]
        }
      }
      parent[change.key] = change.value
      break
    case 'delete-key':
      change.value = parent[change.key]

      if (parentIsArray) {
        $(elementSelectorFromPath(change.parentPath))
          .children('[data-key]:gt('+change.key+')').each(function(i, el) {
            var ix = change.key + i
            $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
          })

        for (var i=change.key; parent[++i];) {
          parent[i-1] = parent[i]
        }
        parent.splice(i-1)
      } else {
        delete parent[change.key]
      }
      break
    case 'edit-key':
      if (!parent) {
        var path = Object.prototype.toString.call(change.parentPath) == '[object Array]' ? change.parentPath.join(' < ') : '[BAD PATH]'
        alert('parent not found at path:' + path)
        return false
      }
      parent[change.newKey] = parent[change.oldKey]
      delete parent[change.oldKey]
      break
    case 'edit-value':
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
  updateControlStripButtonsEnabled()
  return true
}

function undo() {
  var change = changeStack[--currStackIndex]
    , parent = change.parentPath && objAtPath(change.parentPath)
    , parentIsArray = parent && Object.prototype.toString.call(parent) == '[object Array]'

  switch(change.type) {
    case 'change-type':
      changeType(change, true)
      break
    case 'insert-key':
      var $parent = $(elementSelectorFromPath(change.parentPath))

      if (parentIsArray) {
        $parent.children('[data-key]:gt('+change.key+')').each(function(i, el) {
          var ix = change.key + i
          $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
        })
        $parent.children('[data-key]:eq('+change.key+')').remove()

        for (var i=change.key; parent[++i];) {
          parent[i-1] = parent[i]
        }
        parent.splice(i-1)
      } else {
        $parent.children('[data-key="'+change.key+'"]').remove()
        delete parent[change.key]
      }

      break
    case 'delete-key':
      var $temp = $('<span/>')
      jade.render($temp[0], 'parse-pdef-template', { key:change.key, value:change.value, level:change.parentPath.length+1 })

      var $parent = $(elementSelectorFromPath(change.parentPath))
        , $next = $parent.children('[data-type]:eq('+change.index+')')
        , $el = $temp.children()

      if ($el.is('[data-type~="collection"]')) $el.addClass('collapsed')

      $next.length ? $next.before($el) : $parent.append($el)

      if (parentIsArray) {
        $parent
          .children('[data-key]:gt('+change.key+')')
          .each(function(i, el) {
            var ix = change.key + i + 1
            $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
          })

        for (var i=parent.length; i > change.key; i--) {
          parent[i] = parent[--i]
        }
      }
      parent[change.key] = change.value
      break
    case 'edit-key':
      var $el = $(elementSelectorFromPath([change.newKey].concat(change.parentPath)))
      $el
        .attr('data-key', change.oldKey)
        .children('span[data-field="key"]').html(change.oldKey)
      parent[change.oldKey] = parent[change.newKey]
      delete parent[change.newKey]
      break
    case 'edit-value':
      var $span = $(elementSelectorFromPath([change.key].concat(change.parentPath))).children('[data-field="value"]')
        , $sel = $span.children('select')
        , oldVal = $span.closest('[data-type]').is('[data-type~="Boolean"]') ? Number(change.oldVal) : change.oldVal
      $sel.length ? $sel.val(oldVal) : $span.html(oldVal)
      parent[change.key] = change.oldVal
      break
  }
  updateControlStripButtonsEnabled()
}

function redo() {
  var change = changeStack[currStackIndex++]
    , parent = change.parentPath && objAtPath(change.parentPath)
    , parentIsArray = parent && Object.prototype.toString.call(parent) == '[object Array]'

  switch(change.type) {
    case 'change-type':
      changeType(change, false)
      break
    case 'insert-key':
      var $temp = $('<span/>')
      jade.render($temp[0], 'parse-pdef-template', { key:change.key, value:change.value, level:change.parentPath.length+1 })

      var $parent = $(elementSelectorFromPath(change.parentPath))
        , $next = $parent.children('[data-type]:eq('+change.index+')')
        , $el = $temp.children()

      if ($el.is('[data-type~="collection"]')) $el.addClass('collapsed')

      $next.length ? $next.before($el) : $parent.append($el)

      if (parentIsArray) {
        $parent
          .children('[data-key]:gt('+change.key+')')
          .each(function(i, el) {
            var ix = change.key + i + 1
            $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
          })

        for (var i=parent.length; i > change.key; i--) {
          parent[i] = parent[--i]
        }
      }
      parent[change.key] = change.value
      break
    case 'delete-key':
      var $parent = $(elementSelectorFromPath(change.parentPath))

      if (parentIsArray) {
        $parent.children('[data-key]:gt('+change.key+')').each(function(i, el) {
          var ix = change.key + i
          $(el).attr('data-key', ix).children('[data-field="key"]').html(ix)
        })
        $parent.children('[data-key]:eq('+change.key+')').remove()

        for (var i=change.key; parent[++i];) {
          parent[i-1] = parent[i]
        }
        parent.splice(i-1)
      } else {
        $parent.children('[data-key="'+change.key+'"]').remove()
        delete parent[change.key]
      }
      break
    case 'edit-key':
      var $el = $(elementSelectorFromPath([change.oldKey].concat(change.parentPath)))
      $el
        .attr('data-key', change.newKey)
        .children('span[data-field="key"]').html(change.newKey)
      parent[change.newKey] = parent[change.oldKey]
      delete parent[change.oldKey]
      break
    case 'edit-value':
      var $span = $(elementSelectorFromPath([change.key].concat(change.parentPath))).children('[data-field="value"]')
        , $sel = $span.children('select')
        , newVal = $span.closest('[data-type]').is('[data-type~="Boolean"]') ? Number(change.newVal) : change.newVal
      $sel.length ? $sel.val(newVal) : $span.html(newVal)
      objAtPath(change.parentPath)[change.key] = change.newVal
      break
  }
  updateControlStripButtonsEnabled()
}

function save() {
  if (ios) self.location = 'save'
}

function updateControlStripButtonsEnabled() {
  $('input[type="button"][value="undo"]').prop('disabled', currStackIndex == 0)
  $('input[type="button"][value="redo"]').prop('disabled', currStackIndex == changeStack.length)
  $('input[type="button"][value="save"]').prop('disabled', currStackIndex === lastSaveStackIndex)
}

function buttonModalDialog(text) {
  var buttons = [].slice.call(arguments, 1, arguments.length - 1)
  var callback = arguments[arguments.length - 1]

  var $modalBG = $('<div id="modal-bg"/>').appendTo('body')
  var $modalDialog = $('<div id="modal-dialog"/>')
    .appendTo('body')
    .html(text + '<br/>')

  buttons.forEach(function(b) {
    $('<input type="button" value="'+b+'" />')
      .appendTo($modalDialog)
      .on('click', function() {
        callback($(this).val())
        $modalBG.add($modalDialog).remove()
      })
  })
}
