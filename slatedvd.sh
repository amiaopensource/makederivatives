#!/bin/bash
# make a specific dvd image file with slate
# a fake slate file for testing can be made with: ffmpeg -f lavfi -i smptebars=s=2048x1556 -frames:v 1 -pix_fmt rgb24 slate.tif
#SLATEFILE=/Users/preservation/slate.tif
SLATEFILE=/Users/davidrice/Desktop/slate.tif
TMPSLATE="/tmp/slate.mov"

cleanup(){
	rm "$TMPSLATE"
	exit $1
}
trap clean_up SIGHUP SIGINT SIGTERM

[ ! -s "$1" ] && { echo Please run the script with one or many arguments. Arguments should be video files to be transcoded. ; exit 1 ;};
[ ! -s "$SLATEFILE" ] && { echo I can\'t find this slate file you\'re referring to. ; exit 2 ;};

while [ "$*" != "" ] ; do
	OUTPUT="${1%.*}.iso"
	name=$(basename ${1%.*})
	[ -s $OUTPUT ] && { echo "$OUTPUT already existing, skipping transcode for $1" ; shift ; continue ;};
	ffmpeg -n -loop 1 -i "$SLATEFILE" -t 5 -f lavfi -i aevalsrc=0::d=5:s=44100 -vf 'scale=720:480,setdar=4/3,fps=fps=ntsc,fade=in:0:30,fade=out:120:30' -t 5 -r:v ntsc -c:v ffv1 -pix_fmt yuv420p -c:v libx264 -c:a libfaac -r:a 44100 -ac 2 "$TMPSLATE"
	dvdffmpegcommand="ffmpeg -y -i \"$TMPSLATE\" -vsync 0 -i \"$1\" -filter_complex '[1:v]scale=720:480:interl=1,setdar=4/3,format=yuv420p,fps=fps=ntsc[pvid];[0:v:0][0:a:0][pvid][1:a:0]concat=n=2:v=1:a=1[v][a]' -map '[v]' -map '[a]' -r:v ntsc -c:v mpeg2video -c:a ac3 -f dvd -s 720x480 -pix_fmt yuv420p -g 18 -b:v 5000k -maxrate 9000k -minrate 0 -bufsize 1835008 -packetsize 2048 -muxrate 10080000 -b:a 448000 -ar 48000 \"${1%.*}.mpeg\""
	eval "$dvdffmpegcommand"
	export VIDEO_FORMAT=NTSC
	dvdauthor --title -v ntsc -a ac3+en -c 0,5:00,10:00,15:00,20:00,25:00,30:00,35:00,40:00,45:00,50:00,55:00,1:00:00,1:05:00,1:10:00,1:15:00,1:20:00,1:25:00,1:30:00,1:35:00,1:40:00,1:45:00,1:50:00,1:55:00,2:00:00,2:05:00 -f "${1%.*}.mpeg" -o "${1%.*}_DVD"
	dvdauthor_err="$?"
	if [ "$dvdauthor_err" -gt "0" ] ; then
		echo "ERROR dvdauthor reported error code $dvdauthor_err. Please review ${1%.*}_DVD" 1>&2
		shift
		continue
	else
		rm "${1%.*}.mpeg"
	fi
	dvdauthor -T -o "${1%.*}_DVD/"
	echo "HEY ${1%.*:0:32} HEY"
	mkisofs -f -dvd-video -udf -V "${name:0:32}" -v -v -o "$OUTPUT" "${1%.*}_DVD"
	mkisofs_err="$?"
	if [ "$mkisofs_err" -gt "0" ] ; then
		echo "ERROR mkisofs reported error code $mkisofs_err. Please review ${OUTPUT}." 1>&2
		shift
		continue
	else
		rm -r "${1%.*}_DVD"
	fi
	shift
done
