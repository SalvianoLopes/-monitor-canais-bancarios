#!/bin/bash
# Deploy seguro pro canais-criticos.
# Bloqueia o deploy se houver qualquer coisa não commitada ou não pushada,
# pra nunca mais repetir o incidente de 08/08/2026 (funcionalidade publicada
# direto em produção sem passar por commit — ver CLAUDE.md).
set -e

if [ -n "$(git status --porcelain)" ]; then
  echo "ERRO: há mudanças não commitadas. Rode 'git add' + 'git commit' antes de dar deploy."
  git status --short
  exit 1
fi

git fetch origin main --quiet
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "ERRO: HEAD local ($LOCAL) diverge de origin/main ($REMOTE)."
  echo "Rode 'git push origin main' antes de dar deploy."
  exit 1
fi

echo "OK: working tree limpo e sincronizado com origin/main ($LOCAL). Deployando..."
npx vercel deploy --prod --yes
