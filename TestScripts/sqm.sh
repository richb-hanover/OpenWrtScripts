DOWNLOADSPEED=8264
UPLOADSPEED=911
WANIF=eth0
echo 'Setting SQM to' $DOWNLOADSPEED/$UPLOADSPEED 'kbps down/up'
uci set sqm.@queue[0].interface=$WANIF
uci set sqm.@queue[0].enabled=1
uci set sqm.@queue[0].download=$DOWNLOADSPEED
uci set sqm.@queue[0].upload=$UPLOADSPEED
uci set sqm.@queue[0].script='simple.qos' # Already the default
uci set sqm.@queue[0].qdisc='fq_codel'
uci set sqm.@queue[0].itarget='auto'
uci set sqm.@queue[0].etarget='auto'
uci set sqm.@queue[0].linklayer='atm'
uci set sqm.@queue[0].overhead='44'
uci commit sqm