# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

mkdir -pv /home/ubuntu/schema-registry/consul

cat > /home/ubuntu/schema-registry/consul/register.json <<'EOL'
{
  "service": {
    "name": "schema-registry",
    "port": 8081,
    "check": {
      "id": "rest",
      "name": "REST API",
      "tcp": "localhost:8081",
      "interval": "10s",
      "timeout": "5s"
    }
  }
}
EOL

consul services register /home/ubuntu/schema-registry/consul/register.json

echo "UserData done"
