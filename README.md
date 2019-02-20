# Webpiling End-to-End Demo

This repository demonstrates how to webpile OpenCV's ArUco marker tracking for use on the Web, 
and particularly for use in Babylon.js apps.  The repository contains references to three 
submodules -- Emscripten, OpenCV, and webpiled-aruco-ar -- and a single script that runs the 
entire webpiling process: webpile-all-the-things.sh.  This script contains substantial commentary
explaining each of the steps it performs.

To build, simply execute webpile-all-the-things.sh from within a Linux environment (Windows 
Subsystem for Linux will work) that's equipped with the required technologies (Git and CMake 
v2.8.7 or higher).

### NOTE
Sometimes, especially on Windows, the process of pulling down this repository can remove
execution permissions from the bash scripts (webpile-all-the-things.sh and the two bash 
scripts it calls, submodules/webpiled-aruco-ar/build.sh and submodules/webpiled-aruco-ar/run.sh).
If this happens, you can just add the appropriate permissions back to the scripts before trying 
to execute them.

```bash
chmod +x webpile-all-the-things.sh
```