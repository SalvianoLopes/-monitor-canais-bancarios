# Plataforma de Gestão de Demandas — Setor Bancário

Sistema de acompanhamento e análise de demandas por canais de atendimento desenvolvido para operação bancária. Permite upload de planilhas, visualização de tendências e gestão de status por canal.

![Dashboard](https://img.shields.io/badge/status-demo-1a56db) ![Stack](https://img.shields.io/badge/stack-Chart.js%20%7C%20XLSX%20%7C%20Vanilla%20JS-0e0f11)

## Funcionalidades

- **Upload de planilhas** — importação direta de arquivos `.xlsx` com validação automática
- **Análise por canal** — visão comparativa entre canais de atendimento (Redirecionamento, Consultivo, Processamento)
- **Gráficos de tendência** — evolução diária e semanal por canal
- **Filtros dinâmicos** — por período, canal, status e responsável
- **Resumo executivo** — KPIs consolidados com variação período a período
- **Export** — relatório consolidado em Excel

## Stack

| Tecnologia | Uso |
|-----------|-----|
| Vanilla JS (ES6+) | Toda a lógica sem frameworks |
| Chart.js 4 | Gráficos de linha, barra e pizza |
| SheetJS (XLSX) | Leitura e exportação de planilhas |
| DM Sans / DM Mono | Tipografia |

## Como rodar

Aplicação 100% client-side — sem backend, sem dependências para instalar.

```bash
# Abrir direto no browser
open index.html

# Ou via servidor local
npx serve .
python -m http.server 8080
```

## Uso

1. Acesse `index.html` no browser
2. Clique em **Importar Planilha** e selecione o arquivo `.xlsx`
3. O sistema processa automaticamente e exibe os gráficos e tabelas
4. Use os filtros para segmentar a análise por período ou canal

## Estrutura esperada da planilha

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| Data | Date | Data da demanda |
| Canal | Text | Nome do canal |
| Status | Text | `Redirecionamento`, `Consultivo`, `Processamento` |
| Responsável | Text | Nome do responsável |
| Quantidade | Number | Volume de demandas |

## Projeto

Desenvolvido para substituir relatórios manuais diários da equipe de canais, centralizando a visualização e tornando o acompanhamento operacional mais ágil.

---

*Portfólio — [SalvianoLopes](https://github.com/SalvianoLopes)*
