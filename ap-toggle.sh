#!/bin/sh
#
# ap-toggle script
# written by Dirk Brenken (dev@brenken.org)
# usage:
#   ap-toggle.sh on <radio>  => switch the AP on all radios "on", you can limit this with the optional <radio>-parm
#   ap-toggle.sh off <radio> => switch the AP on all radios "off", you can limit this with the optional <radio>-parm
# reference this script in /etc/crontabs/root and restart cron service afterwards, e.g.:
#   0 00 * * *    /usr/bin/ap-toggle.sh off
#   0 06 * * *    /usr/bin/ap-toggle.sh on
#

# This is free software, licensed under the GNU General Public License v3.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# set initial defaults
#
LC_ALL=C
PATH="/usr/sbin:/usr/bin:/sbin:/bin"
apt_ver="0.5"
apt_sysver="$(ubus -S call system board | jsonfilter -e '@.release.description')"
apt_action="${1}"
apt_radio="${2}"

. "/lib/functions.sh"

# f_prepare: gather wireless information & enable/disable AP interfaces
#
f_prepare()
{
    local config="${1}"
    local mode="$(uci -q get wireless."${config}".mode)"
    local radio="$(uci -q get wireless."${config}".device)"
    local disabled="$(uci -q get wireless."${config}".disabled)"

    if [ "${mode}" = "ap" ] && ([ -z "${apt_radio}" ] || [ "${apt_radio}" = "${radio}" ])
    then
        if [ "${apt_action}" = "on" ] && ([ -z "${disabled}" ] || [ "${disabled}" = "1" ])
        then
            uci -q set wireless."${config}".disabled=0
        elif [ "${apt_action}" = "off" ] && ([ -z "${disabled}" ] || [ "${disabled}" = "0" ])
        then
            uci -q set wireless."${config}".disabled=1
        fi
    fi
}
config_load wireless
config_foreach f_prepare wifi-iface

# commit & reload all changes, write final log message
# 
if [ -n "$(uci -q changes wireless)" ]
then
    uci -q commit wireless
    ubus call network reload
    apt_radio="${apt_radio:="all radios"}"
    logger -t "ap-toggle-[${apt_ver}] info " "AP on ${apt_radio} has been switched '${apt_action}' (${apt_sysver})"
fi
