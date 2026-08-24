# Recording and adding the demo video

## Before recording

- Close private chats, terminals with personal paths, email, and notifications.
- Use a neutral wallpaper or crop the recording to the bar and its popups.
- Temporarily clear clipboard history and notification history.
- Keep the pointer movements slow enough to show the animations clearly.

## Suggested 45–75 second sequence

1. Show the pinned bar on the desktop.
2. Maximize or snap a window and demonstrate autohide.
3. Open Search and find one application and one file.
4. Show a running indicator, multi-window chooser, and application context menu.
5. Open the system tray and audio popup.
6. Open Clipboard, Network/Notifications, Weather/Calendar, and System Resources.
7. End with a fullscreen window to demonstrate complete bar lockout.

## Recommended export

- MP4 with H.264 video for broad browser compatibility.
- 1920×1080 or a tightly cropped region.
- 30 FPS.
- No microphone audio unless narration is intentional.
- Keep the final file below 10 MB for a repository on GitHub's free plan.

GitHub currently accepts `.mp4`, `.mov`, and `.webm` attachments and recommends
H.264 for compatibility. See the official
[Attaching files documentation](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files).

## Add it to the README

1. Open `README.md` on GitHub and select the edit button.
2. Place the cursor below the `## Demo` heading.
3. Drag the video into the Markdown editor.
4. Wait for GitHub to generate the attachment URL.
5. Remove the “video will be added soon” placeholder.
6. Commit the README change.

Do not commit a large raw recording directly to Git history. Use the generated
GitHub attachment URL, or host a longer video externally and link a thumbnail.
