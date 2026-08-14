# Contratos de infraestrutura

A infraestrutura deve provisionar API Gateway, rede privada, service discovery, bancos, secrets, observabilidade e políticas de deploy.

## Interfaces

| Interface | Regra |
| --- | --- |
| Entrada pública | Apenas Gateway e frontends autorizados |
| Rede interna | Serviços acessíveis somente por allowlist e autenticação de serviço |
| Banco | Um banco/schema por owner, sem acesso cruzado informal |
| Secrets | Secret manager/KMS/Vault, rotação e auditoria |
| Deploy | Migrations compatíveis, readiness, rollout e rollback documentados |

## Inconsistências a resolver antes de produção

A auditoria dos templates atuais identificou possíveis colisões de porta: Integration e Notification declaram "4720", e Entitlements e Media declaram "4770". O Pay declara "4200" no template local, enquanto referências arquiteturais anteriores utilizaram "4500". Esses valores devem ser reconciliados no inventário de deployment antes de publicar um ambiente compartilhado.

## Referências

[1]: https://github.com/operaon/infra "Repositório Infraestrutura Operaon"
[2]: https://github.com/operaon/api "API Gateway Operaon"
[3]: https://github.com/operaon/identity "Identity Operaon"
