# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

mkdir -pv /home/ubuntu/kafka-connect/consul

cat > /home/ubuntu/kafka-connect/consul/register.json <<'EOL'
{
  "service": {
    "name": "debezium",
    "port": 8083
  }
}
EOL

consul services register /home/ubuntu/kafka-connect/consul/register.json

echo "UserData done"
