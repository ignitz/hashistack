# Hashistack

> Yuri Niitsuma <ignitzhjfk@gmail.com>

## Usage

Antes precisa que todos as subnets tenha a tag `Type = private` ou `Type = public` a VPC tenha uma tag em Name como identificado para o terraform encontrar o VPC pelo nome.

### Criar as imagens

```shell
(cd packer && packer build vault-consul.json)
```

Pegue o AMI criado e adicionado no arquivo `terraform.tfvars`

### Criar a stack inicial Vault-Consul

Crie a stack inicial com o terraform.

```shell
terraform apply -auto-approve -target=module.hashistack.module.vault_consul
```

### Criar a VPN

Crie a VPN para termos acesso a rede

```shell
terraform apply -auto-approve -target=module.hashistack.module.openvpn-server
```

Espere a máquina se auto-configurar e copie as chaves necessárias para acessar a vpn

```
ssh -i <SUA_CHAVE_PEM> ubuntu@<IP_PUBLICO_DO_OPENVPN> "sudo cp /root/admin.ovpn /home/ubuntu/admin.ovpn"
```

```
scp -i <SUA_CHAVE_PEM> ubuntu@<IP_PUBLICO_DO_OPENVPN>:/home/ubuntu/admin.ovpn .
```

Adicione o arquivo OPENVPN no client VPN do seu uso

TODO: Adicionar solução para o Ubuntu

### Criar a stack do Kafka como exemplo

```shell
terraform apply -auto-approve -target=module.hashistack.module.kafka_stack
```
