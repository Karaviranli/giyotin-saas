#!/bin/bash
set -e
cd /root/giyotin-saas
echo '[deploy] Backend rebuild ediliyor, DB dokunulmaz...'
docker compose build --no-cache backend
docker compose up -d --no-deps backend
sleep 3
echo '[deploy] Tamamlandi. Son loglar:'
docker logs kavira_backend --tail 10
