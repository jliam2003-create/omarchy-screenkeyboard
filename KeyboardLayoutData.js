.pragma library

function charKey(normal, shifted, width) {
  var isAlpha = normal.length === 1 && normal >= "a" && normal <= "z"
  return {
    kind: "char",
    label: isAlpha ? normal.toUpperCase() : normal,
    subLabel: isAlpha ? "" : (shifted || ""),
    char: normal,
    shiftChar: shifted || normal.toUpperCase(),
    isLetter: isAlpha,
    w: width || 1.0,
    repeatable: true
  }
}

function namedKey(label, xkbName, width, repeatable, accentRole) {
  return {
    kind: "named",
    label: label,
    subLabel: "",
    named: xkbName,
    w: width || 1.0,
    repeatable: repeatable !== undefined ? repeatable : true,
    role: accentRole || "action"
  }
}

function modKey(label, modName, width) {
  return {
    kind: "mod",
    label: label,
    subLabel: "",
    mod: modName,
    w: width || 1.25,
    repeatable: false,
    role: "mod"
  }
}

var fullRows = [
  [
    namedKey("Esc", "Escape", 1.1, false, "esc"),
    namedKey("F1", "F1", 1.0, false),
    namedKey("F2", "F2", 1.0, false),
    namedKey("F3", "F3", 1.0, false),
    namedKey("F4", "F4", 1.0, false),
    namedKey("F5", "F5", 1.0, false),
    namedKey("F6", "F6", 1.0, false),
    namedKey("F7", "F7", 1.0, false),
    namedKey("F8", "F8", 1.0, false),
    namedKey("F9", "F9", 1.0, false),
    namedKey("F10", "F10", 1.0, false),
    namedKey("F11", "F11", 1.0, false),
    namedKey("F12", "F12", 1.0, false),
    namedKey("Del", "Delete", 1.15, true),
    namedKey("Home", "Home", 1.15, false),
    namedKey("End", "End", 1.1, false)
  ],
  [
    charKey("`", "~", 1.0),
    charKey("1", "!", 1.0),
    charKey("2", "@", 1.0),
    charKey("3", "#", 1.0),
    charKey("4", "$", 1.0),
    charKey("5", "%", 1.0),
    charKey("6", "^", 1.0),
    charKey("7", "&", 1.0),
    charKey("8", "*", 1.0),
    charKey("9", "(", 1.0),
    charKey("0", ")", 1.0),
    charKey("-", "_", 1.0),
    charKey("=", "+", 1.0),
    namedKey("⌫ Back", "BackSpace", 2.5, true)
  ],
  [
    namedKey("Tab ⇥", "Tab", 1.5, true),
    charKey("q", "Q", 1.0),
    charKey("w", "W", 1.0),
    charKey("e", "E", 1.0),
    charKey("r", "R", 1.0),
    charKey("t", "T", 1.0),
    charKey("y", "Y", 1.0),
    charKey("u", "U", 1.0),
    charKey("i", "I", 1.0),
    charKey("o", "O", 1.0),
    charKey("p", "P", 1.0),
    charKey("[", "{", 1.0),
    charKey("]", "}", 1.0),
    charKey("\\", "|", 1.0),
    namedKey("PgUp", "Prior", 1.0, true)
  ],
  [
    modKey("Caps", "caps", 1.75),
    charKey("a", "A", 1.0),
    charKey("s", "S", 1.0),
    charKey("d", "D", 1.0),
    charKey("f", "F", 1.0),
    charKey("g", "G", 1.0),
    charKey("h", "H", 1.0),
    charKey("j", "J", 1.0),
    charKey("k", "K", 1.0),
    charKey("l", "L", 1.0),
    charKey(";", ":", 1.0),
    charKey("'", "\"", 1.0),
    namedKey("↵ Enter", "Return", 1.75, true, "enter"),
    namedKey("PgDn", "Next", 1.0, true)
  ],
  [
    modKey("⇧ Shift", "shift", 2.15),
    charKey("z", "Z", 1.0),
    charKey("x", "X", 1.0),
    charKey("c", "C", 1.0),
    charKey("v", "V", 1.0),
    charKey("b", "B", 1.0),
    charKey("n", "N", 1.0),
    charKey("m", "M", 1.0),
    charKey(",", "<", 1.0),
    charKey(".", ">", 1.0),
    charKey("/", "?", 1.0),
    modKey("⇧ Shift", "shift", 1.35),
    namedKey("↑", "Up", 1.0, true),
    namedKey("Del", "Delete", 1.0, true)
  ],
  [
    modKey("Ctrl", "ctrl", 1.4),
    modKey("Super", "logo", 1.35),
    modKey("Alt", "alt", 1.35),
    namedKey("Space", "space", 6.0, true),
    modKey("Alt", "alt", 1.2),
    modKey("Ctrl", "ctrl", 1.2),
    namedKey("←", "Left", 1.0, true),
    namedKey("↓", "Down", 1.0, true),
    namedKey("→", "Right", 1.0, true)
  ]
]

var compactRows = [
  [
    namedKey("Esc", "Escape", 1.15, false, "esc"),
    charKey("1", "!", 1.0),
    charKey("2", "@", 1.0),
    charKey("3", "#", 1.0),
    charKey("4", "$", 1.0),
    charKey("5", "%", 1.0),
    charKey("6", "^", 1.0),
    charKey("7", "&", 1.0),
    charKey("8", "*", 1.0),
    charKey("9", "(", 1.0),
    charKey("0", ")", 1.0),
    charKey("-", "_", 1.0),
    namedKey("⌫", "BackSpace", 1.6, true)
  ],
  [
    namedKey("Tab", "Tab", 1.35, true),
    charKey("q", "Q", 1.0),
    charKey("w", "W", 1.0),
    charKey("e", "E", 1.0),
    charKey("r", "R", 1.0),
    charKey("t", "T", 1.0),
    charKey("y", "Y", 1.0),
    charKey("u", "U", 1.0),
    charKey("i", "I", 1.0),
    charKey("o", "O", 1.0),
    charKey("p", "P", 1.0),
    charKey("[", "{", 1.0),
    charKey("]", "}", 1.0),
    charKey("\\", "|", 1.4)
  ],
  [
    modKey("Caps", "caps", 1.65),
    charKey("a", "A", 1.0),
    charKey("s", "S", 1.0),
    charKey("d", "D", 1.0),
    charKey("f", "F", 1.0),
    charKey("g", "G", 1.0),
    charKey("h", "H", 1.0),
    charKey("j", "J", 1.0),
    charKey("k", "K", 1.0),
    charKey("l", "L", 1.0),
    charKey(";", ":", 1.0),
    charKey("'", "\"", 1.0),
    namedKey("↵ Enter", "Return", 2.1, true, "enter")
  ],
  [
    modKey("⇧ Shift", "shift", 2.1),
    charKey("z", "Z", 1.0),
    charKey("x", "X", 1.0),
    charKey("c", "C", 1.0),
    charKey("v", "V", 1.0),
    charKey("b", "B", 1.0),
    charKey("n", "N", 1.0),
    charKey("m", "M", 1.0),
    charKey(",", "<", 1.0),
    charKey(".", ">", 1.0),
    charKey("/", "?", 1.0),
    namedKey("↑", "Up", 1.1, true),
    modKey("⇧", "shift", 1.55)
  ],
  [
    modKey("Ctrl", "ctrl", 1.4),
    modKey("Super", "logo", 1.3),
    modKey("Alt", "alt", 1.3),
    charKey("`", "~", 1.0),
    namedKey("Space", "space", 4.95, true),
    charKey("=", "+", 1.0),
    namedKey("←", "Left", 1.1, true),
    namedKey("↓", "Down", 1.1, true),
    namedKey("→", "Right", 1.1, true)
  ]
]

var numpadRows = [
  [
    charKey("7", "7", 1.0),
    charKey("8", "8", 1.0),
    charKey("9", "9", 1.0),
    charKey("/", "/", 1.0),
    charKey("(", "(", 1.0),
    charKey(")", ")", 1.0),
    namedKey("⌫ Back", "BackSpace", 1.6, true)
  ],
  [
    charKey("4", "4", 1.0),
    charKey("5", "5", 1.0),
    charKey("6", "6", 1.0),
    charKey("*", "*", 1.0),
    charKey("[", "[", 1.0),
    charKey("]", "]", 1.0),
    namedKey("Tab ⇥", "Tab", 1.6, true)
  ],
  [
    charKey("1", "1", 1.0),
    charKey("2", "2", 1.0),
    charKey("3", "3", 1.0),
    charKey("-", "-", 1.0),
    charKey("{", "{", 1.0),
    charKey("}", "}", 1.0),
    namedKey("↑", "Up", 1.6, true)
  ],
  [
    charKey("0", "0", 2.08),
    charKey(".", ".", 1.0),
    charKey("+", "+", 1.0),
    charKey("=", "=", 1.0),
    namedKey("←", "Left", 1.0, true),
    namedKey("↓", "Down", 1.0, true),
    namedKey("→", "Right", 1.0, true)
  ],
  [
    charKey("$", "$", 1.0),
    charKey("%", "%", 1.0),
    charKey("_", "_", 1.0),
    charKey(":", ":", 1.0),
    namedKey("Space", "space", 1.9, true),
    namedKey("↵ Enter", "Return", 1.7, true, "enter")
  ]
]

function rowsForLayout(mode) {
  if (mode === "compact") return compactRows
  if (mode === "numpad") return numpadRows
  return fullRows
}

function displayLabel(keySpec, shiftActive, capsActive) {
  if (!keySpec) return ""
  if (keySpec.kind === "char") {
    if (keySpec.isLetter) {
      var upper = (!!shiftActive) !== (!!capsActive)
      return upper ? keySpec.shiftChar : keySpec.char
    }
    return shiftActive ? keySpec.shiftChar : keySpec.char
  }
  return keySpec.label || ""
}
