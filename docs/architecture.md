# Arquitetura e responsabilidades — Infraestrutura Operaon

## Propósito

Topologia de ambientes, rede, deploy, observabilidade, secrets, bancos e políticas operacionais. O repositório não expõe um serviço de domínio próprio.

## Boundary de responsabilidade

| Dentro do boundary | Fora do boundary |
| --- | --- |
| Persistência e regras do domínio de Infraestrutura Operaon | Regras pertencentes a outros owners |
| Validação de tenant, organização e autorização | Confiança em dados não assinados do cliente |
| Auditoria das mutações relevantes | Alterações diretas no banco de outro módulo |
| Contratos de integração versionados | Recalcular estados oficiais de outro owner |

## Topologia

```mermaid
flowchart LR
  Client[Cliente ou serviço autorizado] --> Boundary[Infraestrutura Operaon]
  Boundary --> Identity[Identity / JWT]
  Boundary --> Tenant[Tenant & Organization]
  Boundary --> Audit[Audit & Activity]
  Boundary -. eventos .-> Reporting[Reporting & Analytics]
```

## Dependências autorizadas

Todos os serviços publicados e respectivos provedores de infraestrutura.

Toda dependência deve utilizar o contrato transversal de comunicação, audience e scope mínimos. Nenhum módulo deve abrir acesso direto ao banco de outro módulo.

## Ownership e dados

Módulos devem permanecer em rede privada; portas, secrets e rotas devem ser declarados por ambiente e validados em CI. Dados persistidos neste repositório devem possuir tenant/organization quando o domínio for multi-tenant, chaves únicas apropriadas, migrations versionadas e trilha de auditoria para alterações sensíveis.

## Evolução

Mudanças de boundary, ownership, estado ou contrato devem ser registradas em ADR antes da implementação. Mudanças incompatíveis exigem nova versão de contrato e janela de compatibilidade.

## Referências

[1]: https://github.com/operaon/infra "Repositório Infraestrutura Operaon"
[2]: https://github.com/operaon/api "API Gateway Operaon"
[3]: https://github.com/operaon/identity "Identity Operaon"
