const defaults = {
  fg: "#FFF",
  bg: "#000",
  newline: !1,
  stream: !1,
  colors: getDefaultColors()
}

function getDefaultColors() {
  const a = {
    0: "#000",
    1: "#A00",
    2: "#0A0",
    3: "#A50",
    4: "#00A",
    5: "#A0A",
    6: "#0AA",
    7: "#AAA",
    8: "#555",
    9: "#F55",
    10: "#5F5",
    11: "#FF5",
    12: "#55F",
    13: "#F5F",
    14: "#5FF",
    15: "#FFF"
  }
  return range(0, 5).forEach(b => {
    range(0, 5).forEach(c => {
      range(0, 5).forEach(d => setStyleColor(b, c, d, a))
    })
  }), range(0, 23).forEach(function (b) {
    const c = toHexString(10 * b + 8)
    a[b + 232] = "#" + c + c + c
  }), a
}

function setStyleColor(a, c, d, e) {
  const f = 0 < a ? 40 * a + 55 : 0,
    h = 0 < c ? 40 * c + 55 : 0,
    g = 0 < d ? 40 * d + 55 : 0
  e[16 + 36 * a + 6 * c + d] = toColorHexString([f, h, g])
}

function toHexString(a) {
  let b = a.toString(16)
  for (; 2 > b.length;) b = "0" + b
  return b
}

function toColorHexString(a) {
  const b = []
  for (const c of a) b.push(toHexString(c))
  return "#" + b.join("")
}

function generateOutput(a, b, c, d) {
  let e
  return "text" === b ? e = pushText(c, d) : "display" === b ? e = handleDisplay(a, c, d) : "xterm256Foreground" === b ? e = pushForegroundColor(a, d.colors[c]) : "xterm256Background" === b ? e = pushBackgroundColor(a, d.colors[c]) : "rgb" == b && (e = handleRgb(a, c)), e
}

function handleRgb(a, b) {
  b = b.substring(2).slice(0, -1)
  const c = +b.substr(0, 2),
    d = b.substring(5).split(";"),
    e = d.map(function (a) {
      return ("0" + (+a).toString(16)).substr(-2)
    }).join("")
  return pushStyle(a, (38 == c ? "color:#" : "background-color:#") + e)
}

function handleDisplay(a, b, c) {
  b = parseInt(b, 10)
  const d = {
    "-1": () => "<br/>",
    0: () => a.length && resetStyles(a),
    1: () => pushTag(a, "b"),
    3: () => pushTag(a, "i"),
    4: () => pushTag(a, "u"),
    8: () => pushStyle(a, "display:none"),
    9: () => pushTag(a, "strike"),
    22: () => pushStyle(a, "font-weight:normal;text-decoration:none;font-style:normal"),
    23: () => closeTag(a, "i"),
    24: () => closeTag(a, "u"),
    39: () => pushForegroundColor(a, c.fg),
    49: () => pushBackgroundColor(a, c.bg),
    53: () => pushStyle(a, "text-decoration:overline")
  }
  let e
  return d[b] ? e = d[b]() : 4 < b && 7 > b ? e = pushTag(a, "blink") : 29 < b && 38 > b ? e = pushForegroundColor(a, c.colors[b - 30]) : 39 < b && 48 > b ? e = pushBackgroundColor(a, c.colors[b - 40]) : 89 < b && 98 > b ? e = pushForegroundColor(a, c.colors[8 + (b - 90)]) : 99 < b && 108 > b && (e = pushBackgroundColor(a, c.colors[8 + (b - 100)])), e
}

function resetStyles(a) {
  const b = a.slice(0)
  return a.length = 0, b.reverse().map(function (a) {
    return "</" + a + ">"
  }).join("")
}

function range(a, b) {
  const c = []
  for (let d = a; d <= b; d++) c.push(d)
  return c
}

function notCategory(a) {
  return function (b) {
    return (null === a || b.category !== a) && "all" !== a
  }
}

function categoryForCode(a) {
  a = parseInt(a, 10)
  let b = null
  return 0 === a ? b = "all" : 1 === a ? b = "bold" : 2 < a && 5 > a ? b = "underline" : 4 < a && 7 > a ? b = "blink" : 8 === a ? b = "hide" : 9 === a ? b = "strike" : 29 < a && 38 > a || 39 === a || 89 < a && 98 > a ? b = "foreground-color" : (39 < a && 48 > a || 49 === a || 99 < a && 108 > a) && (b = "background-color"), b
}

function pushText(a) {
  return a
}

function pushTag(a, b, c) {
  return c || (c = ""), a.push(b), `<${b}${c ? ` style="${c}"` : ""}>`
}

function pushStyle(a, b) {
  return pushTag(a, "span", b)
}

function pushForegroundColor(a, b) {
  return pushTag(a, "span", "color:" + b)
}

function pushBackgroundColor(a, b) {
  return pushTag(a, "span", "background-color:" + b)
}

function closeTag(a, b) {
  let c
  if (a.slice(-1)[0] === b && (c = a.pop()), c) return "</" + b + ">"
}

function tokenize(a, b, c) {
  function d() {
    return ""
  }

  function e(a) {
    return b.newline ? c("display", -1) : c("text", a), ""
  }

  function f(b, c) {
    c > h && g || (g = !1, a = a.replace(b.pattern, b.sub))
  }
  let g = !1
  const h = 3,
    j = [{
      pattern: /^\x08+/,
      sub: d
    }, {
      pattern: /^\x1b\[[012]?K/,
      sub: d
    }, {
      pattern: /^\x1b\[\(B/,
      sub: d
    }, {
      pattern: /^\x1b\[[34]8;2;\d+;\d+;\d+m/,
      sub: function (a) {
        return c("rgb", a), ""
      }
    }, {
      pattern: /^\x1b\[38;5;(\d+)m/,
      sub: function (a, b) {
        return c("xterm256Foreground", b), ""
      }
    }, {
      pattern: /^\x1b\[48;5;(\d+)m/,
      sub: function (a, b) {
        return c("xterm256Background", b), ""
      }
    }, {
      pattern: /^\n/,
      sub: e
    }, {
      pattern: /^\r+\n/,
      sub: e
    }, {
      pattern: /^\r/,
      sub: e
    }, {
      pattern: /^\x1b\[((?:\d{1,3};?)+|)m/,
      sub: function (a, b) {
        g = !0, 0 === b.trim().length && (b = "0"), b = b.trimRight(";").split(";")
        for (const d of b) c("display", d)
        return ""
      }
    }, {
      pattern: /^\x1b\[\d?J/,
      sub: d
    }, {
      pattern: /^\x1b\[\d{0,3};\d{0,3}f/,
      sub: d
    }, {
      pattern: /^\x1b\[?[\d;]{0,3}/,
      sub: d
    }, {
      pattern: /^(([^\x1b\x08\r\n])+)/,
      sub: function (a) {
        return c("text", a), ""
      }
    }],
    k = []
  let {
    length: l
  } = a
  outer: for (; 0 < l;) {
    for (let b = 0, c = 0, d = j.length; c < d; b = ++c) {
      const c = j[b]
      if (f(c, b), a.length !== l) {
        l = a.length
        continue outer
      }
    }
    if (a.length === l) break
    k.push(0), l = a.length
  }
  return k
}

function updateStickyStack(a, b, c) {
  return "text" !== b && (a = a.filter(notCategory(categoryForCode(c))), a.push({
    token: b,
    data: c,
    category: categoryForCode(c)
  })), a
}
class Filter {
  constructor(a) {
    a = a || {}, a.colors && (a.colors = Object.assign({}, defaults.colors, a.colors)), this.options = Object.assign({}, defaults, a), this.stack = [], this.stickyStack = []
  }
  toHtml(a) {
    a = "string" == typeof a ? [a] : a
    const {
      stack: b,
      options: c
    } = this, d = []
    return this.stickyStack.forEach(a => {
      const e = generateOutput(b, a.token, a.data, c)
      e && d.push(e)
    }), tokenize(a.join(""), c, (a, e) => {
      const f = generateOutput(b, a, e, c)
      f && d.push(f), c.stream && (this.stickyStack = updateStickyStack(this.stickyStack, a, e))
    }), b.length && d.push(resetStyles(b)), d.join("")
  }
}
export default new Filter