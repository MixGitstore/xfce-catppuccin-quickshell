.pragma library

// Edit this array to reorder, add, or remove pinned applications.
// Commands are argument arrays because Quickshell launches them without a shell.
var pinned = [
    {
        name: "Terminal",
        pinKey: "xfce4-terminal.desktop",
        wmClasses: ["xfce4-terminal"],
        contextActions: [
            { label: "New terminal", command: ["xfce4-terminal"] }
        ],
        icon: "catppuccin-terminal",
        iconSource: "assets/icons/catppuccin-terminal.svg",
        command: ["exo-open", "--launch", "TerminalEmulator"]
    },
    {
        name: "Files",
        pinKey: "thunar.desktop",
        wmClasses: ["thunar"],
        contextActions: [
            { label: "Home folder", command: ["bash", "-lc", "exec xdg-open \"$HOME\""] },
            { label: "Desktop", command: ["bash", "-lc", "exec xdg-open \"$(xdg-user-dir DESKTOP)\""] },
            { label: "Downloads", command: ["bash", "-lc", "exec xdg-open \"$(xdg-user-dir DOWNLOAD)\""] }
        ],
        icon: "catppuccin-files",
        iconSource: "assets/icons/catppuccin-files.svg",
        command: ["exo-open", "--launch", "FileManager"]
    },
    {
        name: "Zen Browser",
        pinKey: "zen.desktop",
        wmClasses: ["zen"],
        contextActions: [
            {
                label: "New window",
                command: ["zen-browser", "--new-window"]
            },
            {
                label: "New private window",
                command: ["zen-browser", "--private-window"]
            },
            {
                label: "Profile Manager",
                command: ["zen-browser", "--ProfileManager"]
            }
        ],
        icon: "zen-browser",
        iconSource: "assets/icons/zen-browser.svg",
        command: ["zen-browser"]
    },
    {
        name: "Thunderbird",
        pinKey: "net.thunderbird.Thunderbird.desktop",
        wmClasses: ["thunderbird", "mail", "net.thunderbird.Thunderbird"],
        contextActions: [
            { label: "New message", command: ["thunderbird", "-compose"] }
        ],
        icon: "catppuccin-mail",
        iconSource: "assets/icons/catppuccin-mail.svg",
        command: ["thunderbird"]
    },
    {
        name: "Discord",
        pinKey: "discord.desktop",
        wmClasses: ["discord"],
        icon: "catppuccin-discord",
        iconSource: "assets/icons/catppuccin-discord.svg",
        command: ["discord"]
    },
    {
        name: "Steam",
        pinKey: "steam.desktop",
        wmClasses: ["steam"],
        contextActions: [
            { label: "Library", command: ["steam", "steam://open/games"] },
            { label: "Store", command: ["steam", "steam://store"] },
            { label: "Big Picture", command: ["steam", "steam://open/bigpicture"] }
        ],
        icon: "catppuccin-steam",
        iconSource: "assets/icons/catppuccin-steam.svg",
        command: ["steam"]
    },
    {
        name: "FileZilla",
        pinKey: "filezilla.desktop",
        wmClasses: ["filezilla"],
        icon: "catppuccin-filezilla",
        iconSource: "assets/icons/catppuccin-filezilla.svg",
        command: ["filezilla"]
    },
    {
        name: "Zed",
        pinKey: "dev.zed.Zed.desktop",
        wmClasses: ["dev.zed.zed", "zed"],
        contextActions: [
            {
                label: "New workspace",
                command: ["zed", "--new"]
            }
        ],
        icon: "zed",
        iconSource: "assets/icons/catppuccin-zed.svg",
        command: ["zed"]
    },
    {
        name: "DaVinci Resolve",
        pinKey: "com.blackmagicdesign.resolve.desktop",
        wmClasses: ["resolve"],
        icon: "catppuccin-resolve",
        iconSource: "assets/icons/catppuccin-resolve.svg",
        command: ["/opt/resolve/bin/resolve"]
    },
    {
        name: "OBS Studio",
        pinKey: "com.obsproject.Studio.desktop",
        wmClasses: ["obs"],
        icon: "catppuccin-obs",
        iconSource: "assets/icons/catppuccin-obs.svg",
        command: ["obs"]
    },
    {
        name: "XFCE Settings",
        pinKey: "xfce-settings-manager.desktop",
        wmClasses: ["xfce4-settings-manager"],
        icon: "catppuccin-settings",
        iconSource: "assets/icons/catppuccin-settings.svg",
        command: ["xfce4-settings-manager"]
    },
    {
        name: "Task Manager",
        pinKey: "xfce4-taskmanager.desktop",
        wmClasses: ["xfce4-taskmanager"],
        icon: "catppuccin-taskmanager",
        iconSource: "assets/icons/catppuccin-taskmanager.svg",
        command: ["xfce4-taskmanager"]
    }
]

function normalized(value) {
    return String(value || "").toLowerCase()
}

function byPinKey(pinKey) {
    const wanted = normalized(pinKey)
    for (let index = 0; index < pinned.length; ++index) {
        if (normalized(pinned[index].pinKey) === wanted) {
            return pinned[index]
        }
    }
    return null
}

function byClasses(classes) {
    if (!classes) {
        return null
    }

    for (let appIndex = 0; appIndex < pinned.length; ++appIndex) {
        const appClasses = pinned[appIndex].wmClasses || []
        for (let classIndex = 0; classIndex < classes.length; ++classIndex) {
            if (appClasses.map(normalized).indexOf(normalized(classes[classIndex])) !== -1) {
                return pinned[appIndex]
            }
        }
    }
    return null
}
