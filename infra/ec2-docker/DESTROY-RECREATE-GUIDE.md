# Guia de Destroy e Recreate

## ⚠️ IMPORTANTE: Backend Protection

O projeto tem proteção contra destruição acidental dos recursos de backend:
- S3 Bucket (terraform state)
- DynamoDB Table (state locking)

## Opções de Destruição

### Opção 1: Destroy Parcial (Recomendado para Lab)

Destruir apenas a aplicação, mantendo o backend:

```bash
# Destruir recursos específicos (exceto backend)
terraform destroy \
  -target=aws_instance.docker_host \
  -target=aws_security_group.ec2_sg \
  -target=aws_iam_instance_profile.ec2_profile \
  -target=aws_iam_role_policy.secrets_manager_policy \
  -target=aws_iam_role.ec2_role \
  -target=aws_secretsmanager_secret_version.dockerhub_token_version \
  -target=aws_secretsmanager_secret.dockerhub_token \
  -target=aws_key_pair.ec2_key
```

### Opção 2: Destroy Completo (Remove Backend)

**⚠️ ATENÇÃO**: Isto destruirá TUDO, incluindo o histórico de estado!

1. **Remover proteção temporariamente:**

```bash
# Editar backend-resources.tf e comentar os blocos lifecycle:
# lifecycle {
#   prevent_destroy = true
# }
```

2. **Destruir tudo:**

```bash
terraform destroy -auto-approve
```

3. **Limpar estado local:**

```bash
rm -f terraform.tfstate*
rm -rf .terraform
```

### Opção 3: Destroy via Makefile (Mais Seguro)

Adicionar ao Makefile:

```makefile
destroy-app: ## Destroy only application resources (keep backend)
	@echo "$(YELLOW)Destroying application resources (keeping backend)...$(NC)"
	terraform destroy \
		-target=aws_instance.docker_host \
		-target=aws_security_group.ec2_sg \
		-target=aws_iam_instance_profile.ec2_profile \
		-target=aws_iam_role_policy.secrets_manager_policy \
		-target=aws_iam_role.ec2_role \
		-target=aws_secretsmanager_secret_version.dockerhub_token_version \
		-target=aws_secretsmanager_secret.dockerhub_token \
		-target=aws_key_pair.ec2_key

destroy-backend: ## Destroy backend resources (S3 + DynamoDB) - DANGEROUS!
	@echo "$(RED)⚠️  WARNING: This will destroy state history!$(NC)"
	@echo "$(RED)Are you sure? Type 'yes' to continue:$(NC)"
	@read CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		terraform destroy \
			-target=aws_s3_bucket_versioning.terraform_state \
			-target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
			-target=aws_s3_bucket_public_access_block.terraform_state \
			-target=aws_s3_bucket.terraform_state \
			-target=aws_dynamodb_table.terraform_locks; \
	else \
		echo "$(GREEN)Aborted.$(NC)"; \
	fi

destroy-all-force: ## Force destroy everything (bypass prevent_destroy)
	@echo "$(RED)⚠️  DANGER: Destroying EVERYTHING including backend!$(NC)"
	@echo "$(RED)Type 'I UNDERSTAND' to continue:$(NC)"
	@read CONFIRM; \
	if [ "$$CONFIRM" = "I UNDERSTAND" ]; then \
		terraform destroy -auto-approve -refresh=false -lock=false || true; \
		aws s3 rb s3://terraform-state-160071257600-us-east-1 --force --profile tw-poweruserplus || true; \
		aws dynamodb delete-table --table-name terraform-state-locks-ec2-docker --profile tw-poweruserplus || true; \
		rm -f terraform.tfstate*; \
		rm -rf .terraform; \
		echo "$(GREEN)All resources destroyed$(NC)"; \
	else \
		echo "$(GREEN)Aborted.$(NC)"; \
	fi
```

## Processo de Recreate Completo

### 1. Após Destroy Parcial (Backend Mantido)

```bash
# Simples - o backend já existe
make apply
```

### 2. Após Destroy Completo (Sem Backend)

```bash
# 1. Limpar configuração de backend temporariamente
mv backend.tf backend.tf.bak

# 2. Recriar infraestrutura localmente
terraform init
terraform apply

# 3. Restaurar backend
mv backend.tf.bak backend.tf

# 4. Migrar estado para backend remoto
terraform init -migrate-state

# 5. Verificar
terraform plan  # Deve mostrar "No changes"
```

## Checklist Pós-Recreate

- [ ] `terraform plan` mostra "No changes"
- [ ] `make health` retorna "Application is healthy"
- [ ] `make ssh` conecta com sucesso
- [ ] `make backend-status` mostra estado remoto
- [ ] `make docker-secret-setup` reconfigura token (se necessário)

## Problemas Comuns

### Erro: "Backend configuration changed"

**Solução:**
```bash
terraform init -reconfigure
```

### Erro: "Secret already exists"

**Solução:**
```bash
# Deletar secret antigo
aws secretsmanager delete-secret --secret-id MyTWTestToken --force-delete-without-recovery --profile tw-poweruserplus

# Recriar
make apply
make docker-secret-setup
```

### Erro: "Bucket already exists"

**Solução:**
```bash
# Esvaziar bucket
aws s3 rm s3://terraform-state-160071257600-us-east-1 --recursive --profile tw-poweruserplus

# Deletar bucket
aws s3 rb s3://terraform-state-160071257600-us-east-1 --profile tw-poweruserplus

# Recriar
terraform apply
```

## Recomendações

### Para Ambiente de Lab/Dev
- Use **Opção 1** (Destroy Parcial)
- Mantém o backend para histórico
- Mais rápido para testar mudanças

### Para Ambiente de Produção
- **NUNCA** destrua o backend
- Use `prevent_destroy = true` (já configurado)
- Faça backups regulares do estado

### Para Reset Completo
- Use **Opção 2** (Destroy Completo)
- Apenas quando necessário
- Documente o processo
