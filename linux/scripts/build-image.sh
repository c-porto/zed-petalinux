#!/bin/bash

echo "Starting to build Zedboard linux image..."

# Updating the configuration to include newest hw-design
petalinux-config --silentconfig --get-hw-description hw-design/zed.xsa

# Actually calling the petalinux tools
petalinux-build 

# Packaging the image
petalinux-package --boot --u-boot --fpga --force 

# Generate the .wic file for QEMU 
petalinux-package --wic
