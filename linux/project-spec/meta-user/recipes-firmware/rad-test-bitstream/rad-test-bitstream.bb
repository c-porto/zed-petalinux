SUMMARY = "Radiation Testing Setup Bitstream"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit custom-bitstream

SRC_URI = " \
        file://${BPN}.xsa \
        "
