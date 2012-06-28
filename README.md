# MoaiRemote

This is an utility to launch Moai apps remotely without building

# Usage

## Prepare your device:

- Build a Moai app for your platform with the provided main.lua as the only source file
- Launch it on your device
- Make sure that your device's wifi is on and it's in the same network with your development computer
- Yes, the GUI is rudimentary, but it works.  

## Locate your device (optional):

- In the directory of this project, execute:

		moai-remote search

- You should see your device name and IP listed. e.g:

		192.168.0.102   GT-I9100

## Deploy your app:

- Build a zip file with your main.lua (not the one provided) in the root directory of the archive. Refer to sample.zip for an example.
- In the directory of this project, execute: moai-remote deploy &lt;archive_name&gt; &lt;device_ip&gt;. e.g: 


		moai-remote deploy sample.zip 192.168.0.102
