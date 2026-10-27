#!/bin/sh
# Runs after board/tezuka/common/post-build.sh for the Shonan_Lite DATV builds
# (configs/plutoplus_shonan_defconfig and plutoplus_shonan_dvb_defconfig).
set -e

BOARD_DIR="$(dirname "$0")"

if [ -e "${TARGET_DIR}/etc/init.d/S60maia-httpd" ]; then
	# lighttpd takes port 80 for the DATV PHP pages and proxies the rest to
	# maia-httpd (etc/lighttpd/lighttpd.conf), so maia-httpd moves to 8000.
	grep -q -- '--listen 0.0.0.0:80 ' "${TARGET_DIR}/etc/init.d/S60maia-httpd"
	sed -i 's/--listen 0\.0\.0\.0:80 /--listen 127.0.0.1:8000 /' "${TARGET_DIR}/etc/init.d/S60maia-httpd"
else
	# No Maia-SDR (plutoplus_shonan_dvb): nothing to proxy to; lighttpd
	# serves the Tezuka Dashboard (/root/index.html, MQTT over websocket)
	# itself for everything that is not a DATV page.
	CONF="${TARGET_DIR}/etc/lighttpd/lighttpd.conf"
	grep -q 'proxy.server = ( "" => ( ( "host" => "127.0.0.1", "port" => 8000 ) ) )' "${CONF}"
	sed -i -e 's|^\tproxy.server = .*|\tserver.document-root = "/root"|' \
		-e '/^\tproxy.header = /d' "${CONF}"
	echo 'index-file.names = ( "index.html" )' >> "${CONF}"
fi

if [ -e "${TARGET_DIR}/root/pluto_dvb.fpga" ]; then
	# plutoplus_dvb bitstream: the TX DAC path goes through the FPGA DVB-S2
	# encoder, driven by pluto_stream. udpts.sh / rtmppluto.sh keep calling
	# /root/pluto_dvb, now the stand-in that feeds pluto_stream; the software
	# modulator stays as pluto_dvb.sw for its TS bitrate calculation (-d).
	mv "${TARGET_DIR}/root/pluto_dvb" "${TARGET_DIR}/root/pluto_dvb.sw"
	mv "${TARGET_DIR}/root/pluto_dvb.fpga" "${TARGET_DIR}/root/pluto_dvb"
	chmod 755 "${TARGET_DIR}/root/pluto_dvb.sw"
fi

# USB network defaults to CDC-NCM (macOS and Windows 10 2004 or later work
# without a driver); usb_ethernet_mode in the u-boot env still overrides it.
sed -i 's/usb_ethernet_mode 2> \/dev\/null || echo rndis/usb_ethernet_mode 2> \/dev\/null || echo ncm/' \
	"${TARGET_DIR}/etc/init.d/S23udc" "${TARGET_DIR}/etc/init.d/S40network"

# Firmware name: make clear this is the Shonan_Lite / Portsdown 4 build,
# not a tezuka release. /opt/VERSIONS "device-fw" feeds the USB drive
# info.html (S45msd), the iiod fw_version context attribute (S23udc) and
# the Tezuka Dashboard; the tezuka version stays as "base".
# board/tezuka/shonan/VERSION holds our own version number.
SHONAN_VER=$(cat "${BOARD_DIR}/VERSION")
SHONAN_COMMIT=$(cd "${BOARD_DIR}" && (git rev-parse --short=4 HEAD 2>/dev/null || echo unknown))
EDITION=ShonanLite-Portsdown4
[ -e "${TARGET_DIR}/root/pluto_dvb.sw" ] && EDITION=ShonanLite-Portsdown4-FPGA
FW_NAME="${EDITION}_v${SHONAN_VER}-${SHONAN_COMMIT}"
BASE=$(grep '^device-fw ' "${TARGET_DIR}/opt/VERSIONS" | cut -d ' ' -f 2)
sed -i "s/^device-fw .*/device-fw ${FW_NAME}/" "${TARGET_DIR}/opt/VERSIONS"
echo "base ${BASE}" >> "${TARGET_DIR}/opt/VERSIONS"

# Login banner. Portsdown 4 (scripts/pluto_fw_version.sh) shows the first
# line starting with "v" that a plain "ssh root@pluto" prints.
sed -i "s/^Version #BUILD#/Version ${FW_NAME} (base ${BASE})/" "${TARGET_DIR}/etc/motd.plain"
{
	echo "Shonan_Lite / Portsdown 4 edition for Pluto+"
	echo "v${SHONAN_VER}-${EDITION}-${SHONAN_COMMIT}"
} >> "${TARGET_DIR}/etc/motd.plain"

# Shown in the DVB service provider name by udpts.sh / rtmppluto.sh
date +"%d%m" > "${TARGET_DIR}/www/fwversion.txt"
(cd "${BOARD_DIR}" && git log --pretty=oneline --abbrev-commit -20) > "${TARGET_DIR}/www/releasenote.txt" || true

chmod 755 "${TARGET_DIR}"/root/*.sh "${TARGET_DIR}/root/pluto_dvb" "${TARGET_DIR}/usr/bin/tsp"
