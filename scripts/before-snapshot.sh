#! /bin/bash

exec > /dev/null
exec 2>&1

sudo touch /run/mjpg_streamer_paused.lock

while :; do
  ps -T -p $(pidof mjpg_streamer) | grep -q input_raspicam || break
  sleep 0.01
done

#/usr/bin/raspistill -q 100 -e jpg -w 2464 -h 3280  -v -md 3 -sh 0 -co 0 -br 50 -sa 0 -ISO 200 --nopreview \
#	-awb off -ifx denoise -mm average -rot 90 -awbg 1.5,1.2 -drc off -st -ex auto \
#	-o /home/pi/mjpg-streamer/www/snap.jpg --verbose -ag 1.0 -set -th none -t 1000

#/usr/bin/raspistill -o /home/pi/mjpg-streamer/www/snap.jpg -q 100 -e jpg -w 2464 -h 3280 -rot 90 \
#	   --nopreview -th none -st -set -v --verbose -awb off --awbgains 1.0,4.0

#/usr/bin/raspistill --verbose -set -q 100 -e jpg -w 2464 -h 3280 -rot 90 \
#	-md 3 -sh 0 -co 0 -br 50 -sa 0 --nopreview -drc high -awb auto -awbg 1.0,2.0 -ifx denoise \
#	-mm spot -ISO 200 -ex auto --timeout 5000 \
#	-o /home/pi/mjpg-streamer/www/snap.jpg

sudo /usr/bin/raspistill --verbose -q 100 -e jpg -w 2464 -h 3280 -rot 90 \
	-md 3 -sh 20 -co 0 -br 50 -sa 0 --nopreview -th none \
	-drc low -awb off -awbg 1.4,1.4 -ifx denoise -st -set \
	-mm spot -ISO 100 -ex auto --timeout 1000 \
	-o /run/snap.jpg

sudo rm /run/mjpg_streamer_paused.lock

exit 0
