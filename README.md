# Hashistack

> Yuri Niitsuma <ignitzhjfk@gmail.com>

## Consul

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

Dê uma bizoiada dos serviços no consul [http://consul.service.consul:8500](http://consul.service.consul:8500)

### Criar uma instância postgres

Utilizar como exemplo em adicionar o banco no VAULT

```shell
terraform apply -auto-approve -target=module.hashistack.module.postgres
```

## Vault

Inicializar o Vault. Acesse o IP de um nó do vault

```shell
ssh -i ~/.ssh/personal/development.pem ubuntu@<IP_DE_UM_VAULT>
```

Gerar as chaves iniciais

```shell
vault operator init
```

Guarde chaves geradas. (Abaixo é apenas um exemplo)

```shell
Unseal Key 1: e5lhlNA8Iaz5daZOcUKdR2ef0RivRNcmYDh9iUUzgr25
Unseal Key 2: 0O9IQaapBIRLynbn8+TxNXBaHPryzcRyPqmnynH9aYEE
Unseal Key 3: IsZiG1iRao+KvvRyAv8I/fjd0iCi9OhNUejEC/nG52iG
Unseal Key 4: LxZo7d2MoSzRtT0ZYbAPLf6YEqgQbK++EQIt3C/LP5qr
Unseal Key 5: wLgCXJNYIX6Atarj0qQtO2Ok+8mnA0GHRLI8tilwt7jH

Initial Root Token: s.zezhniD1x8ZpfFCHJANhRztB
```

Rode `vault operator unseal` para tirar o selo do vault. É necessário fazer isto em cada nó do Vault.

OPCIONAL: Acesse o UI que é mais intuitivo [https://<IP_DO_VAULT>:8200](https://<IP_DO_VAULT>:8200)

Após isso o vault estará acessível na url [https://vault.service.consul:8200](https://vault.service.consul:8200)

### Enable database engine

```shell
export VAULT_ADDR=https://vault.service.consul:8200
export VAULT_TOKEN=s.zezhniD1x8ZpfFCHJANhRztB
# Se reclamar do tls
export VAULT_SKIP_VERIFY=true
```

DUMMY

### Criar a conexão

O usuário precisa ser admin. Está é a única vez que a senha será exposta

```shell
vault write database/config/mydatabase \
    plugin_name=postgresql-database-plugin \
    allowed_roles="my-role" \
    connection_url="postgresql://{{username}}:{{password}}@postgres.service.consul:5432/postgres?sslmode=disable" \
    username="postgres" \
    password="postgres"
```

Criar o template do código em SQL de criação e deleção do usuário temporário.

```shell
vault write database/roles/my-role \
    db_name=mydatabase \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

Conectar no banco postgres (necessita do psql). (Senha: postgres)

```shell
psql -h postgres.service.consul -p 5432 -U postgres
```

Mostrar os usuários

```sql
\du
```

Pedir uma senha temporária no vault

```
vault read database/creds/my-role
```

## Nomad

Esse vai ser simples pra não complicar.

Fiz uma instância rodando em modo DEV no módulo `nomad_example`.

Acesso o `http://nomad.service.consul:4646` para acessar a UI do nomad

Deploy no arquivo `.nomad`

```shell
export NOMAD_ADDR='http://nomad.service.consul:4646'

cd nomad/examples
nomad job plan redis.nomad
nomad job run redis.nomad
```

Olhar no consul o serviço do redis catalogado
