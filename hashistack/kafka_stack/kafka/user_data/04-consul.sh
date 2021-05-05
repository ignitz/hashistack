# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

mkdir -pv /home/ubuntu/kafka/consul

cat > /home/ubuntu/kafka/consul/register.json <<'EOL'
{
  "service": {
    "name": "kafka${KAFKA_ID}",
    "port": 9092
  }
}
EOL

consul services register /home/ubuntu/kafka/consul/register.json

echo "UserData done"
