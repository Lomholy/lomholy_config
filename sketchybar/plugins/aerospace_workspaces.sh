#!/usr/bin/env bash

# Rebuilds the workspace items: every workspace on the focused monitor that has
# windows, plus the focused one. The focused one is highlighted.
# Order follows the alt-<N> = 'workspace <name>' keybindings in aerospace.toml;
# workspaces without a keybinding come last, in AeroSpace's order.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

config="$HOME/.config/aerospace/aerospace.toml"
[ -f "$config" ] || config="$HOME/.aerospace.toml"

focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
on_monitor="$(aerospace list-workspaces --monitor focused)"
non_empty="$(aerospace list-workspaces --monitor focused --empty no)"

ordered="$(
  {
    sed -nE "s/^[[:space:]]*alt-([0-9]+)[[:space:]]*=[[:space:]]*'workspace (.+)'.*/\1 \2/p" "$config" 2>/dev/null |
      sort -n | cut -d' ' -f2-
    printf '%s\n' "$on_monitor"
  } | awk '!seen[$0]++'
)"

args=(--remove '/^space\..*/')
while IFS= read -r ws; do
  [ -n "$ws" ] || continue
  grep -Fxq -- "$ws" <<<"$on_monitor" || continue
  if [ "$ws" != "$focused" ] && ! grep -Fxq -- "$ws" <<<"$non_empty"; then
    continue
  fi
  [ "$ws" = "$focused" ] && selected=on || selected=off
  args+=(
    --add item "space.$ws" left
    --set "space.$ws"
      background.color=0x44ffffff
      background.height=20
      background.drawing="$selected"
      width=40
      icon="$ws"
      icon.align=center
      icon.padding_left=12
      icon.highlight=on
      icon.highlight_color=0xff00ff00
      click_script="aerospace workspace '$ws'"
  )
done <<<"$ordered"

sketchybar "${args[@]}"

