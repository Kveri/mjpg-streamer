mjpg-streamer
=============

This is a dirty fork of jacksonliam/mjpg-streamer. Mjpg-streamer is used by OctoPrint to live stream 3D printing. I also use octolapse to make timelapse of almost each print.

There are two problems with the original implementation:

1. the quality of the stream and the quality of the timelapse photos is the same, because the photo is always taken from the stream
This means that either the stream has to be high quality and then photos are high quality as well. This is good for timelapse but RPi 4 can only handle 2-3fps of max resolusion of RPi Camera v2, so the stream is severely low-fps and also good 5 seconds behind real-time. Alternatively the stream can be made low-quality but then the timelapse is also low-res.
2. it is not possible to run raspistill to take timelapse snapshot directly from the camera while the stream is running, because the RPi camera is used by mjpg-streamer and raspistill can't access the port.

I analysed various solutions:
1. extend mjpg-streamer to take still photos at correct intervals (whenever signalled by octolapse), this proved to be to difficult
2. shutdown mjpg-streamer, take the photo using raspistill and start mjpg-streamer every time octolapse needs to take a photo - this interrupts the stream which I didn't like and browser/app refresh is necessary - it doesn't recover automatically and probably some healthcheck would be needed in the GUI
3. use some mid quality resolution good for stream as well as photos - this didn't work out because any relatively good quality for photos already provided very low fps for the stream. I was frustrated by the non-realtimeness and lagging of the video.
4. don't use mjpeg but rather encode to mpeg-ts/x264, etc. - RPi 4 performance is not good enough for real-time transcoding

Another thing to note is that the bitrate of the stream is relatively high, it is mjpeg, so no inter-frame compression is possible, so transmission outside of local LAN/wifi was problematic. So I wanted to have the stream as low quality as possible, just enough to see that something is happening and whether there is a failed print, etc. But to still get very good quality timelapses.

So I hacked mjpg-streamer a bit. The main idea is: when octolapse wants to take a snapshot it somehow signals mjpg-streamer (which runs with relatively low settings) to disconnect from the camera, but to keep the HTTP output context alive. Then raspistill can take the snapshot using max settings. Then octolapse again signals mjpg-streamer to continue streaming by re-connecting to the camera.

The "signal" is a simple file, when created mjpg-streamer detects this and pauses itself. After removed, mjpg-streamer un-pauses itself. Mjpg-streamer stays paused while the file exists.

This required some dirty hacks because mjpg-streamer is multi-threaded and to disconnect from the camera almost all internal structures had to be destroyed. I took great care to prevent any memory leaks and I tested this on multiple ~700 layer prints without mjpg-streamer restart, so it should be hopefully fine.

I used linux signals at first and not file, but signals can be "lost" (i.e. when received during an interrupt) and then the whole idea falls apart.

HOWTO:
- compile as standard mjpg-streamer
- mjpg-streamer checks every few milliseconds for file /run/mjpg_streamer_paused.lock. If it exists, mjpg-streamer is paused (disconnected from the camera)
- setup "before-snapshot.sh" as "before snapshot" script in octolapse - this creates the pause file and waits until mjpg-streamer disconnects from the camera, then takes the photo and deletes the pause file
- create a symlink ~/mjpg-streamer/www/snap.jpg to /run/snap.jpg, so that the snapshot is accessible through the mjpg-streamer web server and octolapse can get it
- run your new mjpg-streamer normally

Original mjpg-streamer howto, compile guide, etc...

Security warning
----------------

**WARNING**: mjpg-streamer should not be used on untrusted networks!
By default, anyone with access to the network that mjpg-streamer is running
on will be able to access it.

Plugins
-------

Input plugins:

* input_file
* input_http
* input_opencv ([documentation](mjpg-streamer-experimental/plugins/input_opencv/README.md))
* input_ptp2
* input_raspicam ([documentation](mjpg-streamer-experimental/plugins/input_raspicam/README.md))
* input_uvc ([documentation](mjpg-streamer-experimental/plugins/input_uvc/README.md))

Output plugins:

* output_file
* output_http ([documentation](mjpg-streamer-experimental/plugins/output_http/README.md))
* ~output_rtsp~ (not functional)
* ~output_udp~ (not functional)
* output_viewer ([documentation](mjpg-streamer-experimental/plugins/output_viewer/README.md))
* output_zmqserver ([documentation](mjpg-streamer-experimental/plugins/output_zmqserver/README.md))

Building & Installation
=======================

You must have cmake installed. You will also probably want to have a development
version of libjpeg installed. I used libjpeg8-dev. e.g.

    sudo apt-get install cmake libjpeg8-dev

If you do not have gcc (and g++ for the opencv plugin) you may need to install those.

    sudo apt-get install gcc g++

Simple compilation
------------------

This will build and install all plugins that can be compiled.

    cd mjpg-streamer-experimental
    make
    sudo make install
    
By default, everything will be compiled in "release" mode. If you wish to compile
with debugging symbols enabled, you can do this:

    cd mjpg-streamer-experimental
    make distclean
    make CMAKE_BUILD_TYPE=Debug
    sudo make install
    
Advanced compilation (via CMake)
--------------------------------

There are options available to enable/disable plugins, setup options, etc. This
shows the basic steps to enable the experimental HTTP management feature:

    cd mjpg-streamer-experimental
    mkdir _build
    cd _build
    cmake -DENABLE_HTTP_MANAGEMENT=ON ..
    make
    sudo make install

Usage
=====
From the mjpeg streamer experimental
folder:
```
export LD_LIBRARY_PATH=.
./mjpg_streamer -o "output_http.so -w ./www" -i "input_raspicam.so"
```

See [README.md](mjpg-streamer-experimental/README.md) or the individual plugin's documentation for more details.

Discussion / Questions / Help
=============================

Probably best in this thread
http://www.raspberrypi.org/phpBB3/viewtopic.php?f=43&t=45178

Authors
=======

mjpg-streamer was originally created by Tom Stöveken, and has received
improvements from many collaborators since then.


License
=======

mjpg-streamer is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
GNU General Public License for more details.
