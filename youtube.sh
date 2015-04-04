#!/bin/bash
#
# start youtube download

set -e -u

clear

vlc=/c/Program\ Files\ \(x86\)/VideoLAN/VLC/vlc.exe
youtubedl=/c/Program\ Files\ \(x86\)/youtube-dl/youtube-dl.exe
linkfile="links.txt"

getvideoname(){
  local url="$1"
  "$youtubedl" --get-filename "$url"
}

download(){
  local url="$1"

  echo "Lade '$url' herunter"

  "$youtubedl" -t "$url"
}

convert(){
  local videoname="$1"

  mp3name=$(basename "$videoname" | sed 's/\..*$/.mp3/')
  wavname=$(basename "$videoname" | sed 's/\..*$/.wav/')

  rm -fv "$wavname" "$mp3name"

  echo "Konvertiere '$videoname' zu $wavname"

  "$vlc" \
    --no-crashdump \
    -vvv \
    "$videoname" \
    :no-video \
    :sout='#transcode{acodec=s16l,channels=2,samplerate=44100}:std{access=file,mux=wav,dst="'"$wavname"'"}' \
    vlc://quit

  rm -fv "$videoname"

  echo "Konvertiere '$wavname' zu $mp3name"

  "$vlc" \
    --no-crashdump \
    -vvv \
    "$wavname" \
    :sout='#transcode{acodec=mp3,ab=192}:std{access=file,mux=dummy,dst="'"$mp3name"'"}' \
    vlc://quit

  rm -fv "$wavname"
}

empty(){
  (( $(wc -w "$linkfile" | awk '{ print $1 }') == 0 )) || return 1
  return 0
}

readurl(){
  url=$(head -1 "$linkfile")
  sed -i '1d; s/$/\r/' "$linkfile"
  echo "$url"
}

waitandexit(){
  read -p "Drücke Enter, um fortzufahren"
  exit 0
}

createlinkfile(){
  [ -f "$linkfile" ] && return

  touch "$linkfile"

  cat <<EOF
$linkfile wurde erstellt.

Kopiere deine Youtube-Links in $linkfile, speicher ab und starte $(sed 's/^.*[\\/]//' <<< "$0") erneut.

EOF

  waitandexit
}

createlinkfile

if empty; then
  echo "'$linkfile' enthält keine Youtube-Links."
  echo
  waitandexit
fi

while ! empty; do
  url=$(readurl)
  download "$url"
  convert "$(getvideoname "$url")"
done

echo
echo "fertig"

