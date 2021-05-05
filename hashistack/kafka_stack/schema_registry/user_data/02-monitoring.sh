# Install netdata and expose the ui to network. Need to install a agent to export this data to prometheus
# Netdata is not designed to be exposed to potentially hostile
# networks.See https://github.com/firehol/netdata/issues/164
apt install -y netdata && \
sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/g' /etc/netdata/netdata.conf
