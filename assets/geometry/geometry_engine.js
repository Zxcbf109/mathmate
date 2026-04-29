(function () {
  var board = null
  var mode = 'select'
  var selectedPoint = null
  var pointCount = 0
  var tempLinePoints = []
  var tempLinePreview = null

  function postMessage(payload) {
    if (window.GeometryBridge && window.GeometryBridge.postMessage) {
      window.GeometryBridge.postMessage(JSON.stringify(payload))
    }
  }

  function clearNode(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild)
    }
  }

  function initBoard() {
    if (board) return
    board = JXG.JSXGraph.initBoard('jxgbox', {
      boundingbox: [-10, 8, 10, -8],
      axis: true,
      showCopyright: false,
      showNavigation: true,
      pan: { enabled: true, needTwoFingers: true },
      zoom: { enabled: true, needTwoFingers: true, wheel: true },
    })

    board.on('down', function (e) {
      handleDown(e)
    })
  }

  function handleDown(e) {
    var coords = getCoords(e)
    if (!coords) return

    var x = coords[0]
    var y = coords[1]

    if (mode === 'point') {
      createPoint(x, y)
    } else if (mode === 'line') {
      handleLinePoint(x, y)
    } else if (mode === 'circle') {
      createCircle(x, y)
    }
  }

  function getCoords(e) {
    if (!board) return null
    try {
      var coords = board.getUsrCoordsOfMouse(e)
      return coords
    } catch (err) {
      return null
    }
  }

  function createPoint(x, y) {
    var id = 'P' + (++pointCount)
    var p = board.create('point', [x, y], {
      name: id,
      size: 5,
      fillColor: '#3F51B5',
      strokeColor: '#3F51B5',
      fixed: false,
    })
  }

  function handleLinePoint(x, y) {
    tempLinePoints.push([x, y])

    if (tempLinePoints.length === 1) {
      var p = board.create('point', [x, y], {
        name: '起点',
        size: 5,
        fillColor: '#FF7043',
        strokeColor: '#FF7043',
        fixed: true,
      })
      tempLinePreview = p
    } else if (tempLinePoints.length === 2) {
      var p1 = tempLinePoints[0]
      var p2 = tempLinePoints[1]
      board.create('line', [p1, p2], {
        strokeColor: '#3d7bfd',
        straightFirst: true,
        straightLast: true,
        fixed: false,
      })
      if (tempLinePreview) {
        board.removeObject(tempLinePreview)
        tempLinePreview = null
      }
      tempLinePoints = []
      setMode('select')
    }
  }

  function createCircle(x, y) {
    board.create('circle', [[x, y], [x + 1, y + 1]], {
      strokeColor: '#1f78b4',
      fillColor: '#a6cee3',
      fillOpacity: 0.15,
    })
    setMode('select')
  }

  function deleteSelected() {
    var hit = findHitElement()
    if (hit) {
      board.removeObject(hit)
    }
  }

  function findHitElement() {
    var objects = board.objectsList
    for (var i = objects.length - 1; i >= 0; i--) {
      var obj = objects[i]
      if (obj && obj.elType && obj.elType !== 'axis' && obj.elType !== 'ticks' && obj.visProp && obj.visProp.highlighted) {
        return obj
      }
    }
    return null
  }

  function clearAll() {
    if (!board) return
    var objects = board.objectsList
    for (var i = objects.length - 1; i >= 0; i--) {
      var obj = objects[i]
      if (obj && obj.elType && obj.elType !== 'axis') {
        try {
          board.removeObject(obj)
        } catch (e) {}
      }
    }
    pointCount = 0
    tempLinePoints = []
    tempLinePreview = null
  }

  function setMode(newMode) {
    mode = newMode
    tempLinePoints = []
    if (tempLinePreview) {
      try {
        board.removeObject(tempLinePreview)
      } catch (e) {}
      tempLinePreview = null
    }

    var buttons = document.querySelectorAll('#toolbar button')
    buttons.forEach(function (btn) {
      btn.classList.remove('active')
    })

    switch (mode) {
      case 'select':
        document.getElementById('btn-select').classList.add('active')
        break
      case 'point':
        document.getElementById('btn-point').classList.add('active')
        break
      case 'line':
        document.getElementById('btn-line').classList.add('active')
        break
      case 'circle':
        document.getElementById('btn-circle').classList.add('active')
        break
    }
  }

  function setupToolbar() {
    document.getElementById('btn-select').addEventListener('click', function () { setMode('select') })
    document.getElementById('btn-point').addEventListener('click', function () { setMode('point') })
    document.getElementById('btn-line').addEventListener('click', function () { setMode('line') })
    document.getElementById('btn-circle').addEventListener('click', function () { setMode('circle') })
    document.getElementById('btn-delete').addEventListener('click', function () { deleteSelected() })
    document.getElementById('btn-clear').addEventListener('click', function () { clearAll() })
  }

  document.addEventListener('DOMContentLoaded', function () {
    initBoard()
    setupToolbar()
  })

  postMessage({ type: 'renderReady' })
})()
