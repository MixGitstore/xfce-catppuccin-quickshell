# Changelog

## 1.1.1 - 2026-08-29

- Animated the central taskbar width around its center so application buttons
  expand and contract evenly on both sides as windows open or close.
- Added portable AppImage desktop-entry and icon setup guidance, including an
  Obsidian example and X11 window-class troubleshooting.

## 1.1.0 - 2026-08-25

- Added drag-and-drop ordering for taskbar applications and right-side quick
  actions, with persistent JSON state.
- Improved X11 window-to-desktop-entry matching for Flatpak applications and
  applications whose runtime `WM_CLASS` differs from their desktop entry.
- Moved Search, Audio, Calendar, Clipboard, and System interfaces into lazy QML
  components to reduce idle and startup memory use.
- Kept only the default PipeWire output active while the Audio popup is closed;
  MPRIS, microphones, devices, and streams now load on demand.
- Removed duplicate permanent NetworkManager state from the main bar.
- Anchored the Audio popup above the movable Audio icon.
- Preserved smooth popup close animations before unloading their components.
- Made XFCE notification-daemon replacement reliable through a reversible
  systemd user-service mask.
