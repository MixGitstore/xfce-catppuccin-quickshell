# Changelog

## 1.2.0 - 2026-08-29

- Added a Display tab alongside Network and Notifications with software
  brightness, manual and scheduled Night Light, color temperature, resolution,
  and refresh-rate controls.
- Added a 15-second confirmation countdown that restores the previous display
  mode automatically when a new resolution or refresh rate is not confirmed.
- Persisted display settings and reapplied gamma after startup, resume, and
  display-mode changes without keeping a Redshift daemon running.
- Added per-application audio routing for active PipeWire/PulseAudio streams,
  including output selection, remembered rules, automatic event-driven route
  restoration, and MPRIS-aware media matching.
- Moved popup content into one transparent window created on demand while
  retaining delayed unloading for Search, Audio, Calendar, Clipboard, System,
  and the extracted application context menu.
- Reduced the permanent X11 surface to the compact bar and consolidated active
  window, client-list, fullscreen/maximized, and geometry monitoring into one
  small event-driven Xlib helper.
- Added IPC controls for Display and Night Light and integrated Display into
  popup closing, autohide, and fullscreen behavior.
- Animated central taskbar resizing evenly around its center.
- Documented portable AppImage desktop entries and icon setup, including an
  Obsidian example.
- Updated Fedora dependencies, setup checks, resource-design notes, project
  layout, and troubleshooting for the new display and audio features.

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
