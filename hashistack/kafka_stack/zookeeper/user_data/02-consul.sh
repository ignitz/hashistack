# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

mkdir -pv /home/ubuntu/zookeeper/consul

# cat > /home/ubuntu/zookeeper/consul/register.json <<'EOL'
# {
#   "service": {
#     "name": "zookeeper",
#     "port": 5432,
#     "check": {
#       "id": "zookeeper",
#       "name": "Check port 2181",
#       "tcp": "localhost:2181",
#       "interval": "10s",
#       "timeout": "1s"
#     }
#   }
# }
# EOL

cat > /home/ubuntu/zookeeper/consul/register.json <<'EOL'
{
  "service": {
    "name": "zookeeper${ZOO_MY_ID}",
    "port": 2181
  }
}
EOL

consul services register /home/ubuntu/zookeeper/consul/register.json

echo "UserData done"
