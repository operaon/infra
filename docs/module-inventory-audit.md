# Inventário de módulos Operaon

Data da auditoria: 2026-08-14.

## Repositórios locais e remotos

Todos os diretórios abaixo possuem Git, remoto `https://github.com/operaon/<repo>.git` e branch `main` no checkout local.

| Repositório | Domínio | Descrição | Estado de organização |
| --- | --- | --- | --- |
| `api` | Gateway/API núcleo | Entrada pública, autenticação de borda, compatibilidade e montagem de rotas | Repositório privado; publicado |
| `identity` | Identity | Identidade, autenticação, RBAC e contexto multi-tenant | Standalone; publicado |
| `tenant` | Tenant & Organization | Tenants, organizações, memberships e lifecycle | Standalone; publicado |
| `clinical` | Clinical / Patient Care | Domínio clínico e cuidado do paciente | Standalone; publicado |
| `agend` | Agenda | Appointments, reservas e autoridade temporal | Standalone; publicado |
| `catalog` | Catalog | Categorias, itens e preços multi-tenant | Standalone; publicado |
| `crm` | CRM | Pipeline, contatos, empresas e deals | Standalone legado/publicado |
| `chat` | Chat | Chat 1:1/grupo, notificações, cache e upload | Standalone legado/publicado; integração ainda referenciada pelo Gateway |
| `faturament` | Billing | Vendas, itens, contratos e cobrança de excedentes | Standalone; publicado |
| `pay` | Pay | Integração de pagamentos e Smart Checkout | Standalone; publicado |
| `entitlements` | Entitlements / Session Credits | Créditos, ledger e movimentos | Standalone; publicado |
| `equipment` | Equipment & Maintenance | Ativos, QR Code, locação e manutenção | Standalone; publicado |
| `notification` | Notification & Delivery | Notificações e entrega | Standalone; publicado |
| `integration` | Integration Hub | Catálogo, credenciais e saúde de integrações | Standalone; publicado |
| `audit` | Audit & Activity | Trilhas imutáveis, atividade e retenção | Standalone; publicado |
| `reporting` | Reporting & Analytics | Relatórios, métricas e agregações | Standalone; publicado |
| `media` | Media & File Storage | Metadados, armazenamento e ciclo de vida de objetos | Standalone; publicado |
| `frontend_adm` | Frontend administrativo | Interface administrativa/tenant | Aplicação cliente; publicado |
| `frontend_client` | Frontend do cliente | Interface do paciente/cliente | Aplicação cliente; publicado |
| `frontend_site` | Site público | Site/apresentação pública | Aplicação cliente; publicado |
| `infra` | Infraestrutura | Configurações e artefatos de infraestrutura | Repositório de suporte; publicado |

## Situação remota verificada

A consulta autenticada somente para leitura à organização `operaon` retornou 21 repositórios: `agend`, `api`, `audit`, `catalog`, `chat`, `clinical`, `crm`, `entitlements`, `equipment`, `faturament`, `frontend_adm`, `frontend_client`, `frontend_site`, `identity`, `infra`, `integration`, `media`, `notification`, `pay`, `reporting` e `tenant`. Todos utilizam `main` como branch padrão.

## Observações arquiteturais

O conjunto possui 16 domínios standalone de negócio ou plataforma: Identity, Tenant & Organization, Clinical, Agend, Catalog, CRM, Chat, Billing, Pay, Entitlements, Equipment, Notification, Integration Hub, Audit & Activity, Reporting & Analytics e Media & File Storage. O `api` é o Gateway/núcleo, não deve duplicar o ownership dos standalones. Os três frontends e o repositório `infra` são componentes de suporte, não módulos de domínio.

O Gateway ainda contém referências históricas a Chat e alguns domínios locais de compatibilidade. Isso não significa necessariamente duplicação ativa, mas deve ser tratado como legado controlado e revisado durante o cutover. O Equipment possui write fence publicado para impedir novas escritas na rota legada.

Não foram contados como módulos independentes os diretórios temporários, scripts de auditoria local ou documentação existente na raiz de `api`; são artefatos de suporte.
