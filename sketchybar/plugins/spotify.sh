#!/bin/bash

# Allow override via first arg or env variable
SPOTIFY_DISPLAY_CONTROLS="${1:-false}"
COVER_PATH="/tmp/cover.jpg"
MAX_LABEL_LENGTH=35
LOCK="${TMPDIR:-/tmp}/sketchybar_spotify.lock"

if [ -z "$SPOTIFY_LOCKED" ]; then
  # Open/close the popup right away, before waiting for Spotify
  if [ "$SENDER" = "mouse.clicked" ] && [ "$NAME" = "spotify.anchor" ]; then
    sketchybar -m --set spotify.anchor popup.drawing=toggle
  fi
  # One run at a time: clicks wait their turn, background refreshes are skipped
  # while another run is still talking to Spotify
  wait=0
  [ "$SENDER" = "mouse.clicked" ] && wait=5
  SPOTIFY_LOCKED=1 exec lockf -s -t "$wait" "$LOCK" "$0" "$@"
fi

# Runs AppleScript inside tell application "Spotify", giving up after 2 seconds
spotify() {
  osascript -e 'with timeout of 2 seconds' -e 'tell application "Spotify"' -e "$1" -e 'end tell' -e 'end timeout' 2>/dev/null
}

truncate_text() {
  local text="$1"
  local max_length=${2:-$MAX_LABEL_LENGTH}
  if [ ${#text} -le "$max_length" ]; then
    echo "$text"
  else
    echo "${text:0:max_length}" | sed -E 's/\s+[[:alnum:]]*$//' | awk '{$1=$1};1' | sed 's/$/.../'
  fi
}

update() {
  # pgrep needs no Automation permission and, unlike osascript, never launches Spotify
  if ! pgrep -xq Spotify; then
    sketchybar -m --set spotify.anchor drawing=off popup.drawing=off
    exit 0
  fi
  sketchybar -m --set spotify.anchor drawing=on

  local state track artist album cover_url
  {
    read -r state
    read -r track
    read -r artist
    read -r album
    read -r cover_url
  } < <(spotify '
    set s to player state as text
    if s is "stopped" then return s
    return s & linefeed & name of current track & linefeed & artist of current track & linefeed & album of current track & linefeed & artwork url of current track')
  if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
    return
  fi

  # Download the cover only when the track changes
  if [ "$cover_url" != "$(cat "$COVER_PATH.url" 2>/dev/null)" ]; then
    echo "$cover_url" > "$COVER_PATH.url"
    if curl -s --max-time 5 "$cover_url" -o "$COVER_PATH"; then
      sketchybar -m --set spotify.cover background.image="$COVER_PATH" background.color=0x00000000
    else
      sketchybar -m --set spotify.cover background.image="" background.color=0x00000000
    fi
  fi

  local args=(
    --set spotify.title label="$(truncate_text "$track" $((MAX_LABEL_LENGTH * 7/10)))"
    --set spotify.artist label="$(truncate_text "$artist")"
    --set spotify.album label="$(truncate_text "$album")"
  )
  if [ "$SPOTIFY_DISPLAY_CONTROLS" = "true" ]; then
    if [ "$state" = "playing" ]; then
      args+=(--set spotify.play icon="󰏤")  # pause icon
    else
      args+=(--set spotify.play icon="󰐊")  # play icon
    fi
  fi
  sketchybar -m "${args[@]}"
}

scroll() {
  local duration position
  {
    read -r duration
    read -r position
  } < <(spotify '
    return ((duration of current track) as text) & linefeed & ((player position) as text)')
  # duration is in ms; position is in seconds and may use a decimal comma
  duration=$(( ${duration%%[.,]*} / 1000 ))
  position=${position%%[.,]*}
  [ "$duration" -gt 0 ] 2>/dev/null && [ -n "$position" ] || return

  sketchybar -m --animate linear 10 \
    --set spotify.state slider.percentage=$((position * 100 / duration)) \
                         icon="$(date -r "$position" +'%M:%S')" \
                         label="$(date -r "$duration" +'%M:%S')"
}

scrubbing() {
  spotify "set player position to (duration of current track) * $PERCENTAGE / 100000"
  sketchybar -m --set spotify.state slider.percentage="$PERCENTAGE"
}

# Spotify sends com.spotify.client.PlaybackStateChanged after these, which
# triggers update(), so they don't update the bar themselves
mouse_clicked() {
  case "$NAME" in
    "spotify.next") spotify 'play next track' ;;
    "spotify.back") spotify 'play previous track' ;;
    "spotify.play") spotify 'playpause' ;;
    "spotify.state") scrubbing ;;
    "spotify.anchor") update ;;
  esac
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  "routine")
    if [ "$NAME" = "spotify.state" ]; then scroll; else update; fi
    ;;
  *) update ;;
esac
