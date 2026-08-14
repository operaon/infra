# Operaon — Índice da documentação da organização

Este documento é o mapa de documentação dos 21 repositórios da Operaon. Cada repositório mantém sua documentação local em "docs/INDEX.md". As decisões transversais são replicadas apenas como referência local; o código continua sendo a fonte executável.

## Repositórios

| Repositório | Tipo | Responsabilidade | Porta declarada | Documentação |
| --- | --- | --- | ---: | --- |
| [api](https://github.com/operaon/api) | gateway | Entrada pública, autenticação de borda, autorização inicial, roteamento e composição de respostas. | 3000 | [docs/INDEX.md](https://github.com/operaon/api/blob/main/docs/INDEX.md) |
| [identity](https://github.com/operaon/identity) | module | Identidade, autenticação, sessões, emissão de tokens e RBAC/ABAC dinâmico. | 4700 | [docs/INDEX.md](https://github.com/operaon/identity/blob/main/docs/INDEX.md) |
| [tenant](https://github.com/operaon/tenant) | module | Tenants, organizações, contexto jurídico/organizacional e dados de cobrança. | 4740 | [docs/INDEX.md](https://github.com/operaon/tenant/blob/main/docs/INDEX.md) |
| [clinical](https://github.com/operaon/clinical) | module | Pacientes, atendimentos e fatos clínicos autorizados. | 4710 | [docs/INDEX.md](https://github.com/operaon/clinical/blob/main/docs/INDEX.md) |
| [agend](https://github.com/operaon/agend) | module | Appointments, reservas, duração e autoridade temporal dos serviços. | 4300 | [docs/INDEX.md](https://github.com/operaon/agend/blob/main/docs/INDEX.md) |
| [catalog](https://github.com/operaon/catalog) | module | Produtos, serviços, itens, preços vigentes, moeda e regras comerciais. | 4400 | [docs/INDEX.md](https://github.com/operaon/catalog/blob/main/docs/INDEX.md) |
| [crm](https://github.com/operaon/crm) | module | Relacionamento, leads, contatos e processos comerciais. | 4100 | [docs/INDEX.md](https://github.com/operaon/crm/blob/main/docs/INDEX.md) |
| [chat](https://github.com/operaon/chat) | module | Conversas, mensagens e comunicação em tempo real. | 4000 | [docs/INDEX.md](https://github.com/operaon/chat/blob/main/docs/INDEX.md) |
| [faturament](https://github.com/operaon/faturament) | module | Obrigação financeira, vendas, itens, preço congelado, contas a receber, baixa, estorno e conciliação. | 4600 | [docs/INDEX.md](https://github.com/operaon/faturament/blob/main/docs/INDEX.md) |
| [pay](https://github.com/operaon/pay) | module | Checkout, transações, integração com provedor, webhooks, confirmação, falha, estorno e chargeback. | 4200 | [docs/INDEX.md](https://github.com/operaon/pay/blob/main/docs/INDEX.md) |
| [entitlements](https://github.com/operaon/entitlements) | module | Ledger de créditos, reserva, consumo, liberação e reembolso de sessões. | 4770 | [docs/INDEX.md](https://github.com/operaon/entitlements/blob/main/docs/INDEX.md) |
| [equipment](https://github.com/operaon/equipment) | module | Equipamentos, número de série, QR Code, reserva, check-in, check-out, utilização e excedentes. | 4780 | [docs/INDEX.md](https://github.com/operaon/equipment/blob/main/docs/INDEX.md) |
| [notification](https://github.com/operaon/notification) | module | Entrega de notificações e mensagens por canais autorizados. | 4720 | [docs/INDEX.md](https://github.com/operaon/notification/blob/main/docs/INDEX.md) |
| [integration](https://github.com/operaon/integration) | module | Conectores externos, credenciais de integração, health checks e orquestração de integrações. | 4720 | [docs/INDEX.md](https://github.com/operaon/integration/blob/main/docs/INDEX.md) |
| [audit](https://github.com/operaon/audit) | module | Trilha imutável de auditoria administrativa, financeira, operacional e de segurança. | 4750 | [docs/INDEX.md](https://github.com/operaon/audit/blob/main/docs/INDEX.md) |
| [reporting](https://github.com/operaon/reporting) | module | Read models, indicadores, relatórios e análises derivadas. | 4760 | [docs/INDEX.md](https://github.com/operaon/reporting/blob/main/docs/INDEX.md) |
| [media](https://github.com/operaon/media) | module | Metadados, upload, download, objetos físicos e controle de arquivos. | 4770 | [docs/INDEX.md](https://github.com/operaon/media/blob/main/docs/INDEX.md) |
| [frontend_adm](https://github.com/operaon/frontend_adm) | frontend | Interface administrativa para operação de tenants, organizações, permissões e módulos autorizados. | 5173 | [docs/INDEX.md](https://github.com/operaon/frontend_adm/blob/main/docs/INDEX.md) |
| [frontend_client](https://github.com/operaon/frontend_client) | frontend | Interface do cliente para agenda, serviços, pagamentos, arquivos e acompanhamento de solicitações. | 5175 | [docs/INDEX.md](https://github.com/operaon/frontend_client/blob/main/docs/INDEX.md) |
| [frontend_site](https://github.com/operaon/frontend_site) | frontend | Site público, apresentação de serviços e entrada de jornadas públicas. | 5173 | [docs/INDEX.md](https://github.com/operaon/frontend_site/blob/main/docs/INDEX.md) |
| [infra](https://github.com/operaon/infra) | infra | Topologia de ambientes, rede, deploy, observabilidade, secrets, bancos e políticas operacionais. | — | [docs/INDEX.md](https://github.com/operaon/infra/blob/main/docs/INDEX.md) |

## Padrões

A Operaon utiliza Markdown para explicações, ADRs para decisões, OpenAPI para REST, AsyncAPI e JSON Schema para eventos, Mermaid para diagramas e runbooks para operação. Nenhum segredo real, token, senha, chave privada ou dado pessoal deve ser incluído.

## Ownership financeiro

Billing é owner da obrigação e dos valores devidos; Pay é owner do processamento do pagamento; Entitlements é owner do ledger de créditos e sessões. Catalog fornece preço vigente, Agend fornece autoridade temporal, Equipment fornece fatos operacionais, Audit registra decisões e Reporting projeta dados derivados.

## Segurança transversal

Todos os módulos e a API utilizam o contrato comum de headers e webhooks. A evolução planejada é rede privada, mTLS por serviço, JWT com audience/scope, rotação de secrets e auditoria de alterações.

## Inconsistências de ambiente identificadas

A auditoria encontrou possíveis colisões nos templates atuais: Integration e Notification declaram `4720`; Entitlements e Media declaram `4770`; e Pay declara `4200` no template local, embora referências anteriores tenham usado `4500`. Esses valores devem ser reconciliados no inventário de deployment antes de um ambiente compartilhado.

## Referências

[1]: https://github.com/operaon "Organização Operaon"
