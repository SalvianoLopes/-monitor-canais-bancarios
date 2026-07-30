# CLAUDE.md — Canais Críticos

## Identificação
- **App real:** https://canais-criticos.vercel.app
- **Demo:** https://canais-criticos-inbursa.netlify.app
- **Código:** `C:\Users\Desktop\portfolio\canais-criticos\index.html`
- **GitHub:** `git@github.com:SalvianoLopes/monitor-canais-bancarios.git` (renomeado em 28/07/2026, sem hífen no início)
- **Vercel project:** `prj_2poSdjHTJHipUJVRDALaPCkG6g7I` (canais-criticos)
- **Supabase real:** `yaaoisqyxfqocrnlymjm` — credenciais em `C:\Users\Desktop\backup-canais-criticos\backup.py`

## Deploy
```
cd C:\Users\Desktop\portfolio\canais-criticos
git add index.html
git commit -m "..."
git push origin main
vercel deploy --prod
```

## Stack
- HTML/CSS/JS puro — sem React, sem build
- Chart.js 4.4.1 + SheetJS (XLSX) 0.18.5 via CDN
- Supabase via fetch nativo (`sbGet`, `sbPost`)
- Fontes: DM Sans + DM Mono (Google Fonts)

## Detecção real vs demo — CRÍTICO
```js
var _REAL = window.location.hostname === 'canais-criticos.vercel.app';
// OBRIGATÓRIO usar 'var' (não const/let) para ficar no window
const SB_URL = _REAL ? 'https://yaaoisqyxfqocrnlymjm.supabase.co' : '';
const SB_KEY = _REAL ? 'eyJ...' : '';
if (!_REAL) { /* mostrar banners demo */ }
```
- Se `const _REAL`: `window._REAL` é undefined → banners aparecem sempre → BUG
- Banners demo: `id="banner-demo"` (topo amarelo) e `id="badge-demo"` (canto inferior direito azul)

## Canais
| Canal | Cor | Tabela |
|---|---|---|
| RDR (BACEN) | Azul `#1a56db` | canais_criticos_demandas (canal='rdr') |
| Consumidor.gov.br | Verde `#0b7a5e` | canais_criticos_demandas (canal='consumidor') |
| PROCON | Roxo `#7c3aed` | canais_criticos_demandas (canal='procon') |

## Tabela principal: canais_criticos_demandas
Colunas relevantes: `id, canal, data_ref, numero, demandante, cpf, abertura, prazo, demanda, status, extra1, extra2, descricao, colaborador, municipio, procon_orgao, inserted_date, upload_date`

- `data_ref`: data de referência (YYYY-MM-DD) — usada para filtrar por dia no calendário
- `numero`: protocolo/número do caso — chave para deduplicação
- `demanda`: tipo/tag da demanda
- `extra1`: no Consumidor = nota do consumidor (1-5); no PROCON = órgão Procon
- `extra2`: no Consumidor = nome fantasia; no PROCON = município
- `prazo`: campo do banco (não usado para classificar vencido — regra de prazo foi removida)

## Indicador Consumidor.gov.br (reformulado 28/07/2026)
**O score composto (Resolução 40% + Nota 40% + Respondidas 20%) foi removido.** Substituído por um indicador único: `buildScoreConsumidor()` agora mostra **"Satisfação (Consumidor.gov)"** = média simples das notas 1-5 dadas pelo consumidor (`soma(extra1) / count(extra1)`), a mesma fórmula que o Consumidor.gov.br usa de verdade (validado por pesquisa: [consumidor.gov.br](https://www.consumidor.gov.br/pages/conteudo/publico/1)).
- Card "Avaliados" mostra quantos registros têm nota real (hoje: 89, de um upload MOL de maio/2026 que trazia nota — as planilhas "Respondida"/"Não respondida" atuais **não** trazem nota, só Situação)
- **`extra1` para Consumidor tem uso duplo** — nos 89 registros antigos é a nota (1-5); nas planilhas novas (28/07) é reaproveitado como "Colaborador responsável". Por isso os scripts de upload/PATCH **nunca tocam em `extra1`** ao atualizar um registro existente — só em INSERT de registro novo.
- Nova constante `OFICIAL_CONSUMIDOR` (topo do `<script>`, perto de `FERIADOS`) guarda os números oficiais do painel Consumidor.gov (Nota, Finalizadas, Índice de Solução, Respondidas, Tempo de resposta) — **preenchida manualmente**, não calculada pelo app. Atualizar quando o Salviano trouxer números mais recentes.
- Conclusão da investigação: não é possível reproduzir o número oficial exato só com os CSVs do MOL (faltam nota individual + data de finalização por caso) — precisaria da base da API do Consumidor.gov.

### Regra de "resolvido" nas Situações reais (28/07/2026)
Confirmado pelo usuário: Respondida, Cancelada, Finalizada (Avaliada/Não Avaliada) e Encerrada = resolvido. "Em Análise Pelo Gestor"/"Em Análise Pelo Fornecedor" = **não resolvido**, deveria entrar na regra dos 10 dias úteis (alerta visual pendente de implementar — pausado, ver Pendências).

## Inserção de dados via PowerShell
Para inserir no banco sem duplicatas:
1. Buscar protocolos existentes: `GET /canais_criticos_demandas?select=numero&canal=eq.X&limit=2000`
2. Usar `Invoke-WebRequest` com `-Body` em bytes UTF-8 (resolve acentos)
3. Verificar `inserted_date` para rastrear o que foi inserido em cada sessão

## Mapeamento planilhas MOL → banco

### Consumidor (MOLReport com avaliação)
| Coluna MOL | Campo banco |
|---|---|
| Protocolo | numero |
| Consumidor/Reclamante | demandante |
| CPF | cpf |
| Data de abertura | abertura / data_ref |
| Data finalização | prazo |
| Tags | demanda |
| Avaliação reclamação | status (Resolvida/Não Resolvida) |
| Nota do consumidor | extra1 (1-5) |
| Colaborador responsável | colaborador |

### PROCON (3 formatos diferentes)
| Arquivo | Protocolo | Situação/Tag | Data |
|---|---|---|---|
| MOLReport 35 (15 cols) | col 6 | col 10 (Situação) | col 11 (Capturada em) |
| MOLReport 36 (13 cols) | col 6 | col 10 (Situação) | ausente → usar hoje |
| MOLReport 37 (14 cols) | col 5 | col 9 (Situação) | col 10 (Atualizada em) |

**Tag PROCON:** extrair linha do "Banco Inbursa" da Situação, remover prefixo "Banco Inbursa - ".  
**Sem situação:** usar "Aguardando Resposta" como padrão.

## Regra de prazo (atualizado 01/06/2026)
- **Regra de vencido REMOVIDA** — `prazoEfetivo(r)` retorna `null` para todos os registros
- App usado apenas para **registro de entradas**; respostas são feitas no MOL
- Todos os registros aparecem como OK (sem vencido, sem urgente)
- KPIs do dia: Total + RDR + Consumidor + PROCON
- Detalhe de canal: Total + Encerradas + Em andamento + card "Status das entradas"

## Formato "Respondida/Não Respondida" (MOL, usado em 28/07/2026)
Formato diferente do `MOLReport` tradicional — exportado por canal, sempre em par (Respondida.csv + Não Respondida.csv), UTF-8 com BOM. Colunas por canal:
- **RDR/BACEN:** Colaborador responsável, Número, Nome, Data de captura, Data de cadastro, Data de disponibilização, Prazo, Situação, Respondido na plataforma
- **PROCON:** Colaborador responsável, Tags, Chave de integração, Procon, Município, Protocolo, Reclamado, Reclamante, CPF, Situação, Capturada em, Data Cadastro CIP, Prazo de resposta CIP, Protocolo Adm., Prazo proc. adm.
- **Consumidor:** Tags, Colaborador responsável, Protocolo, Nome fantasia, Situação, Reclamante, CPF, Data de abertura, Capturada em

Nenhum desses tem coluna de nota (1-5) — só Situação. RDR não tem coluna Tags (usa Situação como "demanda"). Fluxo de upload usado: ler os dois arquivos do par, merge por chave (Número/Protocolo), buscar protocolos já existentes no banco, **INSERT** os novos (com `data_ref` derivado da data do registro, formato ISO) e **PATCH** (só `status`+`demanda`, nunca `extra1`) nos existentes com Situação preenchida. Scripts ficam em `AppData\Local\Temp\claude\...\scratchpad\upload_<canal>.py` por sessão (não versionados no repo).

## Backup automático
- **Script:** `C:\Users\Desktop\backup-canais-criticos\backup.py`
- **Pasta:** `C:\Users\Desktop\backup-canais-criticos\`
- **Gatilho:** Windows Task Scheduler — **roda ao ligar o PC** (AtLogOn)
- **Tarefa:** `BackupCanaisCriticos` (visível no Agendador de Tarefas do Windows)
- **Retenção:** 10 backups mais recentes (apaga os antigos automaticamente)
- **Formato:** `BACKUP_YYYY-MM-DD_HH-MM.xlsx` com abas: demandas, uploads, config
- **Requisito:** PC deve ter internet ao ligar para o backup rodar
- Último backup manual antes da automação: `BACKUP_2026-05-06_20-22.xlsx`
- Backup pós-limpeza final: `BACKUP_2026-05-26_20-01.xlsx` (547 KB — 4.223 demandas, estado limpo)

## Login (adicionado 29/07/2026)
App real agora exige login via **Supabase Auth** — sem login, `garantirSessao()` mostra a tela `#login-gate` e bloqueia `carregarDados()`. Demo (`_REAL=false`) não usa login (segue liberado, dado fictício).

- **UX:** um único e-mail fixo exibido na tela (`sao-atendimento@inbursa.com`), a **senha** é quem identifica o usuário.
- **Por baixo:** contas reais no Supabase Auth (aliases `+nome`, GoTrue trata como e-mails distintos — não precisam existir de verdade, criadas já confirmadas via SQL direto em `auth.users`/`auth.identities`):
  | Usuário | E-mail da conta | Senha |
  |---|---|---|
  | Oliveira | `sao-atendimento+oliveira@inbursa.com` | `Oliveira` |
  | Zoghaib | `sao-atendimento+zoghaib@inbursa.com` | `Zoghaib` |
  | Bovi | `sao-atendimento+bovi@inbursa.com` | `Bovi` |
  | Aguilera | `sao-atendimento+aguilera@inbursa.com` | `Aguilera` |
  | Castagni | `sao-atendimento+castagni@inbursa.com` | `Castagni` |
  | Mellugo | `sao-atendimento+mellugo@inbursa.com` | `Mellugo` |
  (Bovi/Aguilera/Castagni/Mellugo adicionados em 30/07/2026, mesmo padrão dos 2 primeiros — `fazerLogin()` tenta a senha digitada contra todas em sequência até achar a conta certa.)
- **Fluxo de login (`fazerLogin()`):** tenta a senha digitada contra as 2 contas em sequência (`POST /auth/v1/token?grant_type=password`); a que aceitar identifica o usuário. Sessão (`access_token`, `refresh_token`, `expires_at`, `nome`) salva em `localStorage['cc_session']`.
- **Sessão:** `H.Authorization` passa a usar o `access_token` do usuário (não mais a anon key fixa) — todos os `fetch()` do app já usam o objeto `H` por referência, então a troca é automática em todo o app.
- **Renovação:** `garantirSessao()` roda no load e a cada 5 min; renova via `grant_type=refresh_token` quando faltam <5 min pra expirar; se falhar, mostra login de novo.
- **Header:** badge "👤 Nome" + botão "Sair" (`fazerLogout()` limpa a sessão e recarrega a página).
- **Motivo de ter feito assim:** pedido do Salviano — login único (mesmo e-mail) mas cada senha identifica a pessoa, pra depois medir SLA por usuário. Usar contas reais do Supabase Auth (em vez de senha hardcoded no JS) evita expor as senhas no código-fonte da página.
- **Expansão de acessos (30/07/2026):** validado o teste inicial com Oliveira/Zoghaib, adicionados mais 4 usuários (Bovi, Aguilera, Castagni, Mellugo) — total 6 contas ativas. Pra abrir mais no futuro: criar conta real no Supabase Auth (mesmo padrão `sao-atendimento+<nome>@inbursa.com` / senha = sobrenome, via SQL direto em `auth.users`+`auth.identities`) e adicionar em `CONTAS_LOGIN` no `index.html`.

### RLS travado (29/07/2026) — fechando brecha de segurança
Antes: `canais_criticos_demandas` e `canais_criticos_uploads` tinham policy `anon_full_access` (FOR ALL TO anon) — **qualquer pessoa com a anon key (visível dando "Ver código-fonte" na página) tinha leitura E escrita completa, incluindo CPF real de clientes**, sem precisar nem abrir o app.
- Todas as policies antigas (anon_full_access + várias policies soltas duplicadas em `public`) foram **removidas**.
- Cada tabela agora tem **uma única policy**: `authenticated_full_access` — `FOR ALL TO authenticated USING (true) WITH CHECK (true)`.
- Confirmado por teste: GET com só a anon key agora retorna `200 []` (RLS filtra tudo, não dá erro — é assim que Postgres RLS se comporta via PostgREST).
- **`backup-canais-criticos\backup.py` foi atualizado** — antes usava só a anon key; agora faz login (`grant_type=password`, conta Oliveira) antes de puxar os dados, senão o backup automático (Task Scheduler, sem interação) pararia de funcionar. Testado manualmente após a mudança: 6.739 registros, ok.

### 2026-07-28
**Incidente + restauração Consumidor:** 2.205 registros de `consumidor` foram apagados entre 27/07 09:09 e 19:58 (causa raiz achada nesta mesma sessão — ver abaixo). Restaurado via `restaurar_consumidor.py` a partir do backup `BACKUP_2026-07-27_09-09.xlsx` (2.205 registros, zero erro).

**Causa raiz do apagamento — bug corrigido (commit `b36e825`):** `confirmarExclusao()` ignorava o parâmetro de dia (`ds`) e sempre rodava `DELETE ...?canal=eq.${canal}` sem filtro de data — os botões "🗑 Este dia" e "🗑 Todo o canal" tinham o mesmo efeito (apagavam o canal inteiro). Corrigido: exclusão de um dia agora filtra por `data_ref`; modal mostra contagem real antes de excluir; exclusão do canal inteiro exige digitar `EXCLUIR <CANAL>`.

**Segurança:** demo (`canais-criticos-inbursa.netlify.app`) estava chamando a Edge Function real do Supabase (`get-canais-criticos`) sem autenticação, expondo CPF/nome de clientes reais publicamente. Corrigido: demo reescrito com dado 100% fictício (repo próprio `canais-criticos-demo`, privado); Edge Function protegida com "Verificar JWT" ativado no painel Supabase (retorna 401 sem header agora).

**Reformulação do indicador Consumidor:** ver seção "Indicador Consumidor.gov.br" acima — score composto trocado por nota real + números oficiais manuais.

**Upload em massa das planilhas MOL "Respondida/Não Respondida"** (ver seção de formato acima) nos 3 canais — zero erros:
| Canal | Antes | Depois do upload | Inseridos | Atualizados | Após limpeza de duplicatas |
|---|---|---|---|---|---|
| RDR/BACEN | 9 | 1.308 | 1.299 | 9 | 1.308 (já estava limpo, 0 duplicata) |
| PROCON | 2.721 | 3.154 | 432 | 2.699 | 3.153 (1 duplicata removida) |
| Consumidor | 2.205 | 2.737 | 532 | 1.731 | 2.278 (457 duplicatas + 2 vazios removidos) |

RDR estava quase vazio desde antes do incidente do Consumidor (causa nunca identificada, separada) — esse upload resolveu.

**Auditoria de duplicatas nos 3 canais concluída (29/07/2026):** mesma metodologia usada no Consumidor (agrupar por `numero`, checar divergência de status, manter menor `id`, backup antes de apagar) aplicada em PROCON e RDR.
- RDR: 0 protocolos duplicados, 0 vazios — banco já estava limpo.
- PROCON: 1 protocolo duplicado (`26.04.0155.001.00067-3`, ids 17522 e 20283, status idêntico), 1 registro extra removido. Backup em `backup-canais-criticos\PRE_LIMPEZA_DUP_PROCON_2026-07-29_00-05.json`. Total final: 3.153.
- **Estado final pós-auditoria completa: RDR=1.308, PROCON=3.153, Consumidor=2.278 — zero duplicata em qualquer canal.**

**Pendência em aberto:** alerta visual dos 10 dias úteis pra status "Em Análise Pelo Gestor/Fornecedor" (regra "No Aguardo") — combinado com o usuário, mas pausado pra investigar a nota antes. Ainda não implementado.

### 2026-05-26
- **Incidente PROCON:** botão "Excluir PROCON" acionado no app → 1.783 registros deletados
- Upload `PROCON_CONSOLIDADO_CORRIGIDO.xlsx` (4.067 linhas) falhou parcialmente → só 10 registros entraram
- **Restauração via script Python:**
  - `restaurar_procon.py`: reinseriu 1.198 registros do backup de 06/05
  - `inserir_procon_padrao.py`: inseriu 2.057 registros novos do `PROCON_PADRAO_OK.xlsx`
- **Total banco após restauração:** consumidor=1.161 | procon=3.265 | rdr=966
- PROCON agora cobre até 26/05/2026 (planilha consolidada com histórico completo)
- **Backup automático configurado:** Task Scheduler → AtLogOn → `backup.py`
- Scripts de restauração salvos em `C:\Users\Desktop\backup-canais-criticos\`

### 2026-05-23
- **RLS ativado (segurança Supabase):** Tabelas `canais_criticos_demandas` (3805 linhas) e `canais_criticos_uploads` (269 linhas) estavam sem RLS. Supabase alertou por e-mail (17/05/2026). Aplicado via MCP: `ENABLE ROW LEVEL SECURITY` + política `anon_full_access` (FOR ALL TO anon USING (true) WITH CHECK (true)). Todas as 8 tabelas do projeto agora com `rls_enabled: true`. Nenhuma alteração de código necessária.

### 2026-05-13
- Credenciais reais adicionadas com detecção por hostname (var _REAL)
- Corrigido bug: `const _REAL` → `var _REAL` (const não fica no window)
- Score Consumidor alterado para fórmula ponderada (resolução 40% + nota 40% + resposta 20%)
- Nota média adicionada ao indicador (campo extra1)
- 80 casos Consumidor inseridos (MOLReport 34) com nota em extra1
- 183 casos PROCON inseridos (MOLReports 35, 36, 37) com tags da coluna Situação
- Status "Resolvida" agora reconhecido no cálculo do score (além de encerrada/finalizada)
