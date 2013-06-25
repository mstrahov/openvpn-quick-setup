#!/bin/bash
####  run under sudo # sudo sh -c “bash ./setromote.sh”   ??
## test -- ifconfig |grep -o -E 'inet addr:[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'
## ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' | grep -v '127.0.0.2' | cut -d: -f2 | awk {'print $1'} | head -n 1
# need to specify server IP as a parameter
SERVERIP1=$1     
#SERVERIP2=`ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' | grep -v '127.0.0.2' | cut -d: -f2 | awk {'print $1'} | head -n 1`

##  uncomment in more permanent installs
# apt-get update
# apt-get upgrade --show-upgraded

## Install OpenVPN, iptables and dependencies.
apt-get install -y openvpn udev iptables

## Setup Public Key Infrastructure (PKI).
cp -R /usr/share/doc/openvpn/examples/easy-rsa/ /etc/openvpn

## !!!!!!!!!!! Modify /etc/openvpn/easy-rsa/2.0/vars, mine:
####  !!!!!!!!  export KEY_ORG="somefakeorganization"
####  !!!!!!!!  export KEY_EMAIL="quiteanorgemail@gmail.com"
sed -i 's/export KEY_ORG=/#export KEY_ORG=/g' /etc/openvpn/easy-rsa/2.0/vars
sed -i 's/export KEY_EMAIL=/#export KEY_EMAIL=/g' /etc/openvpn/easy-rsa/2.0/vars
cat >> /etc/openvpn/easy-rsa/2.0/vars <<EOF
export KEY_ORG="somefakeorganization"
export KEY_EMAIL="quiteanorgemail@gmail.com"
EOF

## Build PKI and use default values.
cd /etc/openvpn/easy-rsa/2.0/
source ./vars
./clean-all       # sudo sh -c “bash ./clean-all”
./build-ca

## Build Private Keys and use default values.
./build-key-server server

## Keys for clients, repeat to create additional keys.
./build-key laptopubuntu

## Generate Diffie Hellman Parameters
./build-dh

## Relocate secure keys
cd /etc/openvpn/easy-rsa/2.0/keys/
mkdir ~/copy2client
cp ca.crt laptopubuntu.crt laptopubuntu.key ~/copy2client
cp ca.crt ca.key dh1024.pem server.crt server.key /etc/openvpn

## Configuring the Virtual Private Network
cd /usr/share/doc/openvpn/examples/sample-config-files
gunzip -d server.conf.gz
cp server.conf /etc/openvpn/
cp client.conf ~/copy2client

## Modify ~/copy2client/client.conf to reflect your configuration.
# remote my-server-1 1194
#  REPLSTR="s/remote my-server-1 1194/remote $SERVERIP1 1194/g"
#  sed -i "$REPLSTR" ~/copy2client/client.conf

#ca ca.crt
#cert client.crt   --> cert laptopubuntu.crt
#key client.key     --> key laptopubuntu.key
sed -i 's/ca ca.crt/ca \/etc\/openvpn\/ca.crt/g' ~/copy2client/client.conf
sed -i 's/cert client.crt/cert \/etc\/openvpn\/laptopubuntu.crt/g' ~/copy2client/client.conf
sed -i 's/key client.key/key \/etc\/openvpn\/laptopubuntu.key/g' ~/copy2client/client.conf
chmod 777 ~/copy2client/laptopubuntu.key

## Start OpenVPN
/etc/init.d/openvpn start

## Tunnel all traffic except DNS through the VPN

## Add to /etc/openvpn/server.conf to tunnel all traffic except DNS through the VPN
cat >> /etc/openvpn/server.conf <<EOF
push "redirect-gateway def1"
EOF


## Uncomment net.ipv4.ip_forward in /etc/sysctl.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

## Set for current session.
echo 1 > /proc/sys/net/ipv4/ip_forward

## Configure iptables to properly forward traffic through the VPN
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

## Forward DNS traffic through the VPN with DNSMasq
apt-get install -y dnsmasq

##Modify /etc/dnsmasq.conf
cat >> /etc/dnsmasq.conf <<EOF
listen-address=127.0.0.1,10.8.0.1
bind-interfaces
EOF


## Insert to /etc/rc.local
## Also insert these iptables commands to /etc/rc.local, enabling run on boot.
sed -i 's/exit 0/#exit 0/g' /etc/rc.local
cat >> /etc/rc.local <<EOF
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -A FORWARD -j REJECT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
/etc/init.d/dnsmasq
exit 0
EOF

## Add to /etc/openvpn/server.conf
cat >> /etc/openvpn/server.conf <<EOF
push "dhcp-option DNS 10.8.0.1"
EOF

## Start both.
/etc/init.d/openvpn restart
/etc/init.d/dnsmasq restart
/etc/init.d/openvpn restart
