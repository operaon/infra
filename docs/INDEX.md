# Documentação — Infraestrutura Operaon

> **Status:** documentação versionada em Docs as Code. **Owner:** Plataforma e Infraestrutura. **Branch:** main.

Este índice organiza a documentação oficial do repositório [Infraestrutura Operaon][1]. A documentação global define os padrões; este repositório registra somente responsabilidades, contratos e procedimentos específicos.

## Visão rápida

| Campo | Valor |
| --- | --- |
| Repositório | `infra` |
| Tipo | infra |
| Responsabilidade | Topologia de ambientes, rede, deploy, observabilidade, secrets, bancos e políticas operacionais. |
| Porta declarada | não aplicável |
| Banco próprio | Não aplicável como owner de domínio |
| Entrada oficial | Pipeline/operador autorizado |

## Documentos

- [Arquitetura de infraestrutura](infrastructure.md)
- [Ambientes e deploy](deployment.md)
- [Segurança](security.md)
- [Operação](operations.md)
- [Testes](testing.md)
- [Runbook de saúde](runbooks/health-and-readiness.md)
- [Decisões arquiteturais](decisions/ADR-0001-documentation-standard.md)

## Princípios

Módulos devem permanecer em rede privada; portas, secrets e rotas devem ser declarados por ambiente e validados em CI.

A regra de ownership é obrigatória: comandos que alteram estado devem ser enviados ao owner do domínio; eventos informam mudanças após commit; consultas não transferem ownership.

## Referências

[1]: https://github.com/operaon/infra "Repositório Infraestrutura Operaon"
[2]: https://github.com/operaon/api "API Gateway Operaon"
[3]: https://github.com/operaon/identity "Identity Operaon"
