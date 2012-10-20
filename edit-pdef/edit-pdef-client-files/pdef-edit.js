var laptopTesting = window.location.hash == '#laptop-testing'
  , pdef
  , changeStack = []
  , currStackIndex
  , lastSaveStackIndex

$(function() {
  setEnableExpandCollapse(true)
  setEnableEditKey(true)
  setEnableEditValue(true)

  // if input focues and touching outside input, blur input
  $(document)
    .on('click touchstart', function(e) {
      var focusedInput = $('input:focus')[0]
      focusedInput && e.target !== focusedInput && $(focusedInput).blur()
    })
    .on('click touchstart', 'div[data-type]', function(e) {
      if (e.currentTarget !== $(e.target).closest('div[data-type]')[0]) return false
      if ($(e.currentTarget).hasClass('selected')) return false

      var getKey = function(el) {
        return $(el).children('[data-field="key"]').text()
      }
      var log = [
            e.type
            , 'currentTarget key: ' + getKey($(e.currentTarget))
      ]

      var fn = function() {
        $('div[data-type].selected').removeClass('selected')
        $(e.currentTarget).addClass('selected')
        log.push('currentTarget key: ' + getKey(e.currentTarget))
        alert(log.join('\n'))
      }

      if (e.type == 'click') {
        fn()
      } else {
        $(window).on('touchmove touchcancel touchend', function(e) {
          if (e.type != 'touchmove') fn()
          $(window).off('touchmove touchcancel touchend', arguments.callee)
        })
      }
    })
    .on('click touchstart', 'div[data-type].selected > span > input[type="button"][value="del"]', function() {
      $(this).closest('div[data-type]').remove()
    })

  // test-edits button listener
  $('input[type="button"][value="test"]').on('touchstart click', function() {
    var $form = $('<form action="test-edits" method="POST"><input type="text" name="pdef" /></form>')
    $form.children('[name="pdef"]').val(JSON.stringify(getJSON()))
    if (!laptopTesting) $form.submit()
  })
  $('input[type="button"][value="cancel"]').on('touchstart click', function() {
    self.location = "cancel"
  })

  if (!laptopTesting) window.location = "ready"
  else appInterface.loadPDef(json)
})

var appInterface = {
  loadPDef: function(pDef) {
    pdef = pDef

    // wihout delay some images don't load
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

  $(document)[on ? 'on' : 'off']('touchstart', 'div[data-type~="collection"] > span.expand-collapse', fn)
}

function setEnableEditKey(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $span = $(this)
    , $input = $('<input type="text"/>').val($span.text())

    $span.html($input)
    $input.focus()

    $input.on('focusout', function() {
      $span.html($input.val())
    })
    return false
  }

  $(window)[on ? 'on' : 'off']('click touchstart', 'div[data-type]:not([data-type~="Array"]) > div[data-type].selected > span[data-field="key"]:not(:has(>input))', fn)
}

function setEnableEditValue(on) {
  var fn = arguments.callee.fn = arguments.callee.fn || function() {
    var $span = $(this)
      , oldVal = $span.text()
      , w = $('#pdef-wrapper').width() - $span.offset().left
      , $input = $('<input type="text"/>').val(oldVal).width(w)

    $span.html($input)
    $input.focus()

    $input.on('focusout', function() {
      var newVal = $input.val()
      $span.html(newVal)
      if (newVal !== oldVal) {
        //onChangeValue($span)
      }
    })
    return false
  }

  $(window)[on ? 'on' : 'off']('click touchstart', 'div[data-type] > div[data-type~="primitive"].selected:not([data-type~="Boolean"]) > span[data-field="value"]:not(:has(>input))', fn)
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

function onChangeValue() {
  var $form = $('<form action="change" method="POST"><input type="text" name="pdef" /></form>')
  $form.children('[name="pdef"]').val(JSON.stringify(getJSON()))
  if (!laptopTesting) $form.submit()
}
