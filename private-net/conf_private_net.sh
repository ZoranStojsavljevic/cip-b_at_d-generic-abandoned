#!/bin/bash
# Copyright (C) 2018, Siemens AG, Zoran Stojsavljevic
# SPDX-License-Identifier:	AGPL-3.0
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

echo "START: conf_private_net.sh"

## Configure network interfaces
## sudo copy ./interfaces /etc/network/interfaces
## sudo apt-get install ndiswrapper ndiswrapper-dkms ndiswrapper-source

## Put some additional useful packages into VM
## sudo apt-get install usbutils usbip-utils

#!/bin/bash

echo "START test script: test.sh"

## [1] Check if there is a route to www/0.0.0.0, so the necessary setup could be performed
T_VAR=`ip route show | grep default | awk '{print $1}'`

echo "default route installed? $T_VAR"

if [ "$T_VAR" != "default" ]; then
	## More code to check eth0 i/f and specific VBox gw IP address must be added here
	ip route add default via 10.0.2.2 dev eth0
	sleep 1 ## wait for ip route add default to perform!
	T_VAR=`ip route show | grep default | awk '{print $1}'`
	if [ "$T_VAR" != "default" ]; then
		exit 127
	fi
fi

## Test along the execution
ip route show > /dev/null

## [2] Test eth2 interface, since this one (so far) is used as pass-through!

T_VAR=`ifconfig -a | grep "eth2" | awk '{print $1}' | sed 's/://g'`

if [ "$T_VAR" != "eth2" ]; then
        echo "VMM USB/ETH passthrough mechanism failed!"
        exit 127
fi

T_VAR=`ifconfig -a eth2 | grep 'inet ' | awk '{print $2}'`

if [ -z "$T_VAR" ]; then
        ## give to eth2 the formal static address for DHCP init
        ifconfig eth2 192.168.15.2 up
fi

## Test along the execution
ifconfig eth2 > /dev/null

## [3] dnsmasq service, running here as server

T_VAR=`apt search dnsmasq | grep installed | head -1 | awk '{print $4}'` > /dev/null

## Test along the execution
echo "dnsmasq installed? $T_VAR"

if [ "$T_VAR" != "[installed]" ]; then
        ## installation of dnsmasq must be performed - for the private VMM passthrough device network!
	echo "Installing: apt-get install dnsmasq"
        apt-get install dnsmasq
fi

## Here, the specification is on which interface dhcpd service will start???

if [ ! -f /etc/dnsmasq.conf ]; then
        cp  ./dnsmasq.conf /etc/dnsmasq.conf
        cat /etc/dnsmasq.conf
fi

## start dnsmasq service!
systemctl restart dnsmasq.service&

## wait here until dnsmasq service does not finish configuring
wait %1

## [4] Processing tftpd server

T_VAR=`which in.tftpd`

## Test along the execution
echo "tftpd installed? $T_VAR"

if [ "$T_VAR" != "/usr/sbin/in.tftpd" ]; then
        ## installation of tftpd-hpa must be performed!
	echo "Installing: apt-get install tftpd-hpa"
        apt-get install tftpd-hpa
fi

## Does tftpd config file exist?
if [ -f /etc/default/tftpd-hpa ]; then
	T_VAR=`cat /etc/default/tftpd-hpa | grep "0.0.0.0:69" | sed 's/"/ /g' | awk '{print $2}'`
	## Test along the execution
	if [ "$T_VAR" == "0.0.0.0:69" ]; then
		echo "Listening on all network UDP ports? $T_VAR"
	else
		cp ./tftpd-hpa /etc/default/tftpd-hpa
		echo " Creating the politically correct tftpd-hpa config file"
	fi
fi

## Does tftpd runs in the VM (should)?
T_VAR=`ps -e | grep in.tftpd | head -1 | awk '{print $4}'`
echo "TFTPD process is: $T_VAR"
if [ "$T_VAR" != "in.tftpd" ]; then
	echo "Restarting in.tftpd server!"
	/etc/init.d/tftpd-hpa restart
fi

## [5] Configure and test power switch - egctl

T_VAR=`apt search egctl | grep installed | awk '{print $4}'` > /dev/null

## Test along the execution
echo "egctl is installed? $T_VAR"

if [ "$T_VAR" != "[installed]" ]; then
        ## installation of egctl must be performed!
	echo "Installing: apt-get install egctl"
        apt-get install egctl
        cp ./egtab /etc/egtab
fi

## Test egctl (do we really need such a extensive testing)?
egctl egenie on on off off
sleep 1
egctl egenie on off on off
sleep 1
egctl egenie on off off on
sleep 1
egctl egenie on off off off

## [6] Configure and test nmap application - nmap

T_VAR=`apt search nmap | grep installed | awk '{print $4}'` > /dev/null

## Test along the execution
echo "nmap is installed? $T_VAR"

if [ "$T_VAR" != "[installed]" ]; then
        ## installation of egctl must be performed!
	echo "Installing: apt-get install nmap"
        apt-get install nmap
fi

## check the network?
nmap -sP 192.168.15.*&
wait  %1
networkctl
