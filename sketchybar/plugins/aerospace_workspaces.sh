#!/usr/bin/env bash

# Keeps one item per workspace and animates it instead of rebuilding the bar:
# a workspace on the focused monitor grows in when it gets windows (or focus)
# and shrinks out when it empties, and the highlight fades to the focused one.
# Order follows the alt-<N> = 'workspace <name>' keybindings in aerospace.toml;
# workspaces without a keybinding come last, in AeroSpace's order.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Run one instance at a time so two events can't add the same item twice
if [ -z "$AEROSPACE_WORKSPACES_LOCKED" ]; then
  AEROSPACE_WORKSPACES_LOCKED=1 exec lockf -k "${TMPDIR:-/tmp}/sketchybar_aerospace_workspaces.lock" "$0" "$@"
fi

config="$HOME/.config/aerospace/aerospace.toml"
[ -f "$config" ] || config="$HOME/.aerospace.toml"

curve=tanh
frames=15 # animation length in frames (60 per second)

source "$(dirname "$0")/../../colors.sh"
icon_on=$BORDER_COLOR
icon_off="0x00${BORDER_COLOR:4}" # same colour, fully transparent

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

existing="$(sketchybar --query bar | grep -o '"space\.[^"]*"' | tr -d '"')"

add=()
order=(aerospace_workspaces)
state=()
while IFS= read -r ws; do
  [ -n "$ws" ] || continue
  item="space.$ws"
  order+=("$item")

  if ! grep -Fxq -- "$item" <<<"$existing"; then
    add+=(
      --add item "$item" left
      --set "$item"
        width=0
        padding_left=0
        padding_right=0
        background.drawing=on
        background.color=0x00ffffff
        background.height=20
        icon="$ws"
        icon.align=center
        icon.padding_left=12
        icon.highlight=on
        icon.highlight_color=$icon_off
        click_script="aerospace workspace '$ws'"
    )
  fi

  if grep -Fxq -- "$ws" <<<"$on_monitor" &&
    { [ "$ws" = "$focused" ] || grep -Fxq -- "$ws" <<<"$non_empty"; }; then
    state+=(--set "$item" width=40 padding_left=5 padding_right=5 icon.highlight_color=$icon_on)
  else
    state+=(--set "$item" width=0 padding_left=0 padding_right=0 icon.highlight_color=$icon_off)
  fi

  if [ "$ws" = "$focused" ]; then
    state+=(background.color=0x44ffffff)
  else
    state+=(background.color=0x00ffffff)
  fi
done <<<"$ordered"

[ ${#add[@]} -gt 0 ] && sketchybar "${add[@]}" --reorder "${order[@]}"
sketchybar --animate "$curve" "$frames" "${state[@]}"
