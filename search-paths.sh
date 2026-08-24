#!/usr/bin/env bash

# Fast, bounded file search for the Quickshell launcher. plocate uses Fedora's
# existing on-disk index, so typing never walks the home directory recursively.
needle=${1:-}

if (( ${#needle} < 2 )); then
    exit 0
fi

shopt -s nocasematch
result_count=0
declare -A seen_paths

search_root() {
    local root=$1
    local path name kind

    while IFS= read -r path; do
        name=${path##*/}

        # plocate matches the complete path. Keep only entries whose own name
        # contains the query, and skip generated trees that swamp useful results.
        [[ "$name" == *"$needle"* ]] || continue
        [[ -z ${seen_paths["$path"]+present} ]] || continue

        case "$path" in
            "$HOME"/.cache/* | \
            "$HOME"/.cargo/registry/* | \
            "$HOME"/.codex/* | \
            "$HOME"/.local/share/icons/* | \
            "$HOME"/.local/share/Steam/* | \
            "$HOME"/.local/share/Trash/* | \
            "$HOME"/.npm/* | \
            "$HOME"/.rustup/* | \
            "$HOME"/.var/app/* | \
            "$HOME"/Catppuccin-GTK-Theme/* | \
            */.git/* | \
            */node_modules/*)
                continue
                ;;
        esac

        if [[ -d "$path" ]]; then
            kind=folder
        elif [[ -f "$path" ]]; then
            kind=file
        else
            # Ignore stale entries in the locate database.
            continue
        fi

        seen_paths["$path"]=1
        printf '%s\t%s\n' "$kind" "$path"
        ((result_count += 1))
        ((result_count >= 12)) && return
    done < <(plocate -N -i -l 500 -- "$root" "$needle")
}

# Personal folders win over development trees and application data. The final
# home-wide pass fills any remaining slots while the associative array removes
# duplicates returned by earlier passes.
for search_root_path in \
    "$HOME/Desktop/" \
    "$HOME/Documents/" \
    "$HOME/Downloads/" \
    "$HOME/Pictures/" \
    "$HOME/Videos/" \
    "$HOME/Music/" \
    "$HOME/"; do
    search_root "$search_root_path"
    ((result_count >= 12)) && break
done
