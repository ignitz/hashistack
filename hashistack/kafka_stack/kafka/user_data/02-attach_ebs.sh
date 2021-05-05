apt-get install -y xfsprogs

(
    # Note on Kafka: it's better to format volumes as xfs:
    # https://kafka.apache.org/documentation/#filesystems
    # mkfs -t ext4 /dev/nvme1n1 && \
    mkfs.xfs -f /dev/nvme1n1 && \
    mkdir -pv /disk && \
    mount /dev/nvme1n1 /disk && \
    mkdir -pv /disk/data/kafka && \
    chown -R ubuntu:ubuntu /disk/data && \ # add permissions to kafka directory
    (echo $(blkid | grep /dev/nvme1 | awk '{print $2" /disk    ext4   rw,relatime     0 2"}') >> /etc/fstab)
) || exit 1
