curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh && \
chmod +x openvpn-install.sh && \
APPROVE_INSTALL=y \
ENDPOINT=$(curl -4 ifconfig.co) \
APPROVE_IP=y \
IPV6_SUPPORT=n \
PORT_CHOICE=1 \
PROTOCOL_CHOICE=1 \
DNS=9 \
COMPRESSION_ENABLED=n \
CUSTOMIZE_ENC=n \
CLIENT=admin PASS=1 ./openvpn-install.sh

# Add DNS server to bypass to VPN client
# https://learn.hashicorp.com/tutorials/consul/dns-forwarding

apt install -y dnsmasq

cat > /etc/dnsmasq.d/10-consul <<'EOL'
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600

# Uncomment and modify as appropriate to enable reverse DNS lookups for
# common netblocks found in RFC 1918, 5735, and 6598:
#rev-server=0.0.0.0/8,127.0.0.1#8600
#rev-server=10.0.0.0/8,127.0.0.1#8600
#rev-server=100.64.0.0/10,127.0.0.1#8600
#rev-server=127.0.0.1/8,127.0.0.1#8600
#rev-server=169.254.0.0/16,127.0.0.1#8600
#rev-server=172.16.0.0/12,127.0.0.1#8600
#rev-server=192.168.0.0/16,127.0.0.1#8600
#rev-server=224.0.0.0/4,127.0.0.1#8600
#rev-server=240.0.0.0/4,127.0.0.1#8600
EOL

systemctl restart dnsmasq

# Add DNS of OpenVPN server, expected that the ip address of VPN will be 10.8.0.1
sed -i '/^push "dhcp-option DNS 8.8.8.8"/ipush "dhcp-option DNS 10.8.0.1"' /etc/openvpn/server.conf
# Disable internet gateway
sed -i 's/^push "redirect-gateway def1 bypass-dhcp"/;push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
# Add route to only VPC
sed -i '/^;push "redirect-gateway def1 bypass-dhcp"/apush "route ${vpc_ip} ${vpc_netmask}"' /etc/openvpn/server.conf


# Trying to find duplicateds 
# sed '/^push "dhcp-option DNS 8.8.8.8"/ipush "dhcp-option DNS 10.8.0.1"' /etc/openvpn/server.conf | sed -z 's/^push "dhcp-option DNS 10.8.0.1"\npush "dhcp-option DNS 10.8.0.1"/push "dhcp-option DNS 10.8.0.1"/g'

# TO create user
# sudo MENU_OPTION="1" CLIENT="YuriNiitsuma" PASS="1" ./openvpn-install.sh

systemctl restart openvpn@server.service
