# Vert.x EventBus Wireshark Dissector

## Overview

The [vertx_eventbus_dissector.lua](vertx_eventbus_dissector.lua) script allows you to analyze Vert.x EventBus communication protocol in Wireshark.
This is the protocol used by Vert.x nodes that communicate over EventBus in clustered mode. See the [script](vertx_eventbus_dissector.lua) for more
information on how to enable this dissector in Wireshark.

## Sample Capture File

You can use [this](vertx_eventbus_sample_capture.pcapng) Vert.x EventBus capture file to check the dissector out.

## Screenshots

![Wireshark decode as](vertx_eventbus_wireshark_screenshot_decode_as.png)

![Wireshark decode as dialog](vertx_eventbus_wireshark_screenshot_decode_as_dialog.png)

![Wireshark screenshot](vertx_eventbus_wireshark_screenshot.png)
