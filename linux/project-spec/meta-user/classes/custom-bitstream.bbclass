inherit fpgamanager_dtg systemd

# Standalone extra overlays to compile from SRC_URI
# Example:
# FPGA_EXTRA_OVERLAYS = "my-extra-a.dts my-extra-b.dts"
FPGA_EXTRA_OVERLAYS ?= ""

# Extra include paths for dtc when compiling FPGA_EXTRA_OVERLAYS
FPGA_EXTRA_DTC_INCLUDES ?= "${WORKDIR} ${XSCTH_WS}/${XSCTH_DT_PATH}"

# systemd integration
SYSTEMD_SERVICE:${BPN} = "${BPN}.service"
SYSTEMD_AUTO_ENABLE ??= "disable"

# fpgautil comes from fpga-manager-script
RDEPENDS:${BPN} += "bash fpga-manager-script"

# Region/flags used by fpgautil for full-bitstream flow
FPGA_FPGAUTIL_FLAGS ?= "Full"
FPGA_FPGAUTIL_REGION ?= "Full"

python __anonymous() {
    overlays = (d.getVar("FPGA_EXTRA_OVERLAYS") or "").split()
    src_uri = d.getVar("SRC_URI") or ""

    fetched = []
    for item in src_uri.split():
        if item.startswith("file://"):
            fetched.append(item[len("file://"):])

    missing = []
    for ovl in overlays:
        if ovl not in fetched and os.path.basename(ovl) not in [os.path.basename(x) for x in fetched]:
            missing.append(ovl)

    if missing:
        bb.fatal("FPGA_EXTRA_OVERLAYS missing from SRC_URI: %s" % " ".join(missing))

    dtbos = []
    for ovl in overlays:
        stem = os.path.splitext(os.path.basename(ovl))[0]
        dtbos.append(stem + ".dtbo")
    d.setVar("FPGA_EXTRA_DTBO_NAMES", " ".join(dtbos))
}

python devicetree_do_compile:append() {
    overlays = (d.getVar("FPGA_EXTRA_OVERLAYS") or "").split()
    if not overlays:
        return

    dtc = os.path.join(d.getVar("STAGING_BINDIR_NATIVE"), "dtc")
    workdir = d.getVar("WORKDIR")
    builddir = d.getVar("B")
    includes = (d.getVar("FPGA_EXTRA_DTC_INCLUDES") or "").split()

    for ovl in overlays:
        src = os.path.join(workdir, ovl)
        if not os.path.exists(src):
            # fall back to basename in WORKDIR
            src = os.path.join(workdir, os.path.basename(ovl))

        if not os.path.exists(src):
            bb.fatal("Overlay source not found: %s" % ovl)

        stem = os.path.splitext(os.path.basename(ovl))[0]
        out = os.path.join(builddir, stem + ".dtbo")

        cmd = [dtc, "-@", "-I", "dts", "-O", "dtb", "-o", out]
        for inc in includes:
            cmd += ["-i", inc]
        cmd.append(src)

        bb.note("Compiling extra overlay: %s -> %s" % (src, out))
        subprocess.run(cmd, check=True)
}

do_install:append() {
    fwdir=${D}${nonarch_base_libdir}/firmware/xilinx/${BPN}
    install -d $fwdir

    # Install extra overlays next to the legacy main artifacts:
    #   ${BPN}.dtbo
    #   ${BPN}.bit.bin
    for ovl in ${FPGA_EXTRA_OVERLAYS}; do
        stem=$(basename "$ovl" .dts)
        if [ ! -f "${B}/${stem}.dtbo" ]; then
            bbfatal "Expected compiled extra overlay ${B}/${stem}.dtbo not found"
        fi
        install -m 0644 ${B}/${stem}.dtbo $fwdir/${stem}.dtbo
    done

    install -d ${D}${sbindir}
    cat > ${D}${sbindir}/${BPN}-fpga-control <<EOF
#!/bin/sh
set -eu

FW_DIR=${nonarch_base_libdir}/firmware/xilinx/${BPN}
MAIN_BIT="\$FW_DIR/${BPN}.bit.bin"
MAIN_DTBO="\$FW_DIR/${BPN}.dtbo"
EXTRA_DTBOS="${FPGA_EXTRA_DTBO_NAMES}"

CONFIGFS=/configfs
OVERLAY_ROOT=\$CONFIGFS/device-tree/overlays

ensure_configfs() {
    if [ ! -d "\$CONFIGFS/device-tree" ]; then
        mkdir -p "\$CONFIGFS"
        mount -t configfs configfs "\$CONFIGFS"
    fi
 }

apply_one_overlay() {
    dtbo_name="\$1"
    live_name="\${dtbo_name%.dtbo}"
    live_dir="\$OVERLAY_ROOT/\$live_name"

    mkdir -p "\$live_dir"
    cp "\$FW_DIR/\$dtbo_name" /lib/firmware/
    echo -n "\$dtbo_name" > "\$live_dir/path"
    rm -f "/lib/firmware/\$dtbo_name"
 }

remove_one_overlay() {
    dtbo_name="\$1"
    live_name="\${dtbo_name%.dtbo}"
    live_dir="\$OVERLAY_ROOT/\$live_name"

    if [ -d "\$live_dir" ]; then
        rmdir "\$live_dir" || true
    fi
 }

case "\$1" in
    start)
        ensure_configfs

        if [ ! -f "\$MAIN_BIT" ]; then
            echo "Missing bitstream: \$MAIN_BIT" >&2
            exit 1
        fi

        if [ -f "\$MAIN_DTBO" ]; then
            fpgautil -b "\$MAIN_BIT" -o "\$MAIN_DTBO" -f ${FPGA_FPGAUTIL_FLAGS} -n ${FPGA_FPGAUTIL_REGION}
        else
            # allow static xsa case with no pl-final.dtbo
            fpgautil -b "\$MAIN_BIT"
        fi

        for o in \$EXTRA_DTBOS; do
            apply_one_overlay "\$o"
        done
        ;;
    stop)
        ensure_configfs

        # Remove extras first, then ask fpgautil to remove the main overlay
        for o in \$EXTRA_DTBOS; do
            remove_one_overlay "\$o"
        done

        # Ignore failures here, e.g. if no main overlay had been loaded
        fpgautil -R -n ${FPGA_FPGAUTIL_REGION} || true
        ;;
    *)
        echo "usage: \$0 {start|stop}" >&2
        exit 2
        ;;
esac
EOF
chmod 0755 ${D}${sbindir}/${BPN}-fpga-control

    install -d ${D}${systemd_unitdir}/system
    cat > ${D}${systemd_unitdir}/system/${PN}.service <<EOF
[Unit]
Description=Load legacy fpgamanager_dtg firmware bundle for ${PN}
After=local-fs.target
ConditionPathExists=${nonarch_base_libdir}/firmware/xilinx/${BPN}/${BPN}.bit.bin

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${sbindir}/${BPN}-fpga-control start
ExecStop=${sbindir}/${BPN}-fpga-control stop
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
}

FILES:${PN} += " \
    ${sbindir}/${BPN}-fpga-control \
    ${systemd_unitdir}/system/${PN}.service \
"

COMPATIBLE_MACHINE:zynq = ".*"
