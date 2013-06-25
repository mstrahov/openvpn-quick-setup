openvpn-quick-setup
===================

Script for a quick openvpn tunnel setup on ubuntu server/client

Openvpn has to be installed on the client, e.g.  sudo apt-get install -y openvpn

On the client machine 

1) copy both scripts to ~/openvpn

2) sudo ptoremote.sh <IP_OF_A_REMOTE_SERVER>

setremote.sh will be copied to a remote server, which will be set up as an openvpn server.  Key pairs are generated on the server and copied back to the client, open vpn tun is started automatically on the client machine

Tested on Ubuntu 12.04


Refs:
https://docs.google.com/document/d/1Ol0kC9bgbBh2zlohtBP7uZnzioZ4sShIcENgTwq5Ot0/edit?pli=1

