# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --cluster-tag-key "${consul_cluster_tag_key}" --cluster-tag-value "${consul_cluster_tag_value}"

# Define a simple healthcheck to use with consul
cat > service.json <<EOL
{
  "service": {
    "name": "openvpn"
  }
}
EOL

# Register Airflow in Consul services
consul services register service.json