# esp8266-template

ESP8266 template project for the esp-open-sdk (https://github.com/pfalcon/esp-open-sdk)

The project is based on the blinky example from: https://github.com/esp8266/source-code-examples

Has support for building and debuggig with Docker by setting USE_DOCKER=1 in the makefile (building/debugging without docker has not been tested)
- To create the Docker image run: "docker build -t esp-open-sdk ." in the project root

To debug the code, set the flavor to "debug" in the makefile (this will automatically build the esp-gdbstub)
- The project contains a working debug configuration for Visual Studio Code, with gdb running through the Docker image
