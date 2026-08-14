# Deployment e ambientes — Infraestrutura Operaon

## Pipeline

O deployment deve executar validação de documentação, sintaxe, testes, detecção de segredos, migrations compatíveis, rollout, readiness e smoke tests antes de liberar tráfego.

## Ambientes

Desenvolvimento, homologação e produção possuem valores, credenciais, certificados, bancos e limites próprios. O contrato de headers permanece igual; os valores operacionais podem variar.

## Rollout e rollback

Aplicar rollout progressivo quando possível. Não executar rollback cego de migrations. Em falha, preservar eventos, logs e dados de auditoria, interromper a progressão e seguir o runbook aprovado.

## Portas

A auditoria identificou possíveis colisões nos templates atuais: Integration/Notification em 4720, Entitlements/Media em 4770 e Pay em 4200 no template local versus 4500 em referência anterior. A matriz de deployment deve resolver essas divergências antes de ambiente compartilhado.

## Referências

[1]: https://github.com/operaon "Organização Operaon"
