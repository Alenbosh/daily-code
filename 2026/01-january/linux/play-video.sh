#!/usr/bin/env bash

BASE="$HOME/Entertainment"

clean_title() {
  local name="$1"
  echo "$name" | sed -E '
    s/[._]/ /g;

    # Resolutions & quality
    s/\b(480p|720p|1080[pP]|2160p|4k|8k|10[Bb]it)\b//Ig;

    # Sources & rips
    s/\b(WEB[- ]?DL|WEBRip|BluRay|HDRip|DVDRip|CAMRip|HDCAM|HC)\b//Ig;

    # Platforms & audio/video codecs
    s/\b(AMZN|NF|Netflix|Prime|Disney|DDP?[0-9.]+|AAC|AC3|HEVC|H[.]?264|H[.]?265|x264|x265|Xvid|X264)\b//Ig;

    # Subs & languages
    s/\b(ESubs?|Subs?|MSubs|Msubs|Multi|Dual|English|Hindi|Korean|Chinese|HIN|KOR|ORG|HDR|SUB)\b//Ig;

    # Release groups & junk
    s/\b(1XBET|MoviesMod|Moviesmod|YTS|Cards|Band|Cafe|Plus|Kids|blackHawk|KyoGo)\b//Ig;

    # Leftover dashes from removed tags (like H.264-Moviesmod)
    s/-$//; s/- $/ /g;

    # Standardize season/episode (just in case)
    s/\bS([0-9]{1,2})E([0-9]{1,2})\b/S\1E\2/Ig;

    # Final space cleanup
    s/\s+/ /g; s/^ //; s/ $//;
  '
}


while true; do
  categories=$(find "$BASE" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
    category=$(basename "$dir")
    case "$category" in
      Films)   echo "🎬 Films" ;;
      Tv)      echo "📺 Tv" ;;
      Sports)  echo "⚽ Sports" ;;
      *)       echo "📁 $category" ;;
    esac
  done)

  choice=$(printf "%s\n" "$categories" | walker --dmenu -p "🎬 Choose Category")
  [ -z "$choice" ] && exit 0

  category_dir_name=$(echo "$choice" | sed -E 's/^[[:space:]]*[^[:space:]]+[[:space:]]+//')
  category_dir="$BASE/$category_dir_name"
  [ ! -d "$category_dir" ] && continue

  while true; do
    unset path_map
    declare -A path_map

    video_list="← Back to Categories\n"

    while read -r file; do
      name="$(basename "$file")"
      name="${name%.*}"
      clean="$(clean_title "$name")"

      if [[ -n "${path_map["$clean"]}" ]]; then
        clean="$clean (duplicate)"
      fi

      path_map["$clean"]="$file"
      video_list+="$clean\n"
    done < <(find "$category_dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.webm" \) | sort)

    video_choice=$(printf "%b" "$video_list" | walker --dmenu -p "🎬 Play from $category_dir_name")

    if [ -z "$video_choice" ]; then
      break
    fi

    if [[ "$video_choice" == "← Back to Categories" ]]; then
      break
    fi

    real_file="${path_map["$video_choice"]}"

    if [[ -n "$real_file" && -f "$real_file" ]]; then
      # Check if Delete or Shift+Backspace was pressed (Walker passes it as selected line if configured, but we detect via prompt)
      # Instead: after selection, offer delete option via a quick confirm menu
      action=$(printf "▶ Play\n🗑 Delete" | walker --dmenu -p "Action for: $video_choice")

      if [ -z "$action" ]; then
        continue  # Esc → back to list
      fi

      case "$action" in
        "▶ Play")
          nohup mpv "$real_file" >/dev/null 2>&1 &
          exit 0
          ;;
        "🗑 Delete")
          confirm=$(printf "No\nYes, move to Trash" | walker --dmenu -p "Delete \"$video_choice\"?")
          if [[ "$confirm" == "Yes, move to Trash" ]]; then
            trash-put "$real_file"
            notify-send "🗑 Moved to Trash" "$video_choice"
          fi
          # Loop back to refreshed list
          continue
          ;;
      esac
    fi
  done
done
