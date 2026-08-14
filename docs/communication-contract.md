# Contrato de comunicação — Infraestrutura Operaon

## Escopo

Este repositório segue o contrato transversal Operaon para consumo de APIs, propagação de contexto, eventos operacionais e webhooks. Frontends consomem exclusivamente o API Gateway; infraestrutura provisiona e aplica as políticas, sem assumir ownership de domínio.

## Headers

Os headers canônicos são Authorization, X-Service-Id, X-Key-Id, X-Protocol-Version, X-Tenant-Id, X-Organization-Id, X-Correlation-Id, X-Request-Id, X-Source-System, X-Source-Id, X-Event-Id, X-Event-Type, X-Event-Version e Idempotency-Key conforme o contexto.

## Webhooks

Webhooks utilizam X-Webhook-Id, X-Webhook-Key-Id, X-Webhook-Timestamp, X-Webhook-Nonce, X-Webhook-Signature, X-Event-Type, X-Event-Version, X-Correlation-Id e X-Delivery-Attempt. A assinatura, replay protection e deduplicação devem ser validadas no boundary de backend.

## Segurança

Frontends não recebem segredos de backend e não são boundary de autorização. Infraestrutura entrega credenciais por secret manager/KMS/Vault, mantém serviços privados e suporta rotação versionada.

## Referências

[1]: https://github.com/operaon "Organização Operaon"
