#!/bin/bash
#ubuntu@54.226.135.174
#  check sshpass -p '<password>' <ssh/scp command>
SERVERIP1=$1
scp ./setremote.sh ubuntu@$SERVERIP1:~/
ssh ubuntu@$SERVERIP1 'sudo ./setremote.sh $SERVERIP1'
mkdir ./copy2client
scp ubuntu@$SERVERIP1:~/copy2client/* ./copy2client/
REPLSTR="s/remote my-server-1 1194/remote $SERVERIP1 1194/g"
sed -i "$REPLSTR" ~/openvpn/copy2client/client.conf
cd ~/openvpn/copy2client
cp ca.crt laptopubuntu.crt laptopubuntu.key client.conf /etc/openvpn
/etc/init.d/openvpn restart
openvpn /etc/openvpn/client.conf   # sudo
