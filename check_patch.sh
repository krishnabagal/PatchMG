#!/bin/bash
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
# Script Name: check_update.sh
# Date: Apr 11th, 2019. 
# Modified: NA
# Versioning: NA
# Author: Krishna Bagal.
# Info: Check System,Security and Important updates and send it to Slack Channel.
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
DATEnTIME=`date +%Y_%m_%d-%H:%M`
DATE=`date +%Y_%m_%d`
HOSTNAMEE=`hostname -f`
HOSTIP=`/sbin/ip route get 1 | awk '{print $NF;exit}'`
UPTIME=`/usr/bin/uptime`
OSVERSION=$(cat /etc/issue |awk {'print $1" "$2'})
CURRENTDATE=`date`
KERNELVERSION=`/bin/uname -r`
APT="/usr/bin/apt-get"
TOTALPKG=`/usr/bin/dpkg -l |wc -l`
HOLDPKG=`/usr/bin/dpkg -l |grep -i ^h |wc -l`
PKGSTATUS=`/usr/bin/apt-get -s dist-upgrade | grep "^[[:digit:]]\+ upgraded"`
SECUTIRYUPDATE=`/usr/bin/apt-get -s dist-upgrade| grep "^Inst" | grep -i security |wc -l`

for a in `/usr/bin/apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }'`; do apt-cache show $a |grep -iA4 "Version" |grep -i Priority |uniq ; done  |sort -n |uniq -c |awk {'print $3": "$1'} >/tmp/patchdetails

NORMALUPDATE=`/usr/bin/apt-get -s dist-upgrade| grep "^Inst" | grep -v security |wc -l`
IMPPORITY=$(cat /tmp/patchdetails |grep -i important |awk {'print $NF'})
OPTPORITY=$(cat /tmp/patchdetails |grep -i optional |awk {'print $NF'})
REQPORITY=$(cat /tmp/patchdetails |grep -i required |awk {'print $NF'})
STANDARDPORITY=$(cat /tmp/patchdetails |grep -i standard |awk {'print $NF'})
EXTRAPORITY=$(cat /tmp/patchdetails |grep -i extra |awk {'print $NF'})
IMPPKGLIST=$(for a in `/usr/bin/apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }'`; do echo $a;apt-cache show $a |grep -iA4 "Version" |grep -i Priority |grep -i import |uniq |grep -i import ;done  |grep -iB1 import |grep -v '^--'  |grep -iv priority |sed 's|$|,|g' |tr -d '\n')
SECURITYPKGLIST=$(/usr/bin/apt-get -s dist-upgrade| grep "^Inst" | grep -i security |awk {'print $2'} |sed 's|$|,|g' |tr -d '\n')
if [ -f /var/run/reboot-required ]; then
	REBOOT="Yes"
else
	REBOOT="No"
fi
curl -X POST \
  https://<SLACK-HOOK-URL> \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
    "attachments": [
        {
            "fallback": "Patch Details",
            "text": ": : Patch Report : :",
            "fields": [
                {
                    "title": "Hostname:",
                    "value": "'"$HOSTNAMEE"'",
                    "short": true
                },
                {
                    "title": "IP",
                    "value": "'"$HOSTIP"'",
                    "short": true
                },
                {
                    "title": "OS",
                    "value": "'"$OSVERSION"'",
                    "short": true
                }	
            ],
			
            "color": "#145a32"
        },
                {
            "fields": [
                {
                    "title": "Total Packges Installed On System:",
                    "value": "'"$TOTALPKG"'",
                    "short": true
                },
                {
                    "title": "Total Hold Packges:",
                    "value": "'"$HOLDPKG"'",
                    "short": true
                },
                {
                    "title": "Current Stats:",
                    "value": "'"$PKGSTATUS"'",
                    "short": true
                }       
            ],
                        
            "color": "#6e2c00"
        },
		       {
            "fields": [
                {
                    "title": "Important Updates:",
                    "value": "'"$IMPPORITY"'",
                    "short": true
                },
                {
                    "title": "Optional Updates:",
                    "value": "'"$OPTPORITY"'",
                    "short": true
                },
				{
                    "title": "Required Updates:",
                    "value": "'"$REQPORITY"'",
                    "short": true
                },
				{
                    "title": "Standard Updates:",
                    "value": "'"$STANDARDPORITY"'",
                    "short": true
                },
				{
                    "title": "Extra Updates:",
                    "value": "'"$EXTRAPORITY"'",
                    "short": true
                }
				           ],
			
            "color": "#6e2c00"
        },
		       {
            "fields": [
				{
                    "title": "Total Security Updates:",
                    "value": "'"$SECUTIRYUPDATE"'",
                    "short": true
                },
                                {
                    "title": "Security Packages:",
                    "value": "'"$SECURITYPKGLIST"'",
                    "short": true
                },
				{
                    "title": "Important Packages:",
                    "value": "'"$IMPPKGLIST"'",
                    "short": true
                }
            ],		
            "color": "#F35A00"
        },
                       {
            "fields": [
                                {
                    "title": "Reboot Required:",
                    "value": "'"$REBOOT"'",
                    "short": true
                },
            ],          
            "color": "#4a235a"
        }
    ]
}'
