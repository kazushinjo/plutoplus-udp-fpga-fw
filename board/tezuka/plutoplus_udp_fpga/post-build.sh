#!/bin/sh
# Runs after board/tezuka/common/post-build.sh for the UDP sender app DATV FPGA build
# (configs/plutoplus_udp_fpga_defconfig, DVB-S2 modulation in the FPGA).
set -e

BOARD_DIR="$(dirname "$0")"

# No Maia-SDR in this bitstream: nothing to proxy to; lighttpd serves the
# status pages (/root/index.html, MQTT over websocket) itself for everything
# that is not a DATV page.
CONF="${TARGET_DIR}/etc/lighttpd/lighttpd.conf"
grep -q 'proxy.server = ( "" => ( ( "host" => "127.0.0.1", "port" => 8000 ) ) )' "${CONF}"
sed -i -e 's|^\tproxy.server = .*|\tserver.document-root = "/root"|' \
	-e '/^\tproxy.header = /d' "${CONF}"
echo 'index-file.names = ( "index.html" )' >> "${CONF}"

if [ -e "${TARGET_DIR}/root/pluto_dvb.fpga" ]; then
	# plutoplus_dvb bitstream: the TX DAC path goes through the FPGA DVB-S2
	# encoder, driven by pluto_stream. udpts.sh / rtmppluto.sh keep calling
	# /root/pluto_dvb, now the stand-in that feeds pluto_stream; the software
	# modulator stays as pluto_dvb.sw for its TS bitrate calculation (-d).
	mv "${TARGET_DIR}/root/pluto_dvb" "${TARGET_DIR}/root/pluto_dvb.sw"
	mv "${TARGET_DIR}/root/pluto_dvb.fpga" "${TARGET_DIR}/root/pluto_dvb"
	chmod 755 "${TARGET_DIR}/root/pluto_dvb.sw"

	# Pages for this bitstream: the Tezuka dashboard relies on Maia-SDR.
	# S45msd fills in the #TOKEN# placeholders of both pages at boot. It
	# must not read the Maia-SDR version register, absent from this design.
	cp "${BOARD_DIR}/fpga_pages/info.html" "${BOARD_DIR}/fpga_pages/index.html" "${TARGET_DIR}/root/"
	cp "${BOARD_DIR}/../common/msd/paho-mqtt-min.js" "${TARGET_DIR}/root/"
	# lighttpd sends /img/ to the DATV web UI, so the status page needs its own path.
	mkdir -p "${TARGET_DIR}/root/status"
	cp "${BOARD_DIR}/../common/msd/img/style.css" "${BOARD_DIR}/../common/msd/img/base.css" "${TARGET_DIR}/root/status/"
	S45="${TARGET_DIR}/etc/init.d/S45msd"
	grep -q 'FPGA_REG=$(devmem 0x7c460004 32 2>/dev/null)' "${S45}"
	sed -i -e 's|FPGA_REG=$(devmem 0x7c460004 32 2>/dev/null)|FPGA_REG=|' \
		-e 's|^\(\s*\)patch_html_page /root/info.html /root/img/version.js|&\n\1patch_html_page /root/index.html /root/img/version.js|' "${S45}"
fi

# USB network defaults to CDC-NCM (macOS and Windows 10 2004 or later work
# without a driver); usb_ethernet_mode in the u-boot env still overrides it.
sed -i 's/usb_ethernet_mode 2> \/dev\/null || echo rndis/usb_ethernet_mode 2> \/dev\/null || echo ncm/' \
	"${TARGET_DIR}/etc/init.d/S23udc" "${TARGET_DIR}/etc/init.d/S40network"

# Firmware name: make clear this is the UDP sender app FPGA build,
# not a tezuka release. /opt/VERSIONS "device-fw" feeds the USB drive
# info.html (S45msd), the iiod fw_version context attribute (S23udc) and
# the Tezuka Dashboard; the tezuka version stays as "base".
# board/tezuka/plutoplus_udp_fpga/VERSION holds our own version number.
FW_VER=$(cat "${BOARD_DIR}/VERSION")
FW_COMMIT=$(cd "${BOARD_DIR}" && (git rev-parse --short=4 HEAD 2>/dev/null || echo unknown))
EDITION=plutoplus-udp-fpga-firm
FW_NAME="${EDITION}_v${FW_VER}-${FW_COMMIT}"
# The tezuka release this branch is based on; git describe cannot tell (the
# tezuka tags are not pushed here), so it is kept in TEZUKA_BASE and must be
# updated when upstream tezuka is merged.
BASE=$(cat "${BOARD_DIR}/TEZUKA_BASE")
sed -i "s/^device-fw .*/device-fw ${FW_NAME}/" "${TARGET_DIR}/opt/VERSIONS"
echo "base ${BASE}" >> "${TARGET_DIR}/opt/VERSIONS"

# Login banner. Portsdown 4 (scripts/pluto_fw_version.sh) shows the first
# line starting with "v" that a plain "ssh root@pluto" prints.
sed -i "s/^Version #BUILD#/Version ${FW_NAME} (base ${BASE})/" "${TARGET_DIR}/etc/motd.plain"
{
	echo "plutoplus-udp-fpga-firm: UDP-only DVB-S2 FPGA firmware for Pluto+"
	echo "v${FW_VER}-${EDITION}-${FW_COMMIT}"
} >> "${TARGET_DIR}/etc/motd.plain"

# Shown in the DVB service provider name by udpts.sh / rtmppluto.sh
date +"%d%m" > "${TARGET_DIR}/www/fwversion.txt"
# The FPGA build carries only its own name, not this repository's log.
echo "${FW_NAME}" > "${TARGET_DIR}/www/releasenote.txt"

chmod 755 "${TARGET_DIR}"/root/*.sh "${TARGET_DIR}/root/pluto_dvb" "${TARGET_DIR}/usr/bin/tsp"
