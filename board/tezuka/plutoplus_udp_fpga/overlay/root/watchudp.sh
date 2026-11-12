# F5UII Gateway setup for routing through lan udp socket to minitiouner. Execute one time at pluto start
GW_ETH0=$(grep "\bgateway-eth0\b" /www/settings-receiver.txt | cut -f2 -d' ')
if expr "$GW_ETH0" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  echo "success"
  route add default gw $GW_ETH0
else
  echo "not an IP v4 format for Gateway found in settings-receiver.txt"
fi

# Restart the TX pipeline only when the content of settings.txt changes.
# Some UDP sender apps (the Pi4 one before every RX start) rewrite the file
# with the same values; restarting on every write (the old mtime check)
# re-initialised the AD9361 each time and broke a receiver on the same Pluto,
# which then restarted and rewrote the file again, in a loop.
settings_sum() { md5sum < /www/settings.txt 2>/dev/null; }
LastSum=$(settings_sum)

while :
do
CurrentSum=$(settings_sum)
if [ "$LastSum" = "$CurrentSum" ]; then
        echo No Change
else
	echo Change !!!
	LastSum=$CurrentSum
	pidffmpeg=$(ps | grep ":8282" |grep -v "grep"| cut -c1-5)
	echo PID $pidffmpeg
	kill -9 $pidffmpeg
	killall -9 tsp
	killall -9 pluto_dvb
fi
sleep 1
done
