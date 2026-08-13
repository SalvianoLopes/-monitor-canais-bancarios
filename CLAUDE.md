# CLAUDE.md — Canais Críticos

## Identificação
- **App real:** https://canais-criticos.vercel.app
- **Demo:** https://canais-criticos-inbursa.netlify.app
- **Código:** `C:\Users\Desktop\portfolio\canais-criticos\index.html`
- **GitHub:** `git@github.com:SalvianoLopes/monitor-canais-bancarios.git` (renomeado em 28/07/2026, sem hífen no início)
- **Vercel project:** `prj_2poSdjHTJHipUJVRDALaPCkG6g7I` (canais-criticos)
- **Supabase real:** `yaaoisqyxfqocrnlymjm` — credenciais em `C:\Users\Desktop\backup-canais-criticos\backup.py`

## Deploy — REGRA OBRIGATÓRIA (desde 12/08/2026)
**NUNCA rode `vercel deploy --prod` sem antes commitar E pushar pro `origin/main`.**

**Por quê:** em 08/08/2026 o painel "Registros por mês" (Visão Geral) foi publicado
direto em produção via `vercel deploy` sem passar por commit — o deploy resultante
(`dpl_G3zbBT3PTVDwxv5GC7MS7hHDRvcz`) não tem nenhuma metadata de git associada.
Como nenhuma sessão futura (nem git log, nem memória) tinha como saber que aquele
código existia, um deploy seguinte feito a partir do `git main` sobrescreveu a
funcionalidade em produção sem ninguém perceber até o usuário notar que o gráfico
tinha sumido. Recuperado em 12/08/2026 baixando o HTML da URL do deploy órfão
(cada deploy do Vercel fica acessível na própria URL, mesmo depois de não ser mais
a produção) e comparando com o commit anterior pra isolar o que faltava.

**Use sempre `deploy.sh`** (na raiz do repo) em vez de chamar `vercel deploy` direto —
ele recusa o deploy se houver qualquer mudança não commitada ou não pushada:
```
cd C:\Users\Desktop\portfolio\canais-criticos
git add index.html
git commit -m "..."
git push origin main
bash deploy.sh
```
Se `deploy.sh` não existir na máquina/sessão atual (ex.: clone novo), primeiro
confirme manualmente com `git status` (deve estar limpo) e `git log origin/main -1`
vs `git log -1` (mesmo commit) antes de rodar `vercel deploy --prod` direto.

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
- `demanda`: tipo/tag da demanda — **no RDR, desde 12/08/2026, é sempre o assunto real da reclamação** (ver "Mapeamento RDR" abaixo). Antes disso, para uploads no formato Situação-only, `demanda` acabava guardando a Situação (duplicado de `status`) — corrigido retroativamente.
- `extra1`: no Consumidor = nota do consumidor (1-5); no PROCON = órgão Procon; **no RDR, desde 12/08/2026 = Data da Captura** (formato BR, DD/MM/AAAA — mesmo padrão de `abertura`/`prazo`)
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

### RDR/BACEN — planilha oficial desde 12/08/2026 (`Consolidado Geral.xlsx`, aba `Consolidado`)
Essa é a planilha que o usuário realmente sobe pro RDR. `normalizar('rdr')` em `index.html` lê só estas 7 colunas — aceita tanto o nome novo quanto o antigo, porque **o usuário decidiu manter os cabeçalhos originais na planilha (confirmado 12/08/2026), não vai renomear nunca** — o fallback não é transitório, é permanente por design:

| Coluna da planilha | Nome antigo na planilha | Campo banco |
|---|---|---|
| Data da Captura | Disponibilização A | `extra1` (formato BR) |
| Número | — | `numero` |
| Data de Ciência | Disponibilização | `abertura` / `data_ref` |
| Prazo | — | `prazo` |
| Nome | — | `demandante` |
| CPF/CNPJ | — | `cpf` |
| Demanda | — | `demanda` |

As demais colunas que aparecem na planilha (Status, Data do Contrato, ISPB, IF Solicitante, CNPJ, Corban) são **desconsideradas de propósito** — decisão do usuário, não usar pra nada no app.

- **Data da Captura vs Data de Ciência:** são datas diferentes de propósito — captura é quando o BACEN registrou a reclamação (pode ser fim de semana), ciência é quando chega no Inbursa pra começar a tratar (base do prazo de 10 dias úteis). Confirmado pelo usuário que na totalidade da planilha essas duas datas costumam bater no mesmo dia — se um registro específico tiver `extra1` (captura) muito diferente de `abertura` (ciência), suspeitar de dado desatualizado em `abertura` vindo de upload antigo, não da planilha atual.
- **CPF vem sem zero à esquerda em ~4% das linhas** (Excel converte a célula pra número e perde o zero). Sempre normalizar com `zfill(11)` antes de gravar/comparar.
- **REGRA — Prazo do RDR (confirmado 13/08/2026):** `Prazo` = `Data de Ciência` + **10 dias úteis**. É regra do próprio BACEN — a planilha já traz o valor calculado pronto na coluna "Prazo", o app **não calcula isso**, só armazena o que vem da planilha. Isso é só documentação do significado do campo, não uma lógica ativa: a classificação de vencido/urgente foi removida de propósito do app em 01/06/2026 (ver seção "Regra de prazo" abaixo) — todo registro aparece como OK, sem cálculo de vencimento.
- **REGRA GERAL — Prazo = Data da Captura + 10 dias úteis, em TODOS os canais (decidido 13/08/2026):** decisão inicial era sobrescrever o campo `prazo` de todo registro (RDR, PROCON, Consumidor) com **data de captura** (`extra1` no RDR / `abertura`-`data_ref` em PROCON e Consumidor) **+ 10 dias úteis**. O usuário reconsiderou no mesmo dia: **implementação real é só visual/alerta — não sobrescreve o campo `prazo` importado da planilha.** Ver "Alerta visual de prazo" abaixo pro que foi de fato implementado.

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

### `data_cadastro_cip` (coluna 12, "Data Cadastro CIP") — REGRA desde 12/08/2026
**Toda importação de PROCON tem que gravar a coluna "Data Cadastro CIP" da planilha no campo dedicado `data_cadastro_cip` da tabela.** Existe uma coluna própria no banco pra isso — nunca deixar esse dado só dentro de `dados_raw` (JSON) ou descartá-lo.

**Por quê:** até 12/08/2026 o `normalizer('procon')` do `index.html` só guardava essa data dentro do `dados_raw`, nunca escrevia na coluna `data_cadastro_cip` — apesar da coluna existir na tabela desde antes. Resultado: **0 dos 3.518 registros de PROCON** tinham esse campo preenchido. Corrigido em duas frentes:
1. Backfill retroativo: 728 registros que tinham `dados_raw` com a chave `'Data Cadastro CIP'` foram recuperados (`UPDATE ... SET data_cadastro_cip = dados_raw->>'Data Cadastro CIP'`). Os ~2.790 registros sem `dados_raw` **não têm como ser recuperados** — esse dado nunca foi capturado em lugar nenhum pra eles.
2. Código (`normalizer('procon')` e o corpo do INSERT em `salvarDia()`) atualizado pra sempre gravar `data_cadastro_cip` na coluna própria a partir de agora, em qualquer upload feito pelo app.

**How to apply:** se aparecer upload de PROCON feito fora do app (script avulso, como o `MOLReport.csv` inserido em 13/08/2026 — ver histórico abaixo), sempre incluir `data_cadastro_cip` no INSERT junto com os outros 15 campos padrão. Se for descoberto outro campo da planilha que a coluna do banco tem mas o app nunca preenche, aplicar o mesmo tratamento: corrigir o `normalizer()`, corrigir o INSERT de `salvarDia()`, e backfillar o que der pra recuperar via `dados_raw`.

**Segundo bug, de LEITURA não de gravação (achado e corrigido 13/08/2026, mesmo dia):** mesmo depois do fix acima e do backfill (99,9% dos 3.503 registros com `data_cadastro_cip` preenchido no banco), o usuário reportou "todos sem Data Cadastro CIP" olhando a tabela no app. Causa: a constante `SELECT` em `carregarDados()` (`index.html`) **nunca incluía a coluna `data_cadastro_cip`** — o app nunca buscava esse campo do Supabase, então chegava sempre `undefined` no navegador não importa o que tivesse no banco. Além disso, a tabela (`buildCanalPanel` → `getField`) lia esse valor de `r.dados_raw['Data Cadastro CIP']` em vez da coluna dedicada — funcionava só pra prévia de upload ainda não salvo (que tem `dados_raw` em memória), nunca pra dado já salvo vindo do banco.
- **Fix:** `data_cadastro_cip` adicionado à constante `SELECT`; `getField('_data_cip')` agora prioriza `r.data_cadastro_cip`, com `dados_raw` só como fallback pra prévia local. Commit `ec51a68`, deploy `dpl_EmodDdxkEu2idBLF5PAT4wrYkArt`.
- **Lição:** ao adicionar uma coluna nova no banco, sempre conferir 3 pontos, não só o INSERT: (1) o `normalizer()` grava o campo, (2) o INSERT de `salvarDia()` envia o campo, (3) a constante `SELECT` de `carregarDados()` busca o campo de volta. Faltar o passo 3 faz o dado existir no banco mas nunca aparecer na tela — sintoma idêntico ao dado realmente faltando, fácil de confundir.

### PROCON Uberlândia — 4º formato, protocolo próprio (achado 03/08/2026)
Fonte MOL separada dos 3 formatos acima — não aparece nos exports `MOLReport` tradicionais (por isso planilhas desse tipo, ex. export de 01/01 a 30/06/2026, não trazem esses registros e uma comparação direta de contagem vai "sobrar" no banco sem ser duplicata/erro).

- **Protocolo na origem:** número puro, sem máscara (ex. `51789`) — diferente do formato `NN.NNNN.NNN.NNNNN-N` dos demais PROCONs.
- **`numero` gravado no banco:** composto `AAAA.MM.0399.NNN.NNNNN` (ano/mês do upload + código fixo `0399` + o número puro do protocolo de origem).
- **Sempre gravado com:** `extra1 = 'Procon Uberlândia'`, `extra2` = município.
- **Como identificar um registro desse tipo:** `extra1 = 'Procon Uberlândia'` — não depender do formato do `numero` sozinho pra reconhecer.
- **How to apply:** ao cruzar planilha MOL × banco por protocolo (auditoria de duplicata, conferência de totais etc.), sempre excluir/tratar à parte os registros com `extra1='Procon Uberlândia'` se a planilha de referência for um export `MOLReport` padrão — eles não vão bater porque vêm de outra fonte, não porque estão errados. Confirmado em auditoria de 03/08/2026 (ver abaixo).
- **ARMADILHA (achada 13/08/2026):** alguns uploads antigos (ex. script de 26/05/2026) gravaram Uberlândia com o `numero` **cru** (`51789`), sem a máscara `AAAA.MM.0399...` — inconsistente com o padrão documentado acima. Um cruzamento de planilha MOL (que já traz o protocolo no formato **composto**) contra o banco usando só `numero` literal **não vai achar esse registro antigo e vai tratá-lo como "novo"**, criando duplicata. Pra cruzar Uberlândia com segurança: além do `numero`, sempre checar também por `cpf` (normalizado, sem zero à esquerda variável) + `demandante` (case-insensitive) dentro de `extra1='Procon Uberlândia'` antes de decidir que um registro é realmente novo. Incidente: 50 pares de duplicata (100 registros) entraram por não seguir essa regra — corrigidos (ver "Quarta rodada" abaixo).

## Tags de assunto do RDR/BACEN em `extra1` (30/07/2026) — SUPERADO em 12/08/2026
**Esta seção é histórico.** Em 12/08/2026 os dados descritos aqui foram migrados: `demanda = extra1` nos 1.263 registros que tinham a tag guardada em `extra1`, depois `extra1` foi limpo e passou a guardar Data da Captura (ver "Mapeamento RDR/BACEN" acima). Hoje a tag de assunto vive direto em `demanda`, não mais em `extra1`. Mantido abaixo só pra entender a origem do dado.

O formato usado pro RDR (ver "Formato Respondida/Não Respondida" abaixo) nunca trouxe uma coluna de assunto/categoria — só Situação (status). O usuário tinha uma planilha separada (`Consolidado Geral.xlsx`, aba `Consolidado`) com o export tradicional do MOL, que tem coluna `Demanda` = a tag de assunto de verdade (ex: "Cópia do contrato", "Desconhece refinanciamento - BP", "Extrato/DED").

- **Campo usado:** `extra1` — estava livre pro canal RDR (só usado por Consumidor/PROCON pra outra coisa), então não precisou de coluna nova nem migração de schema.
- **Chave de cruzamento:** `numero` (protocolo) — confirmado que é o mesmo protocolo/CPF/nome batendo entre planilha e banco antes de gravar qualquer coisa.
- **Origem da planilha:** aba "Consolidado" tinha 1.354 linhas brutas, mas 83 eram sobra vazia do range do Excel → 1.271 registros reais. 6 protocolos apareciam duplicados dentro da própria planilha (2 com tags conflitantes entre si) — regra usada: manter a primeira ocorrência com tag preenchida.
- **Resultado do cruzamento (30/07/2026):** 1.265 protocolos únicos na planilha → **1.262 batendo no banco, gravados em `extra1` sem sobrescrever nada** (campo estava 100% vazio antes) → 3 da planilha sem match no app (fora do período) → **46 registros do app ficaram sem tag** (fora do período coberto por essa planilha específica), exportados pro usuário em `Downloads\RDR_sem_tag.xlsx` (protocolo + nome) pra ele puxar a tag certa direto no MOL depois.
- Scripts do processo (dry-run + write) ficaram em `AppData\Local\Temp\claude\...\scratchpad\` (não versionados).

**How to apply:** Se aparecer nova planilha de tags do RDR no formato tradicional do MOL (colunas Número/Nome/CPF/CNPJ/Demanda/Status/...), repetir o mesmo fluxo: ler com `dtype=str` (evita virar float o protocolo), filtrar linhas com `Número` vazio, dedupe por protocolo mantendo a primeira ocorrência com `Demanda` preenchida, cruzar contra `canais_criticos_demandas` por `numero`, fazer dry-run antes de gravar, PATCH só em `extra1`.

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

## Rejeição de duplicatas dentro do próprio arquivo (30/07/2026)
`salvarDia()` já evitava duplicar protocolo que já estava no banco (PATCH se veio com Situação nova, ignora se não veio) — mas só checava contra o snapshot do banco tirado antes do loop. Se a **própria planilha enviada** tivesse o mesmo protocolo duas vezes (acontece em exports do MOL), as duas linhas passavam nessa checagem e as duas eram inseridas, gerando duplicata real que precisava de limpeza manual depois (ver auditorias de 29/07 acima).

- Correção: depois de separar `novos` (protocolos que não existem no banco), um segundo filtro (`novosFiltrados`) dedupe por `numero` dentro do próprio array — mantém a primeira ocorrência, rejeita as repetidas.
- Protocolos rejeitados por esse filtro entram em `duplicatasArquivo` e aparecem num modal novo (`#modal-dup-overlay` / `mostrarDuplicatas()`) logo após salvar, além de contarem no toast final ("N duplicados no arquivo (ignorados)").
- **Decisão consciente:** não foi adicionada trava a nível de banco (constraint UNIQUE em `canal,numero`) — avaliado e descartado por enquanto (confirmado zero duplicata nos 6.739 registros em 30/07, então seria seguro aplicar, mas o usuário preferiu resolver só no código por ora). Se o problema voltar a aparecer (ex.: duas pessoas salvando o mesmo dia ao mesmo tempo), considerar revisitar essa trava — não é algo que a checagem em memória do app cobre (só cobre duplicata dentro do mesmo upload, não concorrência entre uploads simultâneos).

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

- **UX:** um único e-mail fixo exibido na tela (`canais.criticos@inbursa.com` — trocado de `sao-atendimento@inbursa.com` em 30/07/2026), a **senha** é quem identifica o usuário.
- **Por baixo:** contas reais no Supabase Auth (aliases `+nome`, GoTrue trata como e-mails distintos — não precisam existir de verdade, criadas já confirmadas via SQL direto em `auth.users`/`auth.identities`):
  | Usuário | E-mail da conta | Senha |
  |---|---|---|
  | Oliveira | `canais.criticos+oliveira@inbursa.com` | `Oliveira` |
  | Zoghaib | `canais.criticos+zoghaib@inbursa.com` | `Zoghaib` |
  | Bovi | `canais.criticos+bovi@inbursa.com` | `Bovi` |
  | Aguilera | `canais.criticos+aguilera@inbursa.com` | `Aguilera` |
  | Castagni | `canais.criticos+castagni@inbursa.com` | `Castagni` |
  | Mellugo | `canais.criticos+mellugo@inbursa.com` | `Mellugo` |
  | Auditoria | `canais.criticos+auditoria@inbursa.com` | `Auditoria` |
  | Lima | `canais.criticos+lima@inbursa.com` | `Lima` |
  (Bovi/Aguilera/Castagni/Mellugo adicionados em 30/07/2026, mesmo padrão dos 2 primeiros. Auditoria adicionada em 30/07/2026 no mesmo lote em que o domínio do e-mail mudou de `sao-atendimento` para `canais.criticos` — as 6 contas antigas foram migradas para o novo domínio, mesmas senhas. Lima adicionada logo em seguida, mesmo dia. `fazerLogin()` tenta a senha digitada contra todas em sequência até achar a conta certa.)
- **Fluxo de login (`fazerLogin()`):** tenta a senha digitada contra as 2 contas em sequência (`POST /auth/v1/token?grant_type=password`); a que aceitar identifica o usuário. Sessão (`access_token`, `refresh_token`, `expires_at`, `nome`) salva em `localStorage['cc_session']`.
- **Sessão:** `H.Authorization` passa a usar o `access_token` do usuário (não mais a anon key fixa) — todos os `fetch()` do app já usam o objeto `H` por referência, então a troca é automática em todo o app.
- **Renovação:** `garantirSessao()` roda no load e a cada 5 min; renova via `grant_type=refresh_token` quando faltam <5 min pra expirar; se falhar, mostra login de novo.
- **Header:** badge "👤 Nome" + botão "Sair" (`fazerLogout()` limpa a sessão e recarrega a página).
- **Motivo de ter feito assim:** pedido do Salviano — login único (mesmo e-mail) mas cada senha identifica a pessoa, pra depois medir SLA por usuário. Usar contas reais do Supabase Auth (em vez de senha hardcoded no JS) evita expor as senhas no código-fonte da página.
- **Expansão de acessos (30/07/2026):** validado o teste inicial com Oliveira/Zoghaib, adicionados mais 5 usuários ao longo do dia (Bovi, Aguilera, Castagni, Mellugo, depois Lima) + conta Auditoria no migração do domínio — total 8 contas ativas (Oliveira, Zoghaib, Bovi, Aguilera, Castagni, Mellugo, Auditoria, Lima). Pra abrir mais no futuro: criar conta real no Supabase Auth via Admin API (`POST /auth/v1/admin/users` com `service_role` key — `{"email":"canais.criticos+<nome>@inbursa.com","password":"<Sobrenome>","email_confirm":true}`) e adicionar em `CONTAS_LOGIN` no `index.html`. Validar com um teste de `grant_type=password` antes de dar como concluído.

### Rastreamento de quem fez cada upload (03/08/2026)
Antes: `canais_criticos_uploads` registrava data/hora/arquivo/total de cada lote inserido, mas **não guardava qual dos 8 logins fez o upload** — descoberto ao investigar 20 registros de PROCON com data de abertura antiga (jan-mar/2026) que apareceram no banco em 03/08 (upload legítimo do dia, arquivo `MOLReport (63).xls`, feito pelo fluxo normal do app — não foi script nem duplicata).

- **Coluna nova:** `canais_criticos_uploads.usuario` (text, nullable — registros antigos ficam `NULL`, não dá pra saber retroativamente quem fez uploads anteriores a 03/08/2026).
- **Gravação:** no ponto de `INSERT` em `canais_criticos_uploads` (dentro do loop de `salvarDia()`), o body agora inclui `usuario: getSessao()?.nome || null` — usa o nome já salvo na sessão de login, sem chamada extra.
- **`backup.py` atualizado** — select de `uploads` agora inclui `usuario`, aparece na aba `uploads` do backup Excel.
- **Não afeta `canais_criticos_demandas`** — o rastreamento é por lote de upload (tabela `uploads`), não por demanda individual. Pra saber quem inseriu um registro específico, seria preciso cruzar `data_ref`+`canal`+`upload_date` da demanda com a linha correspondente em `uploads`.

### RLS travado (29/07/2026) — fechando brecha de segurança
Antes: `canais_criticos_demandas` e `canais_criticos_uploads` tinham policy `anon_full_access` (FOR ALL TO anon) — **qualquer pessoa com a anon key (visível dando "Ver código-fonte" na página) tinha leitura E escrita completa, incluindo CPF real de clientes**, sem precisar nem abrir o app.
- Todas as policies antigas (anon_full_access + várias policies soltas duplicadas em `public`) foram **removidas**.
- Cada tabela agora tem **uma única policy**: `authenticated_full_access` — `FOR ALL TO authenticated USING (true) WITH CHECK (true)`.
- Confirmado por teste: GET com só a anon key agora retorna `200 []` (RLS filtra tudo, não dá erro — é assim que Postgres RLS se comporta via PostgREST).
- **`backup-canais-criticos\backup.py` foi atualizado** — antes usava só a anon key; agora faz login (`grant_type=password`, conta Oliveira) antes de puxar os dados, senão o backup automático (Task Scheduler, sem interação) pararia de funcionar. Testado manualmente após a mudança: 6.739 registros, ok.

### 2026-08-13

**Upload de PROCON via `MOLReport.csv` (formato MOLReport 35, 15 cols) direto do Downloads, fora do app** — 191 registros novos (nenhum já existia no banco), cobrindo 06/08 a 13/08/2026. Inseridos por script (SQL direto via MCP), replicando fielmente a lógica de `normalizar('procon')`: Situação categorizada em "Aguardando Resposta"/"Em andamento" quando aplicável, ou mantida como veio. Upload registrado em `canais_criticos_uploads` (um registro por dia, usuario="Claude (script)").

**Descoberta e correção do `data_cadastro_cip` faltando** — ver seção "`data_cadastro_cip` — REGRA" acima pro detalhe completo. Resumo: 0 de 3.518 registros de PROCON tinham essa coluna preenchida (bug do app, não só dos 191 novos); 919 recuperados (191 do CSV + 728 do `dados_raw`); código do app corrigido pra nunca mais faltar.

**Segunda rodada de recuperação de `data_cadastro_cip`** — o usuário perguntou se não tinha mais fonte de dado disponível antes de aceitar a lacuna como definitiva. Busca mais ampla no disco achou:
- `Downloads\Planilhas e Relatorios\MOLReport.csv` (31/07–05/08/2026, 119 protocolos) — 111 já tinham CIP vindo do `dados_raw`, **8 novos recuperados**.
- `Downloads\MOLReport (1).csv` (jan–jul/2026, 450 linhas, 447 protocolos únicos) — cruzamento contra o banco: **412 já existiam** (326 sem CIP → recuperados, 86 já tinham), **35 eram novos** — todos protocolos **Procon Uberlândia** (formato `AAAA.MM.0399.NNN.NNNNN`, ver seção "PROCON Uberlândia" abaixo), inseridos com CIP já preenchido direto do arquivo.
- Descartados como não aplicáveis: `MOLReport (1).csv` da pasta antiga (é formato Consumidor, sem coluna CIP), a cópia duplicada numa pasta de outra sessão (mesmo conteúdo do arquivo de 31/07–05/08), e o `Cópia de Tabulador Inbursa - Janeiro a Junho.xlsx` (114 MB — é log de atendimento SAC/formulário interno, não é export do MOL, não tem a coluna).
- Confirmado por leitura do código-fonte: `backup.py` nunca selecionou `dados_raw` no SELECT, e `inserir_procon_padrao.py` (script histórico de 26/05) usava "Data Cadastro CIP" só como fallback de data e descartava o valor original sem gravar `dados_raw` — por isso registros inseridos por esse script específico não têm como recuperar esse campo (a planilha fonte, `PROCON_PADRAO_OK.xlsx`, não existe mais em nenhum lugar do disco).
- Resultado dessa rodada: PROCON foi de **0 → 1.288 de 3.553** registros com `data_cadastro_cip`.

**Terceira rodada — arquivo `MOLReport (2).csv` (o "grande", jan–jul/2026, 3.136 linhas, 3.131 protocolos únicos):**
- Carregado numa tabela de staging (`stage_procon_hoje`, criada e dropada na mesma sessão — MCP do Supabase não mantém sessão entre chamadas, então `TEMP TABLE` não persiste; usada tabela normal + `DROP TABLE` no final) em 11 lotes de ~300 linhas.
- Cruzamento: **todos os 3.131 protocolos já existiam no banco** (zero novos pra inserir) — **2.215 estavam sem `data_cadastro_cip`**, preenchidos com um único `UPDATE ... FROM stage_procon_hoje`.
- Resultado dessa rodada: PROCON foi de 0 → 3.503 de 3.553 registros com `data_cadastro_cip` (98,6%). ~50 apareceram sem cobertura — investigados na rodada seguinte.

**Quarta rodada — descoberta de duplicatas Uberlândia (usuário perguntou as datas dos ~50 "sem cobertura", investigação achou que não eram lacuna, eram bug):**
- Os ~50 registros "sem CIP" eram na maioria **duplicatas**: os 35 registros Uberlândia inseridos como "novos" na segunda rodada (ver acima) na verdade já existiam no banco desde 26/05 e 03/08/2026, só que gravados com o `numero` **cru** (sem a máscara `AAAA.MM.0399...`) — ver armadilha documentada na seção "PROCON Uberlândia" acima.
- **50 pares de duplicata** encontrados no total (agrupando por `extra1='Procon Uberlândia'` + `cpf` + `demandante`) — incluindo 4 pares que só apareceram por diferença de maiúscula/minúscula no nome ou zero à esquerda faltando no CPF, exigindo correção manual além do agrupamento automático.
- Backup em `canais_criticos_demandas_backup_20260813_dup_uberlandia` antes de apagar. Regra de resolução: manter a linha com `data_cadastro_cip` preenchido (ou, se as duas tinham CIP igual, manter a mais antiga por `inserted_date`); apagar a outra. **50 registros duplicados removidos.**
- **Resultado final real da sessão: PROCON = 3.503 registros (não 3.553 — 50 eram duplicata), 3.500 com `data_cadastro_cip` (99,9%).** Restam só **3 registros** genuinamente sem cobertura em nenhuma planilha (protocolos `0743300/2025`, `0932117/2025`, `25.12.0039.001.05404-3`, todos inseridos em 26/05/2026 — provável script `restaurar_procon.py` ou `inserir_procon_padrao.py`, planilha fonte não existe mais no disco).

**Quinta rodada — `abertura` (Capturada em) errada em 78 registros do restore de 26/05 (usuário viu no painel PROCON prazos que pareciam impossíveis: `abertura` depois de `data_cadastro_cip`/`prazo`):**
- **Descoberta importante sobre o campo `abertura`:** ele nem sempre significa "quando a reclamação chegou" — em vários registros é o timestamp de quando rodou o **lote automático de captura**, podendo ser idêntico entre reclamações não relacionadas e bem distante no tempo do `data_cadastro_cip`/`prazo`. Isso **não é erro** na maioria dos casos, é característica normal do dado.
- Comparado o `abertura` gravado no banco (dos 78 registros com gap suspeito, todos do restore de 26/05/2026) contra "Capturada em" do `MOLReport (2).csv` (mesmo arquivo grande da terceira rodada, protocolo a protocolo):
  - **14 batiam certinho** — pareciam divergentes só por diferença de precisão (banco tinha segundos hardcoded manualmente na comparação, arquivo só tinha HH:MM) — falso positivo da própria checagem, não erro real.
  - **29 tinham gap real mas correto** — `abertura` no banco bate com "Capturada em" do arquivo; o gap grande pra `data_cadastro_cip` é legítimo (lote de captura rodou bem depois da CIP).
  - **35 estavam realmente errados** — `abertura` no banco não batia com "Capturada em" do arquivo-fonte. Causa raiz: bug do próprio script de restore de 26/05/2026 — **11 desses 35** tinham a mesma data errada fixa `01/05/2026` gravada, apesar de terem datas de captura reais e diferentes em janeiro/2026 conforme o arquivo-fonte (ex.: `26.01.0833.001.00023-3` devia ser `06/01/2026 01:48`, estava `01/05/2026`) — evidência clara de bug de escrita em lote, não dado real.
- Backup em `canais_criticos_demandas_backup_20260813_abertura_errada` (35 linhas) antes da correção.
- Corrigido via `UPDATE` cruzando pelos 35 `numero` contra o valor de "Capturada em" do arquivo-fonte, ajustando `abertura` e `data_ref` juntos. **35 registros corrigidos.**
- Os outros 43 dos 78 originalmente sinalizados **não precisam de ação** — ou batem exatamente (só tinham diferença de precisão) ou o gap é real e inerente ao significado de "Capturada em" como timestamp de lote.

**Alerta visual de prazo reativado (13/08/2026)** — `prazoEfetivo(r)` (em `index.html`), que desde 01/06/2026 sempre retornava `null` (ver incidente "Remove regra de 10 dias úteis" abaixo), voltou a calcular de verdade: `prazoEfetivo` = data de captura (`extra1` no RDR, `data_ref`/`abertura` em PROCON/Consumidor) + 10 dias úteis (`addDiasUteis`), pra todos os canais.
- **Só visual — não sobrescreve nada no banco nem o campo `prazo` importado da planilha.** Registros com `isEncerrado(r)` true (status contém "encerrad/finaliz/respondid/resolvid/etc.") nunca contam como vencidos, mesmo que o prazo calculado já tenha passado — é assim que o alerta "some sozinho" quando a resposta é dada na MOL e o status atualizado chega num upload seguinte (upsert por `numero` já atualiza o `status` existente).
- **Onde aparece:** banner vermelho/amarelo no topo da view do dia (`renderDiaDados`) quando há vencidos/vencendo em 3 dias; nova coluna "Prazo (10 du captura)" com badge Vencido/Urgente/No prazo em cada tabela de canal (`buildCanalPanel`); KPIs "Vencidas"/"No prazo" no painel de cada canal; nova seção "⏰ Prazos" no topo do Painel Geral com totais gerais.
- Commit `d01518e`, deploy `dpl_F1bDRyveGvJfLDJApxNo2CAydxEt` via `deploy.sh`.

**Correção: `prazoEfetivo` não considerava feriado nacional (13/08/2026, mesmo dia)** — usuário reportou "datas de captura não estão refletindo no app". Investigado: `addDiasUteis()` só pula sábado/domingo, não feriado (Sexta-feira Santa, Corpus Christi etc.). Recalcular sempre do zero a partir da captura divergia da data real em **490 de 1.299 RDR (38%)** — comparado contra o `prazo` oficial que já vem pronto na própria planilha.
- Achado importante: **RDR (100% preenchido) e PROCON (99,9%, só 4 de 3.503 sem) já trazem o Prazo certo pronto na planilha** — não tem porquê o app recalcular pra esses dois canais. Só Consumidor.gov.br não tem esse campo com frequência (841 de 2.461 sem `prazo`, ~34%).
- **Fix:** `prazoEfetivo(r)` agora usa `r.prazo` (o valor real da planilha) quando ele existe, e só cai pra estimativa própria (captura + 10 dias úteis, sem feriado) quando a planilha não trouxe Prazo — normalmente só em Consumidor.
- Coluna da tabela renomeada de "Prazo (10 du captura)" pra "Situação do prazo" (não é sempre um cálculo de captura, na maioria dos casos agora é o valor real). Commit `ac94029`, deploy `dpl_CqHBSCjEbpQ9UpyfoXwPrVsrkLVQ`.

**Correção: Consumidor.gov.br não tem Prazo de resposta real (13/08/2026, mesmo dia)** — usuário perguntou se as 3 datas (Captura, entrada na CIP, Prazo de resposta) estavam sendo consideradas certas nos 3 canais. Ao confirmar, achado que o fix anterior (usar `r.prazo` como deadline real) estava errado especificamente pro Consumidor: `normalizer('consumidor')` grava `prazo: toBR(r['Data de abertura']||'')` — **é a própria data de abertura duplicada, não um prazo de resposta.** A exportação do MOL não traz prazo de resposta pra esse canal (confirmado: 12 de 15 amostras aleatórias tinham `prazo` == `abertura`, dia idêntico). Com o fix anterior, isso fazia o alerta visual marcar praticamente todo registro aberto de Consumidor como "Vencido" desde o dia da captura.
- **Fix:** `prazoEfetivo(r)` só usa `r.prazo` como deadline real pra `rdr` e `procon`. Consumidor sempre usa a estimativa (captura + 10 dias úteis). Commit `1e799f6`, deploy `dpl_DwZxeRazPBCgtWCbUer5rZp3MXiS`.
- **Resumo final de como cada data é considerada, por canal (estado em 13/08/2026):**
  | Canal | Data da Captura | Data entrada CIP | Prazo de resposta |
  |---|---|---|---|
  | RDR/BACEN | `extra1` (planilha, 100% preenchido) | não se aplica (CIP é conceito exclusivo do PROCON) | `prazo` real da planilha, 100% preenchido, já desconta feriado |
  | PROCON | `abertura` (planilha, 100%) | `data_cadastro_cip` (planilha, 99,9%) | `prazo` real da planilha ("Prazo resp. CIP"), 99,9%, já desconta feriado |
  | Consumidor.gov.br | `abertura` (planilha, 100%) | não se aplica (CIP é exclusivo do PROCON) | **não existe na planilha** — estimado no app como captura + 10 dias úteis (só fim de semana, sem feriado — aproximação, não é oficial) |

### 2026-08-12

**Padronização dos campos do RDR/BACEN com a planilha real (ver "Mapeamento RDR/BACEN" acima):**
- Antes: `demanda` no RDR guardava a Situação (duplicado de `status`), e o assunto real ficava escondido em `extra1` desde o cruzamento de 30/07 (ver seção acima, marcada como superada).
- Migração de dados: backup em `canais_criticos_demandas_backup_20260812_rdr` (1.379 linhas) → `UPDATE demanda = extra1, extra1 = ''` nos 1.263 registros que tinham a tag → `demanda` agora é sempre o assunto real, `status` continua com a Situação intacta.
- Código (`normalizar('rdr')` + `headsMap`/`fieldsMap` em `index.html`) reescrito pra ler só os 7 nomes de coluna da planilha `Consolidado Geral.xlsx`, com fallback pros nomes antigos até o usuário renomear os cabeçalhos na planilha (Disponibilização A → Data da Captura; Disponibilização → Data de Ciência).
- **Backfill de Data da Captura** (`extra1`): cruzado por `numero` contra a aba `Consolidado`, 1.265 de 1.265 protocolos únicos bateram (100%), gravado em formato BR (DD/MM/AAAA, igual aos outros campos de data — o backfill inicial saiu em ISO por engano, corrigido em seguida com `to_char(to_date(...),'DD/MM/YYYY')`).
- **Backfill de CPF**: mesmo cruzamento, coluna `CPF/CNPJ` → `cpf`. 1.257 protocolos com CPF na planilha, ~4% vieram sem zero à esquerda (Excel tratando a célula como número) — normalizado com `zfill(11)` antes de gravar. Resultado: CPF preenchido foi de 80 → 1.325 de 1.379 registros do RDR.
- Os poucos registros que sobraram sem Data da Captura/CPF (~50-114, variando por campo) são protocolos recentes (agosto/2026) fora do período coberto por essa planilha específica — não é erro, é lacuna de cobertura temporal.

**Incidente: painel "Registros por mês" perdido e recuperado.** Descoberto quando o usuário notou que o gráfico/lista por mês da Visão Geral tinha sumido depois do deploy da padronização do RDR acima.
- Causa raiz: em 08/08/2026 esse painel (lista "Registros por mês" com filtro de canal, "Detalhe de um mês" e gráfico "Comparativo mensal por canal") foi publicado direto em produção via `vercel deploy`, sem nunca passar por commit/push — o deploy `dpl_G3zbBT3PTVDwxv5GC7MS7hHDRvcz` não tem metadata de git nenhuma (`meta: {}` na API do Vercel).
- Como não tinha rastro em lugar nenhum (nem `git log`, nem memória), o deploy da padronização do RDR (feito a partir do `git main`, que nunca teve esse código) sobrescreveu a funcionalidade em produção sem ninguém perceber, até o usuário notar.
- Recuperação: achado o deploy órfão pela API do Vercel (`list_deployments`, filtrando por data/hora — cada deploy fica acessível na própria URL mesmo depois de não ser mais produção), baixado o HTML exato daquele deploy (`web_fetch_vercel_url` na URL própria do deploy, contorna a proteção SSO), comparado (`diff`, depois de normalizar `\r\n`) contra o commit anterior (`3a83fd0`) pra isolar exatamente o que tinha sido adicionado (funções `renderRegistrosPorMes`, `popularFocoMes`, `renderFocoMes` + o card `pg-mes-chart`). Reaplicado no código atual e **agora commitado de verdade** (`d5b052a`).
- **Prevenção:** ver seção "Deploy — REGRA OBRIGATÓRIA" no topo do arquivo + `deploy.sh` na raiz do repo, criados nesta mesma sessão como consequência direta desse incidente.

### 2026-07-30
**Acesso configurado numa segunda máquina (notebook Q7info):**
- Repo clonado via SSH em `C:\Users\Q7info\dev\monitor-canais-bancarios`
- Vercel CLI autenticada nessa máquina (conta `salvianolopes`, via `npx vercel login`)
- `.env.local` local (gitignorado) com `SUPABASE_URL` + `SUPABASE_ANON_KEY` — só serve pra leitura pública; com RLS `authenticated_full_access` (ver 29/07 abaixo), qualquer leitura/escrita real exige logar como um dos usuários reais listados na seção "Login" e usar o `access_token` da sessão, não a anon key sozinha
- Confirmado por teste (`curl` com só anon key): banco responde `200 []` — RLS bloqueando como esperado
- **Pendência de segurança identificada, ainda não decidida:** as senhas dos 6 usuários (seção "Login" acima) ficam em texto puro neste CLAUDE.md, que é versionado no Git — mesmo o repo sendo privado, fica no histórico permanentemente. Avaliar mover pra fora do arquivo versionado se for incomodar.

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

**Conferência de totais 01/01–30/06/2026 vs. planilha MOL de referência (03/08/2026):** usuário informou números de referência (BACEN 1.147, PROCON 2.568, Consumidor 1.952) pra bater com o banco. RDR e Consumidor bateram. PROCON no banco = 2.609 (41 a mais que a planilha `Downloads\MOLReport.csv`). Investigação linha a linha (diff de protocolos únicos, banco tem 41 que a planilha não tem, planilha não tem nenhum que falte no banco) achou 3 grupos, nenhum é duplicata/erro:
- 20 registros inseridos no mesmo dia 03/08 (sessão concorrente na 2ª máquina), datas de abertura de janeiro legítimas.
- 18 registros são **Procon Uberlândia** (ver formato próprio acima) — fonte que essa planilha específica não cobre.
- 3 registros são casos antigos de 2025 (Procon SP Digital/Paraná) carregados em 26/05, fora do range que a planilha atual exportou.
Conclusão: banco correto, planilha é só um snapshot parcial — sem ação de correção necessária.

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
