# Arquitetura e processo financeiro da Operaon

## 1. Princípio arquitetural

O módulo financeiro não deve concentrar todos os comportamentos em um único serviço monolítico. A arquitetura recomendada é composta por três owners complementares: **Billing** como fonte de verdade do que é devido, faturado e recebido; **Pay** como processador de pagamentos e integração com o provedor; e **Entitlements** como fonte de verdade de créditos e consumo de sessões. Os módulos de origem informam fatos de negócio, mas não devem criar diretamente registros financeiros fora do Billing.

> **Regra central:** o Billing registra a obrigação financeira; o Pay movimenta o pagamento; o Entitlements movimenta créditos. Nenhum desses domínios deve substituir os demais.

## 2. Ownership dos domínios

| Domínio | Responsabilidade financeira ou operacional | Não deve fazer |
| --- | --- | --- |
| **Catalog** | Produtos, serviços, preços vigentes e regras comerciais configuráveis | Confirmar pagamento ou manter saldo financeiro de uma venda |
| **Tenant & Organization** | Identidade jurídica, organização, dados fiscais e perfil de cobrança | Calcular ou liquidar vendas |
| **Agend** | Appointment, reserva, data, duração e autoridade temporal | Criar cobrança com horários próprios ou controlar créditos |
| **Clinical** | Fatos clínicos, atendimento e vínculo com paciente | Definir liquidação financeira |
| **Equipment** | Equipamento, retirada, devolução, check-in, check-out e minutos efetivos | Ser fonte de verdade do preço, pagamento ou saldo de créditos |
| **Entitlements** | Emissão, reserva, consumo, liberação e reembolso de créditos | Representar dinheiro, pagamento ou valor monetário |
| **Billing** | Sale, SaleItem, descontos, preço congelado, cobranças, faturas, contas a receber, vencimentos, baixa e estornos | Capturar cartão ou falar diretamente com o adquirente |
| **Pay** | Checkout, transação no provedor, tokenização, webhook, autorização, confirmação, falha, estorno e chargeback | Definir o que o tenant deve ou alterar itens faturados |
| **Audit** | Trilha imutável de eventos administrativos, financeiros e de segurança | Ser fonte operacional de estado |
| **Reporting** | Read models, indicadores e relatórios derivados | Executar mutações financeiras |

A recomendação é **não criar imediatamente um quarto módulo financeiro genérico**. O Billing deve ser expandido como núcleo financeiro e o Pay deve permanecer especializado em pagamentos. Um módulo contábil separado somente será necessário quando houver razão para razão contábil de partidas dobradas, integração ERP, fechamento contábil, centros de custo, competência e obrigações fiscais complexas.

## 3. Componentes internos recomendados no Billing

O Billing pode continuar como um único standalone, mas deve organizar seus bounded contexts internos:

| Componente | Função |
| --- | --- |
| **Price Snapshot** | Congelar preço, moeda, quantidade, desconto e regras no momento da cobrança |
| **Charge / Sale** | Representar o valor devido por uma origem de negócio |
| **Sale Items** | Registrar cada produto, serviço, sessão ou excedente com quantidade e preço unitário |
| **Invoice** | Documento financeiro com emissão, vencimento, status e referência do tenant |
| **Accounts Receivable** | Controle do valor em aberto, pago, parcial, vencido, cancelado e estornado |
| **Payment Allocation** | Aplicar pagamentos confirmados a uma ou mais cobranças |
| **Refund / Adjustment** | Registrar devoluções, créditos, descontos posteriores e correções autorizadas |
| **Financial Events** | Outbox de eventos publicados após commit da transação |
| **Reconciliation** | Comparar Pay, Billing e liquidações do provedor |

O Billing deve guardar **preços congelados** no item da venda. Uma alteração futura no Catalog não pode modificar uma venda já criada.

## 4. Processo financeiro ponta a ponta

### 4.1. Contratação ou criação da obrigação

O processo começa quando um módulo de origem registra um fato de negócio: contratação de produto, agendamento de serviço, locação de equipamento, atendimento clínico ou consumo adicional. O módulo de origem envia ao Billing um comando interno com `tenantId`, `organizationId`, `sourceSystem`, `sourceId`, `eventId`, `correlationId`, itens, quantidade, moeda e regra de idempotência.

O Billing resolve ou valida o item do Catalog, calcula o valor conforme a regra autorizada, congela a descrição e o preço e cria a venda em estado `DRAFT` ou `ISSUED`. A criação de `Sale`, `SaleItem`, descontos e totais deve ocorrer em uma única transação. O registro deve ser único por `sourceSystem + sourceId` para impedir duas cobranças para o mesmo fato.

### 4.2. Faturamento e vencimento

Depois de criada, a obrigação pode ser imediata, pré-paga, pós-paga ou parcelada. O Billing gera a fatura ou cobrança com valor, moeda, vencimento, tenant pagador e itens. O cliente não deve receber um valor calculado diretamente pelo frontend; o frontend apenas solicita a operação e exibe o resultado autorizado pelo Billing.

### 4.3. Criação do pagamento

Quando a cobrança exige pagamento, o Gateway ou o Billing solicita ao Pay um Smart Checkout. A referência do Pay deve ser determinística e apontar para a cobrança do Billing, por exemplo:

```text
reference_id = billing:{saleId}:installment:{installmentId}
```

Para excedente de Equipment, a referência deve apontar para o fato operacional único:

```text
reference_id = equipment-overage:{rentalContractId}:{checkoutId}
```

O Pay recebe `establishmentId`, `title`, `amount` em unidade monetária aceita pelo contrato, `reference_id`, `tenantId`, `correlationId` e `sourceSystem`. O Pay não deve criar uma nova cobrança quando a mesma referência já existir com o mesmo payload.

### 4.4. Autorização, confirmação e webhook

O Pay cria a transação no provedor e devolve `PENDING`, `AUTHORIZED`, `CONFIRMED`, `FAILED` ou `CANCELED`, conforme o fluxo do provedor. A confirmação definitiva deve preferencialmente vir por webhook assinado do provedor, não apenas pela resposta síncrona do checkout.

O Pay valida assinatura do webhook, timestamp e replay, persiste o evento bruto de forma idempotente e atualiza a transação local. Depois publica um evento interno `payment.confirmed`, `payment.failed`, `payment.refunded` ou `payment.chargeback` para o Billing.

### 4.5. Baixa financeira

O Billing recebe o evento do Pay e aplica o pagamento à conta a receber. A baixa deve ser transacional e idempotente. Depois do commit, o Billing atualiza a cobrança para `PAID`, `PARTIALLY_PAID`, `OVERDUE`, `REFUNDED` ou outro estado permitido e publica o evento financeiro correspondente.

O estado financeiro do Billing não deve ser inferido diretamente pelo frontend nem por consulta isolada ao Pay. O Pay informa o resultado do processamento; o Billing mantém o significado financeiro para a organização.

### 4.6. Fluxo específico de locação Equipment

| Momento | Sistema | Operação |
| --- | --- | --- |
| Reserva | Agend | Cria appointment com horário oficial e duração |
| Reserva de crédito | Entitlements | Reserva uma unidade `SESSION` vinculada ao `appointmentId` |
| Reserva do ativo | Equipment | Associa equipamento, tenant e `agendReservationId` |
| Retirada | Equipment | Executa check-in e inicia o fato operacional |
| Uso | Equipment | Registra estado, eventos e tempo observado |
| Devolução | Equipment | Executa check-out e calcula utilização efetiva |
| Consumo | Entitlements | Consome uma unidade `SESSION` vinculada à appointment |
| Excedente | Billing | Cria venda idempotente com item, quantidade e preço congelado |
| Cobrança | Pay | Cria Smart Checkout usando `reference_id` único |
| Conciliação | Billing/Pay | Confirma pagamento, falha, estorno ou pendência |

A unidade atual é **uma sessão por appointment**. Os minutos calculados pelo Equipment servem para operação, medição e eventual precificação do excedente, mas não são convertidos em créditos fracionados. Para cobrar minutos adicionais, o Billing deve calcular o valor do item de excedente; o Entitlements continua movimentando uma sessão inteira.

### 4.7. Falha de pagamento, estorno e chargeback

Quando o pagamento falha, a cobrança permanece em `PAYMENT_PENDING` ou `PAYMENT_FAILED`, sem apagar a venda. O Billing deve controlar retentativas e vencimento. Quando há estorno, o Billing registra um `Refund` e aguarda confirmação do Pay. Quando há chargeback, a cobrança entra em `CHARGEBACK` e o evento é enviado à auditoria e aos relatórios.

O reembolso financeiro e o reembolso de crédito são operações diferentes. Um pagamento pode ser estornado no Pay e, separadamente, uma sessão pode ser devolvida no Entitlements, conforme a regra comercial autorizada.

## 5. Estados recomendados

### 5.1. Estados do Billing

| Estado | Significado |
| --- | --- |
| `DRAFT` | Obrigação criada, ainda não emitida |
| `ISSUED` | Cobrança emitida e pronta para pagamento |
| `PAYMENT_PENDING` | Pagamento iniciado, aguardando confirmação |
| `PARTIALLY_PAID` | Parte do valor foi baixada |
| `PAID` | Valor integral confirmado |
| `OVERDUE` | Vencimento ultrapassado sem quitação integral |
| `CANCELED` | Cobrança cancelada antes da liquidação |
| `REFUND_PENDING` | Estorno solicitado ao Pay |
| `REFUNDED` | Estorno confirmado |
| `CHARGEBACK` | Contestação ou chargeback confirmado |

### 5.2. Estados do Pay

O Pay deve manter estados próprios, como `CREATED`, `PENDING`, `AUTHORIZED`, `CONFIRMED`, `FAILED`, `CANCELED`, `REFUNDED` e `CHARGEBACK`. Esses estados não devem ser misturados diretamente aos estados do Billing.

### 5.3. Estados do Entitlements

O Entitlements mantém o ciclo `AVAILABLE`, `RESERVED`, `CONSUMED`, `RELEASED`, `REFUNDED` e `VOIDED` no ledger. O valor de crédito permanece inteiro e a unidade atual é `SESSION`.

## 6. Contrato de evento financeiro

Todos os eventos devem utilizar um envelope comum:

```json
{
  "eventId": "evt_01...",
  "eventType": "billing.sale.created",
  "sourceSystem": "equipment",
  "tenantId": "tenant_01...",
  "organizationId": "org_01...",
  "correlationId": "corr_01...",
  "occurredAt": "2026-08-14T23:00:00.000Z",
  "payload": {
    "sourceId": "rental_01...",
    "saleId": "sale_01...",
    "amount": 120.00,
    "currency": "BRL"
  }
}
```

Eventos devem ser publicados através de outbox depois do commit. Os consumidores devem manter inbox ou registro de eventos processados. O objetivo não é prometer entrega exatamente uma vez; o objetivo é permitir entrega pelo menos uma vez com consumidores idempotentes.

## 7. Idempotência e consistência

As operações financeiras devem aplicar quatro níveis de proteção:

| Nível | Chave ou controle | Uso |
| --- | --- | --- |
| Transporte | `Idempotency-Key` | Repetição da mesma chamada HTTP |
| Negócio | `sourceSystem + sourceId` | Mesmo fato de negócio enviado novamente |
| Evento | `eventId` | Mesmo evento publicado mais de uma vez |
| Pagamento | `reference_id` | Mesmo checkout ou cobrança no Pay |

Se uma mesma chave for reutilizada com payload diferente, o serviço deve retornar conflito de idempotência, nunca substituir silenciosamente a operação anterior. Índices únicos no banco são obrigatórios; o lookup em código sozinho não protege contra concorrência.

Todas as mutações de dinheiro devem usar transação, valores decimais ou inteiros em unidade mínima definida, moeda explícita e arredondamento centralizado. Valores monetários não devem ser calculados com `float` JavaScript.

## 8. Segurança

Os módulos não devem ser públicos. Somente o Gateway e serviços internos explicitamente autorizados devem alcançar as portas privadas. A comunicação interna deve evoluir de `X-Service-Key` para mTLS com identidade individual por serviço, mantendo JWT de serviço com `issuer`, `audience`, `scope`, `tenantId`, `organizationId` e expiração curta.

O Gateway deve remover headers internos recebidos do cliente e recriar `X-Source-System`, `X-Event-Id`, `X-Correlation-Id` e contexto de tenant. Webhooks do Pay devem validar assinatura, timestamp e replay. Dados de cartão não devem ser armazenados pela Operaon; deve-se usar tokenização e o provedor de pagamento.

O acesso administrativo financeiro deve usar RBAC/ABAC deny-by-default, dupla aprovação para estornos manuais e registro de auditoria para alterações de preço, descontos, cancelamentos, reembolsos, chargebacks e ajustes de saldo.

## 9. Conciliação e fechamento

A conciliação deve ser diária e, idealmente, incremental. O processo compara:

1. Cobranças emitidas e baixas no Billing.
2. Checkouts, transações, webhooks e estornos no Pay.
3. Liquidações e taxas informadas pelo provedor.
4. Créditos reservados, consumidos e reembolsados no Entitlements.
5. Fatos de uso do Equipment e appointments do Agend.

Cada divergência deve gerar um registro de reconciliação com origem, valor esperado, valor recebido, diferença, status, responsável e ação corretiva. O relatório não deve alterar dados automaticamente sem uma regra de reconciliação aprovada.

## 10. Relatórios e auditoria

O Reporting deve consumir eventos ou réplicas de leitura do Billing, Pay e Entitlements, sem consultar tabelas de produção de outros módulos para executar mutações. Os indicadores mínimos são faturado, recebido, em aberto, vencido, estornado, chargeback, taxa do provedor, margem, consumo de sessões, excedentes e divergências de conciliação.

O Audit deve registrar quem, quando, tenant, organização, origem, correlação, motivo, valores anterior e posterior e identificadores financeiros. Nunca se deve registrar número completo de cartão, CVV, tokens sensíveis ou chaves de serviço.

## 11. Roadmap recomendado

| Fase | Entrega |
| --- | --- |
| **1. Núcleo financeiro** | Expandir Billing com `Invoice`, `Receivable`, `PaymentAllocation`, `Refund`, estados formais e snapshots de preço |
| **2. Contrato Pay** | Padronizar `payment_intent`, `reference_id`, webhooks assinados e eventos idempotentes |
| **3. Outbox/inbox** | Garantir publicação confiável após commit e processamento idempotente nos consumidores |
| **4. Segurança interna** | Rede privada, mTLS, JWT de serviço por audience/scope e secret manager |
| **5. Conciliação** | Importar liquidações, taxas, estornos e divergências do provedor |
| **6. Fechamento** | Relatórios financeiros, aprovação de ajustes, auditoria e integração contábil |

## 12. Resumo executivo

O processo financeiro ideal da Operaon é: **o módulo de origem registra o fato; o Catalog fornece a referência comercial; o Billing cria e congela a obrigação; o Pay processa o dinheiro; o Billing confirma a baixa; o Entitlements movimenta sessões; o Audit registra a decisão; e o Reporting consolida a visão analítica**.

Essa separação evita que Equipment calcule dinheiro, que Pay defina o que é devido, que Entitlements represente moeda ou que o Gateway vire um segundo Billing. Ela também permite migração gradual, idempotência, conciliação e substituição do provedor de pagamento sem reescrever os domínios de negócio.

## Referências

[1]: https://github.com/operaon/faturament "Operaon Billing"
[2]: https://github.com/operaon/pay "Operaon Pay"
[3]: https://github.com/operaon/entitlements "Operaon Entitlements"
[4]: https://github.com/operaon/equipment "Operaon Equipment"
[5]: https://github.com/operaon/agend "Operaon Agend"
[6]: https://github.com/operaon/catalog "Operaon Catalog"
[7]: https://github.com/operaon/audit "Operaon Audit"
[8]: https://github.com/operaon/reporting "Operaon Reporting"
