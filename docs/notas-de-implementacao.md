# Notas de implementação

O código deste repositório não tem comentários. O que não dá para deduzir lendo o código — o porquê de uma
escolha, restrições externas, contratos com os outros repositórios — fica registrado aqui, organizado por
arquivo.

---

## `providers.tf`

A rede provisionada por oficina-infra-k8s é lida do SSM Parameter Store, em vez de `terraform_remote_state`: isso
evita dar a este repositório acesso de leitura ao state do outro e mantém o contrato entre as stacks explícito e
inspecionável pelo console da AWS.

## `rds.tf`

- `random_password` sem caracteres especiais: a senha entra numa connection string
  (`postgresql://user:senha@host/db`), e caracteres como `%`, `#`, `?` e `:` mudam o significado da URL e quebram
  o parser do Prisma de formas difíceis de diagnosticar. 40 caracteres alfanuméricos dão ~238 bits de entropia —
  mais do que suficiente, e sem escape nenhum.
- Grupo de parâmetros próprio: sem ele, não dá para ligar o log de queries lentas, base do painel de performance de
  banco no New Relic. `log_min_duration_statement = 1000` loga toda query acima de 1s.
- `backup_window = "06:00-07:00"` está em UTC: 03:00–04:00 BRT, fora do horário da oficina.
- `skip_final_snapshot` e `apply_immediately` ligados: no lab, destruir é rotina; num ambiente real, ambos seriam o
  oposto.

## `security.tf`

Dois grupos, para que o acesso ao banco seja concedido por identidade, e não por faixa de IP:

| Security group | Papel |
| --- | --- |
| `db_client` | "Crachá": quem o anexa ganha acesso ao banco. A Lambda de autenticação usa este, lendo o ID pelo SSM. |
| `database` | SG do RDS. Só aceita a porta 5432 vinda do SG dos nós do EKS e do SG de cliente. Sem CIDR aberto, sem `0.0.0.0/0`. |

O RDS não inicia conexões de saída, mas o SG exige uma regra de egress explícita para não herdar o "permitir tudo"
padrão — daí a regra `database_none`, apontada para `127.0.0.1/32`.

## `ssm.tf`

Contrato com os demais repositórios:

| Consumidor | Parâmetros lidos |
| --- | --- |
| oficina-mvp | `database_url`, no deploy, para criar o Secret do Kubernetes |
| oficina-auth-lambda | `database_url` e `db_client_security_group_id` |

- SecureString usa a chave KMS gerenciada da AWS (`alias/aws/ssm`), que é gratuita. Secrets Manager cobraria
  US$0,40 por segredo/mês e ofereceria rotação automática — desnecessária no escopo do desafio.
- `database_url` é publicada pronta, no formato que o Prisma espera, para que nenhum consumidor remonte a URL e erre
  a codificação.
- `db_client_security_group_id` é o "crachá" de acesso ao banco: a Lambda anexa esse SG à sua ENI.

## `terraform.tfvars.example`

Copie para `terraform.tfvars` e ajuste se necessário. A rede (VPC e subnets privadas) **não** é configurada aqui:
vem do SSM, publicada pela stack oficina-infra-k8s.

| Variável | Observação |
| --- | --- |
| `environment` | `prod` ou `homolog` |
| `engine_version` | Só a major; a AWS descontinua versões menores |
| `instance_class` | `db.t3.micro` é elegível ao free tier (750h/mês) |
| `allocated_storage` | O free tier cobre até 20 GB |
| `max_allocated_storage` | Teto do autoscaling de storage; `0` desliga |
| `multi_az`, `deletion_protection` | `false`: ligados, dobrariam o custo e atrapalhariam o destroy rotineiro do lab |

## `.gitignore`

- `terraform.tfvars` carrega valores específicos do ambiente e, eventualmente, segredos: o `.example` é versionado;
  o real, não. O plano salvo por `terraform plan -out` também é ignorado.
- O `.terraform.lock.hcl` **é** versionado de propósito: garante que CI e devs resolvam exatamente as mesmas versões
  de providers.

## CI — `.github/workflows/terraform.yml`

- O resumo do banco usa `terraform-bin` em vez de `terraform`: o wrapper do `setup-terraform` (necessário para
  comentar o plan no PR) acrescenta linhas extras à saída capturada por `$(terraform output)`.
- As actions são fixadas por SHA de commit, com a versão legível no comentário `# vX.Y.Z` ao lado de cada `uses:`.
  O `.github/dependabot.yml` mantém os SHAs atualizados; sem ele, o pin congelaria as actions para sempre.
