#!/bin/bash
# make a specific mezzanine file with slate
# a fake slate file for testing can be made with: ffmpeg -f lavfi -i smptebars=s=2048x1556 -frames:v 1 -pix_fmt rgb24 slate.tif
SLATEFILE=/Users/preservation/slate.tif
FRAMESIZE="640x480" # example 640x480
OUTFILESUFFIX="_mezz.mp4"
TMPSLATE="/tmp/slate.mov"

[ ! -s "$1" ] && { echo Please run the script with one or many arguments. Arguments should be video files to be transcoded. ; exit 1 ;};
[ ! -s "$SLATEFILE" ] && { echo I can\'t find this slate file you\'re referring to. ; exit 2 ;};

while [ "$*" != "" ] ; do
  ffmpeg -n -loop 1 -i "$SLATEFILE" -t 5 -f lavfi -i aevalsrc=0::d=5:s=44100 -vf 'scale=640:480,setdar=4/3,fps=fps=ntsc,fade=in:0:30,fade=out:120:30' -t 5 -r:v ntsc -c:v ffv1 -pix_fmt yuv420p -c:v libx264 -c:a libfaac -r:a 44100 -ac 2 "$TMPSLATE"
  command="ffmpeg -i \"$TMPSLATE\" -vsync 0 -i \"$1\" -filter_complex '[1:v]scale=640:480:interl=1,setdar=4/3,yadif,format=yuv420p,fps=fps=ntsc[pvid];[0:v:0][0:a:0][pvid][1:a:0]concat=n=2:v=1:a=1[v][a]' -map '[v]' -map '[a]' -pix_fmt yuv420p -b:v 400k -c:v libx264 -c:a libfaac -r:a 44100 -ac 2 \"${1%.*}${OUTFILESUFFIX}\""
  eval "$command"
  shift
done