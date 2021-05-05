# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

mkdir -pv /home/ubuntu/postgres/consul

cat > /home/ubuntu/postgres/consul/register.json <<'EOL'
{
  "service": {
    "name": "postgres",
    "port": 5432,
    "check": {
      "id": "postgres",
      "name": "Check port 5432",
      "tcp": "localhost:5432",
      "interval": "10s",
      "timeout": "1s"
    }
  }
}

EOL

consul services register /home/ubuntu/postgres/consul/register.json

echo "UserData done"
