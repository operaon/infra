# Arquitetura de infraestrutura Operaon

## Responsabilidade

A infraestrutura provisiona rede, service discovery, bancos, secrets, observabilidade, deploy, backups e políticas de continuidade para a API, módulos e frontends.

## Boundary de rede

A Internet acessa somente o Gateway e as interfaces públicas. Módulos standalone permanecem em rede privada e aceitam chamadas por allowlist, mTLS quando habilitado e JWT de serviço com audience/scope.

## Dados e secrets

Cada owner possui persistência própria. Credenciais, chaves privadas, tokens de provedores e segredos de webhook devem ser entregues por secret manager/KMS/Vault. Nenhum segredo real deve ser versionado.

## Deployment

O rollout deve validar migrations compatíveis, readiness, health, conectividade, certificados, observabilidade e rollback. Ambientes devem possuir valores e credenciais próprios, mantendo os contratos iguais.

## Inconsistências identificadas

A auditoria local encontrou possíveis colisões: Integration e Notification declaram PORT=4720; Entitlements e Media declaram PORT=4770; e Pay declara PORT=4200 no template local enquanto referências anteriores utilizaram 4500. A decisão final deve ser registrada no inventário de deployment antes de um ambiente compartilhado.

## Referências

[1]: https://github.com/operaon "Organização Operaon"
