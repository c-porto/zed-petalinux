FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILES:${PN} += "/etc/motd"

SRC_URI += "file://zed.motd"

do_install:append() {
    install -m 0644 ${WORKDIR}/zed.motd ${D}${sysconfdir}/motd
}
