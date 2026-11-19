import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "KeyboardLayoutData.js" as LayoutData

Item {
  id: root

  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  // Lock screen on-screen keyboard state
  property bool oskOpen: false
  property bool oskAutoPop: true
  property string oskLayoutMode: "full"
  property string oskSizePreset: "md"
  property bool oskShift: false
  property bool oskCaps: false
  property bool oskHasDragged: false
  property real oskDragX: 0
  property real oskDragY: 0
  property Item heldKeyItem: null
  property var heldKeySpec: null

  readonly property string stateFilePath: Quickshell.env("HOME") + "/.local/state/omarchy/screenkeyboard.json"
  readonly property real oskScale: oskSizePreset === "sm" ? 0.86 : (oskSizePreset === "lg" ? 1.14 : 1.0)
  readonly property int oskUnitWidth: Math.round(Style.space(44) * oskScale)
  readonly property int oskKeyHeight: Math.round(Style.space(40) * oskScale)
  readonly property int oskKeyGap: Style.space(5)
  readonly property int oskCardPad: Style.space(12)
  readonly property int oskHeaderHeight: Style.space(32)
  readonly property var oskActiveRows: LayoutData.rowsForLayout(root.oskLayoutMode)

  readonly property int oskRowsMaxWidth: {
    var rows = root.oskActiveRows
    var widest = 0
    for (var r = 0; r < rows.length; r++) {
      var row = rows[r]
      var w = 0
      for (var k = 0; k < row.length; k++) {
        w += Math.round(row[k].w * root.oskUnitWidth)
      }
      if (row.length > 1) w += (row.length - 1) * root.oskKeyGap
      if (w > widest) widest = w
    }
    return widest
  }

  readonly property string placeholderText: Commons.I18n.t("lock.enterPassword")
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Commons.Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Commons.Color.lock.borderActive, root.outlineThickness, "border-alpha")

  // A video wallpaper shows its still poster: nothing plays behind the lock.
  readonly property bool video: Util.isVideoPath(root.backgroundPath)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  FileView {
    id: oskStateFile
    path: root.stateFilePath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyOskState(text())
    onFileChanged: reload()
  }

  function applyOskState(raw) {
    if (!raw) return
    try {
      var parsed = JSON.parse(raw)
      if (parsed && typeof parsed === "object") {
        if (parsed.autoPop !== undefined) root.oskAutoPop = parsed.autoPop !== false
        if (parsed.layout) root.oskLayoutMode = String(parsed.layout)
        if (parsed.size) root.oskSizePreset = String(parsed.size)
      }
    } catch (e) {}
  }

  function saveOskState() {
    var payload = JSON.stringify({
      autoPop: root.oskAutoPop,
      layout: root.oskLayoutMode,
      size: root.oskSizePreset,
      position: "bottom"
    })
    Quickshell.execDetached([
      "python3", "-c",
      "import os, sys; p = sys.argv[1]; os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(sys.argv[2])",
      root.stateFilePath,
      payload
    ])
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function triggerLockKey(keySpec, isRepeat) {
    if (!keySpec) return
    root.wakeRequested()
    root.forcePasswordFocus()

    if (keySpec.kind === "mod") {
      if (!isRepeat) {
        if (keySpec.mod === "shift") root.oskShift = !root.oskShift
        else if (keySpec.mod === "caps") root.oskCaps = !root.oskCaps
      }
      return
    }

    if (!root.inputEnabled || root.authenticatingPassword) return

    if (keySpec.kind === "named") {
      var name = keySpec.named
      if (name === "BackSpace" || name === "Delete") {
        if (root.passwordText.length > 0) {
          root.passwordTextEdited(root.passwordText.slice(0, -1))
        }
      } else if (name === "Escape") {
        root.passwordTextEdited("")
      } else if (name === "Return") {
        var submitted = root.passwordText
        root.passwordTextEdited("")
        if (submitted.length > 0) root.submitPassword(submitted)
      } else if (name === "space") {
        if (root.failureMessage.length > 0) root.clearFailureRequested()
        root.passwordTextEdited(root.passwordText + " ")
      }
      if (!isRepeat && root.oskShift) root.oskShift = false
      return
    }

    if (keySpec.kind === "char") {
      var ch = LayoutData.displayLabel(keySpec, root.oskShift, root.oskCaps)
      if (ch.length > 0) {
        if (root.failureMessage.length > 0) root.clearFailureRequested()
        root.passwordTextEdited(root.passwordText + ch)
      }
      if (!isRepeat && root.oskShift) root.oskShift = false
    }
  }

  function startLockRepeat(keyItem) {
    root.stopLockRepeat()
    if (!keyItem || !keyItem.keySpec || !keyItem.keySpec.repeatable) return
    root.heldKeyItem = keyItem
    root.heldKeySpec = keyItem.keySpec
    lockRepeatDelayTimer.restart()
  }

  function stopLockRepeat(keyItem) {
    if (keyItem && root.heldKeyItem && root.heldKeyItem !== keyItem) return
    lockRepeatDelayTimer.stop()
    lockRepeatTimer.stop()
    root.heldKeyItem = null
    root.heldKeySpec = null
  }

  onOskOpenChanged: {
    if (!root.oskOpen) root.stopLockRepeat()
  }

  onOskLayoutModeChanged: {
    root.stopLockRepeat()
  }

  Timer {
    id: lockRepeatDelayTimer
    interval: 400
    repeat: false
    onTriggered: {
      if (root.heldKeyItem && root.heldKeyItem.isPressed && root.heldKeySpec && root.heldKeySpec.repeatable && root.oskOpen && root.inputEnabled) {
        lockRepeatTimer.start()
      } else {
        root.stopLockRepeat()
      }
    }
  }

  Timer {
    id: lockRepeatTimer
    interval: 60
    repeat: true
    onTriggered: {
      if (root.heldKeyItem && root.heldKeyItem.isPressed && root.heldKeySpec && root.heldKeySpec.repeatable && root.oskOpen && root.inputEnabled) {
        root.triggerLockKey(root.heldKeySpec, true)
      } else {
        root.stopLockRepeat()
      }
    }
  }

  // Waking a DPMS-blanked display can stall the compositor for seconds while
  // the monitor modesets, so the wake key's release arrives late and client-side
  // key repeat floods the field with that character. A held key has no business
  // typing a password; only holding Backspace/Delete to clear stays useful.
  function dropsAutoRepeat(key) {
    return key !== Qt.Key_Backspace && key !== Qt.Key_Delete
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  // The field loses focus while a password is checked (it is disabled then),
  // and forcing focus onto it would not stick until the check ends.
  function restorePasswordFocus() {
    if (inputEnabled && passwordInput.enabled && !passwordInput.activeFocus) forcePasswordFocus()
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) {
      if (root.oskAutoPop) root.oskOpen = true
      Qt.callLater(forcePasswordFocus)
    } else {
      root.stopLockRepeat()
    }
  }

  // A VT switch, which the NVIDIA driver forces around every suspend, takes the
  // keyboard away and Qt drops the field's focus with it. Nothing gives it back
  // when the keyboard returns, so typing went nowhere until the field was clicked.
  Window.onActiveFocusItemChanged: Qt.callLater(restorePasswordFocus)
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) {
      if (root.oskAutoPop) root.oskOpen = true
      Qt.callLater(forcePasswordFocus)
    }
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    BackgroundMedia {
      id: wallpaper
      objectName: "lockWallpaper"
      anchors.fill: parent
      path: root.loadBackground ? (root.video ? root.videoPosterPath : root.backgroundPath) : ""
      version: root.backgroundVersion
      cached: true
      constrainDecode: true
      decodeSize: Qt.size(width, height)
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.horizontalCenter: parent.horizontalCenter
      // Lift the password field slightly when the on-screen keyboard is open
      // on shorter screens so the keyboard never overlaps the password field.
      y: root.oskOpen
        ? Math.min(Math.round((parent.height - height) / 2), Math.max(Style.space(48), lockOskCard.y - height - Style.space(36)))
        : Math.round((parent.height - height) / 2)
      color: Commons.Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: Style.cornerRadius
      clip: true

      Behavior on y {
        NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic }
      }

      // Passive TapHandler so clicking the password box auto-pops the keyboard
      // when auto-pop is enabled without stealing pointer focus from TextInput.
      TapHandler {
        onTapped: {
          root.wakeRequested()
          root.forcePasswordFocus()
          if (root.oskAutoPop && !root.oskOpen) {
            root.oskOpen = true
          }
        }
      }

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Commons.Color.lock.text
        selectionColor: Commons.Color.lock.selection
        selectedTextColor: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Commons.Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.isAutoRepeat && root.dropsAutoRepeat(event.key)) {
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? Commons.I18n.t("lock.checking") : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Commons.Color.lock.text : (root.failureMessage.length > 0 ? Commons.Color.lock.textError : Commons.Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: root.fingerprintUnavailable ? "󰺱" : "󰈷"
        color: root.fingerprintUnavailable ? Commons.Color.lock.textError : Commons.Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    // On-screen keyboard toggle button right beside the password field
    BorderSurface {
      id: oskToggleButton
      width: root.fieldHeight
      height: root.fieldHeight
      anchors.left: inputField.right
      anchors.leftMargin: Style.space(12)
      anchors.verticalCenter: inputField.verticalCenter
      color: oskToggleMouse.pressed
        ? Util.alpha(Commons.Color.accent, 0.28)
        : (root.oskOpen
            ? Util.alpha(Commons.Color.accent, 0.18)
            : Commons.Color.lock.background)
      borderSpec: root.oskOpen || oskToggleMouse.containsMouse
        ? Border.surfaceSpec("lock", "border-active", Commons.Color.lock.borderActive, root.outlineThickness, "border-alpha")
        : Border.surfaceSpec("lock", "border", Commons.Color.lock.border, root.outlineThickness, "border-alpha")
      radius: Style.cornerRadius

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: "󰌌"
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.15)
        color: root.oskOpen ? Commons.Color.accent : Commons.Color.lock.text
      }

      MouseArea {
        id: oskToggleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.wakeRequested()
          root.oskOpen = !root.oskOpen
          root.forcePasswordFocus()
        }
      }
    }

    Text {
      objectName: "fingerprintUnavailableNotice"
      textFormat: Text.PlainText
      anchors.top: inputField.bottom
      anchors.topMargin: 18
      anchors.horizontalCenter: inputField.horizontalCenter
      visible: root.fingerprintConfigured && root.fingerprintUnavailable
      text: Commons.I18n.t("lock.fingerprintUnavailable")
      color: Commons.Color.lock.textError
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.italic: true
      horizontalAlignment: Text.AlignHCenter
    }

    // Lockscreen On-Screen Keyboard Card
    BorderSurface {
      id: lockOskCard
      visible: root.oskOpen || opacity > 0

      readonly property int innerWidth: root.oskRowsMaxWidth
      readonly property int innerHeight: root.oskHeaderHeight + Style.space(8)
        + root.oskActiveRows.length * root.oskKeyHeight
        + Math.max(0, root.oskActiveRows.length - 1) * root.oskKeyGap

      width: borderLeft + root.oskCardPad * 2 + innerWidth + borderRight
      height: borderTop + root.oskCardPad * 2 + innerHeight + borderBottom

      x: root.oskHasDragged
        ? Math.max(Style.space(8), Math.min(root.width - width - Style.space(8), root.oskDragX))
        : Math.round((root.width - width) / 2)
      y: root.oskHasDragged
        ? Math.max(Style.space(8), Math.min(root.height - height - Style.space(8), root.oskDragY))
        : Math.max(Style.space(16), root.height - height - Style.space(28))

      color: Util.alpha(Commons.Color.popups.background, 0.96)
      borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.normalBorderWidth))
      radius: Style.cornerRadius

      opacity: root.oskOpen ? 1 : 0
      scale: root.oskOpen ? 1 : 0.97

      Behavior on opacity {
        NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: Style.duration(160); easing.type: Easing.Bezier; easing.bezierCurve: Style.easeOut }
      }

      // Swallow background clicks on the keyboard card
      MouseArea {
        anchors.fill: parent
        onPressed: {
          root.wakeRequested()
          root.forcePasswordFocus()
        }
      }

      Column {
        id: lockOskBody
        x: lockOskCard.borderLeft + root.oskCardPad
        y: lockOskCard.borderTop + root.oskCardPad
        width: lockOskCard.innerWidth
        spacing: Style.space(8)

        // Header bar
        Item {
          width: parent.width
          height: root.oskHeaderHeight

          MouseArea {
            anchors.fill: parent
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property point startMouse
            property real startCardX: 0
            property real startCardY: 0

            onPressed: function(mouse) {
              root.wakeRequested()
              startMouse = mapToItem(root, mouse.x, mouse.y)
              startCardX = lockOskCard.x
              startCardY = lockOskCard.y
            }
            onPositionChanged: function(mouse) {
              if (!pressed) return
              root.wakeRequested()
              var p = mapToItem(root, mouse.x, mouse.y)
              var dx = p.x - startMouse.x
              var dy = p.y - startMouse.y
              if (!root.oskHasDragged && Math.hypot(dx, dy) < Style.space(4)) return
              root.oskHasDragged = true
              root.oskDragX = startCardX + dx
              root.oskDragY = startCardY + dy
            }
            onDoubleClicked: {
              root.oskHasDragged = false
            }
          }

          RowLayout {
            anchors.fill: parent
            spacing: Style.space(8)

            Row {
              spacing: Style.space(6)
              Layout.alignment: Qt.AlignVCenter

              Text {
                textFormat: Text.PlainText
                text: "󰌌"
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                color: Commons.Color.accent
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                textFormat: Text.PlainText
                text: "Screen Keyboard"
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.weight: Font.Bold
                color: Commons.Color.popups.text
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                textFormat: Text.PlainText
                text: "⋮⋮"
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                color: Commons.Color.muted
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Item { Layout.fillWidth: true }

            // Auto-Pop toggle pill
            LockHeaderPill {
              Layout.alignment: Qt.AlignVCenter
              label: root.oskAutoPop ? "Auto: ON" : "Auto: OFF"
              active: root.oskAutoPop
              onClicked: {
                root.wakeRequested()
                root.oskAutoPop = !root.oskAutoPop
                root.saveOskState()
              }
            }

            // Layout switcher pills
            Row {
              spacing: Style.space(4)
              Layout.alignment: Qt.AlignVCenter

              Repeater {
                model: [
                  { id: "full", label: "Full" },
                  { id: "compact", label: "Compact" },
                  { id: "numpad", label: "Numpad" }
                ]
                delegate: LockHeaderPill {
                  required property var modelData
                  label: modelData.label
                  active: root.oskLayoutMode === modelData.id
                  onClicked: {
                    root.wakeRequested()
                    root.oskLayoutMode = modelData.id
                    root.saveOskState()
                  }
                }
              }
            }

            // Close button
            LockHeaderPill {
              Layout.alignment: Qt.AlignVCenter
              label: "✕"
              isClose: true
              onClicked: {
                root.wakeRequested()
                root.oskOpen = false
              }
            }
          }
        }

        // Keyboard rows
        Column {
          width: parent.width
          spacing: root.oskKeyGap

          Repeater {
            model: root.oskActiveRows

            delegate: Row {
              id: lockKeyRow
              required property var modelData
              required property int index

              spacing: root.oskKeyGap
              anchors.horizontalCenter: parent.horizontalCenter

              Repeater {
                model: lockKeyRow.modelData

                delegate: LockVirtualKey {
                  required property var modelData
                  keySpec: modelData
                }
              }
            }
          }
        }
      }
    }
  }

  component LockHeaderPill: Rectangle {
    id: pill
    property string label: ""
    property bool active: false
    property bool isClose: false
    signal clicked()

    width: Math.max(Style.space(26), pillText.implicitWidth + Style.space(14))
    height: Style.space(24)
    radius: Math.min(Style.space(4), Style.cornerRadius)
    color: pillMouse.pressed
      ? Style.pressedFill
      : (pill.active
          ? Util.alpha(Commons.Color.accent, 0.22)
          : (pillMouse.containsMouse ? Style.hoverFill : Style.normalFill))
    border.width: Style.normalBorderWidth
    border.color: pill.active
      ? Commons.Color.accent
      : (pillMouse.containsMouse ? Style.hoverBorderColor : Style.normalBorderColor)

    Text {
      id: pillText
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: pill.label
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: pill.active ? Font.Bold : Font.Medium
      color: pill.isClose && pillMouse.containsMouse
        ? Commons.Color.urgent
        : (pill.active ? Commons.Color.accent : Commons.Color.popups.text)
    }

    MouseArea {
      id: pillMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }

  component LockVirtualKey: Rectangle {
    id: keyItem
    property var keySpec: ({})
    readonly property bool isPressed: keyMouse.pressed

    Component.onDestruction: root.stopLockRepeat(keyItem)

    readonly property bool isMod: keySpec.kind === "mod"
    readonly property bool modEngaged: isMod && ((keySpec.mod === "shift" && root.oskShift) || (keySpec.mod === "caps" && root.oskCaps))
    readonly property bool isAccentAction: keySpec.role === "enter"
    readonly property bool isEscAction: keySpec.role === "esc"
    readonly property string mainText: LayoutData.displayLabel(keySpec, root.oskShift, root.oskCaps)
    readonly property string secondaryText: (!root.oskShift && keySpec.subLabel) ? keySpec.subLabel : ""

    width: Math.round((keySpec.w || 1.0) * root.oskUnitWidth)
    height: root.oskKeyHeight
    radius: Math.min(Style.space(6), Style.cornerRadius)

    color: {
      if (keyMouse.pressed) return Util.alpha(Commons.Color.accent, 0.38)
      if (modEngaged) return Util.alpha(Commons.Color.accent, 0.25)
      if (isAccentAction) return keyMouse.containsMouse ? Util.alpha(Commons.Color.accent, 0.28) : Util.alpha(Commons.Color.accent, 0.16)
      if (isEscAction) return keyMouse.containsMouse ? Util.alpha(Commons.Color.urgent, 0.24) : Util.alpha(Commons.Color.urgent, 0.12)
      if (keyMouse.containsMouse) return Style.hoverFill
      return Style.normalFill
    }

    border.width: modEngaged || keyMouse.pressed ? Math.max(1, Style.hoverBorderWidth) : Style.normalBorderWidth
    border.color: {
      if (modEngaged || keyMouse.pressed || isAccentAction) return Commons.Color.accent
      if (isEscAction) return Util.alpha(Commons.Color.urgent, 0.65)
      if (keyMouse.containsMouse) return Style.hoverBorderColor
      return Style.normalBorderColor
    }

    scale: keyMouse.pressed ? 0.96 : 1.0
    Behavior on scale {
      NumberAnimation { duration: Style.duration(90); easing.type: Easing.OutCubic }
    }

    Text {
      visible: keyItem.secondaryText !== ""
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: Style.space(3)
      anchors.rightMargin: Style.space(5)
      textFormat: Text.PlainText
      text: keyItem.secondaryText
      font.family: Style.font.family
      font.pixelSize: Math.max(8, Style.font.caption - 1)
      color: Commons.Color.muted
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: keyItem.mainText
      font.family: Style.font.family
      font.pixelSize: keyItem.mainText.length > 2 ? Style.font.bodySmall : Style.font.title
      font.weight: (keyItem.modEngaged || keyItem.isAccentAction) ? Font.Bold : Font.Medium
      color: {
        if (keyItem.modEngaged || keyItem.isAccentAction) return Commons.Color.accent
        if (keyItem.isEscAction) return Commons.Color.urgent
        return Commons.Color.popups.text
      }
    }

    Rectangle {
      visible: keyItem.isMod && (keyItem.keySpec.mod === "shift" || keyItem.keySpec.mod === "caps")
      width: Style.space(5)
      height: Style.space(5)
      radius: width / 2
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.topMargin: Style.space(5)
      anchors.leftMargin: Style.space(5)
      color: keyItem.modEngaged ? Commons.Color.accent : Util.alpha(Commons.Color.muted, 0.35)
    }

    MouseArea {
      id: keyMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: {
        root.triggerLockKey(keyItem.keySpec, false)
        if (keyItem.keySpec && keyItem.keySpec.repeatable) {
          root.startLockRepeat(keyItem)
        } else {
          root.stopLockRepeat()
        }
      }
      onReleased: root.stopLockRepeat(keyItem)
      onCanceled: root.stopLockRepeat(keyItem)
      onPressedChanged: {
        if (!pressed) root.stopLockRepeat(keyItem)
      }
      onContainsMouseChanged: {
        if (!containsMouse) root.stopLockRepeat(keyItem)
      }
    }
  }
}
