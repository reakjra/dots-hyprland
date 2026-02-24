pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    // Original theme-file colors before any overrides are applied
    property var themeColors: ({})
    property bool _wallpaperChanging: false
    property bool _gtkDirty: false
    property bool _hasKdeColors: false
    property bool _pendingOverrideClear: false

    function reapplyTheme() {
        themeFileView.reload()
    }

    function scheduleForceReload() {}

    function applyColors(fileContent) {
        let json
        try { json = JSON.parse(fileContent) } catch (e) {
            return
        }
        const originals = {}
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Terminal keys (term0-15) keep their name, others get m3 prefix
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const propKey = (key.startsWith("term") || key.startsWith("kde") || key.startsWith("gtk")) ? camelCaseKey : `m3${camelCaseKey}`
                Appearance.m3colors[propKey] = json[key]
                originals[propKey] = json[key]
            }
        }
        // Capture defaults for kde* properties not in JSON (before first wallpaper change)
        const kdeKeys = [
            "kdeViewBg", "kdeViewAltBg", "kdeWindowBg", "kdeWindowAltBg",
            "kdeButtonBg", "kdeButtonAltBg", "kdeSelectionBg", "kdeSelectionText",
            "kdeTitlebarBg", "kdeTitlebarText", "kdeInactiveTitlebarBg", "kdeInactiveTitlebarText",
            "kdeViewText", "kdeWindowText", "kdeInactiveText",
            "kdeLinkText", "kdeVisitedText", "kdeErrorText", "kdeWarningText", "kdeSuccessText",
            "kdeAccent",
            "kdeTooltipBg", "kdeTooltipText",
            "kdeComplementaryBg", "kdeComplementaryText"
        ]
        let hasKde = false
        for (const k of kdeKeys) {
            if (k in originals) {
                hasKde = true
            } else {
                originals[k] = Appearance.m3colors[k]
            }
        }
        root._hasKdeColors = hasKde
        if (!hasKde) kdeApplyTimer.stop()
        // GTK fallback defaults
        const gtkDefaults = {
            gtkAccent: "#c9c4d6", gtkAccentFg: "#312f3c",
            gtkWindowBg: "#141315", gtkWindowFg: "#e5e1e3",
            gtkHeaderbarBg: "#141315", gtkHeaderbarFg: "#e5e1e3",
            gtkViewBg: "#141315", gtkViewFg: "#e5e1e3",
            gtkCardBg: "#141315", gtkCardFg: "#e5e1e3",
            gtkPopoverBg: "#141315", gtkPopoverFg: "#e5e1e3",
        }
        for (const k in gtkDefaults) {
            if (!(k in originals)) {
                Appearance.m3colors[k] = gtkDefaults[k]
                originals[k] = gtkDefaults[k]
            }
        }
        root.themeColors = originals
        // Clear overrides HERE (after themeColors is updated) so that any
        // refreshColors() triggered by the clearing uses the NEW themeColors.
        if (root._pendingOverrideClear) {
            root._pendingOverrideClear = false
            if (!ColorOverrideStore.data.preserveOnWallpaperChange) {
                root._wallpaperChanging = true
                root._gtkDirty = false
                ColorOverrideStore.data.colorOverrides = "{}"
                root._wallpaperChanging = false
            }
        }
        applyColorOverrides()
    }

    function applyColorOverrides() {
        const raw = ColorOverrideStore.data?.colorOverrides
        let hasKdeOverride = false
        let hasGtkOverride = false
        if (raw && raw !== "{}") {
            try {
                const overrides = JSON.parse(raw)
                for (const key in overrides) {
                    if (overrides[key]) {
                        Appearance.m3colors[key] = overrides[key]
                        if (key.startsWith("kde")) hasKdeOverride = true
                        if (key.startsWith("gtk")) hasGtkOverride = true
                    }
                }
            } catch (e) {}
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
        terminalApplyTimer.restart()
        if (root._hasKdeColors || hasKdeOverride) kdeApplyTimer.restart()
    }

    function refreshColors() {
        for (const key in root.themeColors) {
            Appearance.m3colors[key] = root.themeColors[key]
        }
        applyColorOverrides()
        if (!root._wallpaperChanging) gtkApplyTimer.restart()
    }

    function applyToActiveTerminals() {
        function toHex6(c) {
            function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
            return h(c.r) + h(c.g) + h(c.b)
        }
        let seq = ""
        for (let i = 0; i < 16; i++) {
            const hex = toHex6(Appearance.m3colors["term" + i])
            seq += `\\x1b]4;${i};#${hex}\\x07`
        }
        const fg = toHex6(Appearance.m3colors.term7)
        const bg = toHex6(Appearance.m3colors.term0)
        seq += `\\x1b]10;#${fg}\\x07`
        seq += `\\x1b]11;#${bg}\\x07`
        const seqFile = `\${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/terminal/sequences.txt`
        Quickshell.execDetached(["bash", "-c",
            `printf '${seq}' > "${seqFile}"; for f in /dev/pts/[0-9]*; do printf '${seq}' > "$f" 2>/dev/null & done`
        ])
    }

    function applyToKdeglobals() {
        function toHex6(c) {
            function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
            return "#" + h(c.r) + h(c.g) + h(c.b)
        }
        function toRgb(c) {
            return `${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)}`
        }
        const allSections = [
            "Colors:View", "Colors:Window", "Colors:Button",
            "Colors:Selection", "Colors:Complementary", "Colors:Header",
            "Colors:Header][Inactive", "Colors:Tooltip"
        ]
        const mapping = {
            kdeViewBg: [["Colors:View", "BackgroundNormal"]],
            kdeViewAltBg: [["Colors:View", "BackgroundAlternate"],
                           ["Colors:Header", "BackgroundAlternate"], ["Colors:Header][Inactive", "BackgroundAlternate"]],
            kdeWindowBg: [["Colors:Window", "BackgroundNormal"],
                          ["Colors:Header", "BackgroundNormal"], ["Colors:Header][Inactive", "BackgroundNormal"]],
            kdeWindowAltBg: [["Colors:Window", "BackgroundAlternate"]],
            kdeButtonBg: [["Colors:Button", "BackgroundNormal"]],
            kdeButtonAltBg: [["Colors:Button", "BackgroundAlternate"]],
            kdeSelectionBg: [["Colors:Selection", "BackgroundNormal"], ["Colors:Selection", "BackgroundAlternate"]],
            kdeSelectionText: [["Colors:Selection", "ForegroundNormal"]],
            kdeTitlebarBg: [["WM", "activeBackground"]],
            kdeTitlebarText: [["WM", "activeForeground"]],
            kdeInactiveTitlebarBg: [["WM", "inactiveBackground"]],
            kdeInactiveTitlebarText: [["WM", "inactiveForeground"]],
            kdeViewText: [["Colors:View", "ForegroundNormal"], ["Colors:Button", "ForegroundNormal"]],
            kdeWindowText: [["Colors:Window", "ForegroundNormal"],
                            ["Colors:Header", "ForegroundNormal"], ["Colors:Header][Inactive", "ForegroundNormal"]],
            kdeTooltipBg: [["Colors:Tooltip", "BackgroundNormal"], ["Colors:Tooltip", "BackgroundAlternate"]],
            kdeTooltipText: [["Colors:Tooltip", "ForegroundNormal"]],
            kdeComplementaryBg: [["Colors:Complementary", "BackgroundNormal"], ["Colors:Complementary", "BackgroundAlternate"]],
            kdeComplementaryText: [["Colors:Complementary", "ForegroundNormal"]],
        }
        const broadKeys = {
            kdeInactiveText: "ForegroundInactive",
            kdeLinkText: "ForegroundLink",
            kdeVisitedText: "ForegroundVisited",
            kdeErrorText: "ForegroundNegative",
            kdeWarningText: "ForegroundNeutral",
            kdeSuccessText: "ForegroundPositive",
        }
        for (const kdeKey in broadKeys) {
            mapping[kdeKey] = allSections.map(s => [s, broadKeys[kdeKey]])
        }
        mapping.kdeAccent = [["General", "AccentColor"]]
        for (const s of allSections) {
            mapping.kdeAccent.push([s, "DecorationFocus"], [s, "DecorationHover"], [s, "ForegroundActive"])
        }

        const colors = {}
        for (const kdeKey in mapping) {
            const color = Appearance.m3colors[kdeKey]
            if (!color) continue
            colors[kdeKey] = { hex: toHex6(color), rgb: toRgb(color) }
        }

        const kdeUpdates = {}
        const schemeUpdates = {}
        for (const kdeKey in mapping) {
            if (!colors[kdeKey]) continue
            const { hex, rgb } = colors[kdeKey]
            const targets = mapping[kdeKey]
            for (const [section, iniKey] of targets) {
                const lookup = section + "|" + iniKey
                const useRgb = iniKey === "AccentColor" || iniKey === "DecorationFocus" ||
                               iniKey === "DecorationHover" || iniKey === "ForegroundActive" ||
                               section === "WM"
                kdeUpdates[lookup] = useRgb ? rgb : hex
                schemeUpdates[lookup] = section === "WM" ? "#ff" + hex.slice(1) : hex
            }
        }

        const kdeJson = JSON.stringify(kdeUpdates).replace(/'/g, "'\\''")
        const schemeJson = JSON.stringify(schemeUpdates).replace(/'/g, "'\\''")
        Quickshell.execDetached(["python3", "-c", `
import re, json, sys, os
kde_updates = json.loads('${kdeJson}')
scheme_updates = json.loads('${schemeJson}')

def update_ini(path, updates):
    try:
        with open(path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        return
    u = dict(updates)
    by_section = {}
    for lookup, val in list(u.items()):
        sec, key = lookup.split('|', 1)
        by_section.setdefault(sec, {})[key] = val
    section = ''
    out = []
    for line in lines:
        stripped = line.strip()
        m = re.match(r'^\\[(.+)\\]$', stripped)
        if m:
            if section in by_section:
                for key, val in by_section.pop(section).items():
                    out.append(key + '=' + val + '\\n')
            section = m.group(1)
            out.append(line)
        elif '=' in stripped and section:
            key = stripped.split('=', 1)[0]
            lookup = section + '|' + key
            if lookup in u:
                out.append(key + '=' + u.pop(lookup) + '\\n')
                by_section.get(section, {}).pop(key, None)
            else:
                out.append(line)
        else:
            out.append(line)
    if section in by_section:
        for key, val in by_section.pop(section).items():
            out.append(key + '=' + val + '\\n')
    with open(path, 'w') as f:
        f.writelines(out)

scheme_name = ''
try:
    with open(os.path.expanduser('~/.config/kdeglobals')) as f:
        in_general = False
        for line in f:
            if line.strip() == '[General]':
                in_general = True
            elif line.strip().startswith('['):
                in_general = False
            elif in_general and line.startswith('ColorScheme='):
                scheme_name = line.strip().split('=', 1)[1]
                break
except Exception:
    pass

import subprocess
accent_val = kde_updates.pop('General|AccentColor', '')
update_ini(os.path.expanduser('~/.config/kdeglobals'), kde_updates)
if scheme_name:
    scheme_path = os.path.expanduser(f'~/.local/share/color-schemes/{scheme_name}.colors')
    update_ini(scheme_path, scheme_updates)

if accent_val:
    subprocess.run(['kwriteconfig6', '--file', 'kdeglobals', '--group', 'General',
        '--key', 'AccentColor', '--notify', accent_val], check=False)
subprocess.run(['dbus-send', '--session', '--type=signal',
    '/KGlobalSettings', 'org.kde.KGlobalSettings.notifyChange',
    'int32:0', 'int32:0'], check=False)
`])
    }

    function applyToGtkCss() {
        const raw = ColorOverrideStore.data?.colorOverrides
        let hasGtkOverride = false
        if (raw && raw !== "{}") {
            try {
                const overrides = JSON.parse(raw)
                for (const key in overrides) {
                    if (key.startsWith("gtk")) { hasGtkOverride = true; break }
                }
            } catch (e) {}
        }
        if (!hasGtkOverride && !root._gtkDirty) return
        root._gtkDirty = hasGtkOverride

        function toHex6(c) {
            function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
            return "#" + h(c.r) + h(c.g) + h(c.b)
        }
        const mapping = {
            gtkAccent: ["accent_color", "accent_bg_color"],
            gtkAccentFg: ["accent_fg_color"],
            gtkWindowBg: ["window_bg_color"],
            gtkWindowFg: ["window_fg_color"],
            gtkHeaderbarBg: ["headerbar_bg_color"],
            gtkHeaderbarFg: ["headerbar_fg_color"],
            gtkViewBg: ["view_bg_color"],
            gtkViewFg: ["view_fg_color"],
            gtkCardBg: ["card_bg_color"],
            gtkCardFg: ["card_fg_color"],
            gtkPopoverBg: ["popover_bg_color"],
            gtkPopoverFg: ["popover_fg_color"],
        }
        const updates = {}
        for (const gtkKey in mapping) {
            const color = Appearance.m3colors[gtkKey]
            if (!color) continue
            const hex = toHex6(color)
            for (const cssName of mapping[gtkKey]) {
                updates[cssName] = hex
            }
        }
        const updatesJson = JSON.stringify(updates).replace(/'/g, "'\\''")
        Quickshell.execDetached(["python3", "-c", `
import re, json, os
updates = json.loads('${updatesJson}')
def update_css(path):
    try:
        with open(path) as f:
            css = f.read()
    except FileNotFoundError:
        return
    for name, value in updates.items():
        css = re.sub(
            r'(@define-color\\s+' + re.escape(name) + r'\\s+)#[0-9a-fA-F]{3,8}(\\s*;)',
            r'\\1' + value + r'\\2',
            css
        )
    with open(path, 'w') as f:
        f.write(css)
update_css(os.path.expanduser('~/.config/gtk-3.0/gtk.css'))
update_css(os.path.expanduser('~/.config/gtk-4.0/gtk.css'))
`])
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    // Exactly matches original: delay to let file finish writing, then apply
    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    // After the full switchwall.sh pipeline completes (~4s), bounce filePath
    // to re-establish the file watcher on the (possibly new) inode and
    // pick up the final colors.json with all merges applied.
    Timer {
        id: pipelineCompleteTimer
        interval: 4000
        repeat: false
        onTriggered: {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
        }
    }

    Timer {
        id: terminalApplyTimer
        interval: 50
        repeat: false
        onTriggered: root.applyToActiveTerminals()
    }

    Timer {
        id: kdeApplyTimer
        interval: 100
        repeat: false
        onTriggered: root.applyToKdeglobals()
    }

    Timer {
        id: gtkApplyTimer
        interval: 100
        repeat: false
        onTriggered: root.applyToGtkCss()
    }

    Connections {
        target: ColorOverrideStore.data ?? null
        function onColorOverridesChanged() {
            root.refreshColors()
        }
    }

	FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
            root._pendingOverrideClear = true
            kdeApplyTimer.stop()
            pipelineCompleteTimer.restart()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: {
            root.resetFilePathNextTime()
        }
    }
}
