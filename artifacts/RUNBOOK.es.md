# Runbook: Cal.diy agenda personal / pruebas (Ciudalia)

Objetivo: construir y operar **Cal.diy** desde el fork `Ciudalia/cal.diy` con PostgreSQL privado y app en loopback, sin usar imágenes Docker Hub/Scarf no verificadas y sin tocar DNS/VPS/OpenWA.

## 1. Requisitos

- Ubuntu 24.04 amd64 (verificado también en agente cloud)
- Docker Engine ≈ 29.x + Compose plugin ≈ 5.x
- ≥ 4 vCPU, ≥ 16 GiB RAM, disco libre generoso (build + imagen ~7 GiB + capas)
- Ref congelada: ver `artifacts/REF.txt` (`2eb48eccd8aca8a0c0ffabf28cf92e298b33ecee`)

## 2. Preparar secretos sintéticos (nunca en git)

```bash
mkdir -p artifacts/secrets-local
cp artifacts/env.personal.example artifacts/secrets-local/env.personal
# Editar y generar:
#   NEXTAUTH_SECRET=$(openssl rand -base64 32)
#   CALENDSO_ENCRYPTION_KEY=$(openssl rand -base64 24)
#   POSTGRES_PASSWORD=...  JWT_SECRET=...  CRON_API_KEY=...
# Añadir BUILD_DATABASE_URL=postgresql://USER:PASS@127.0.0.1:5432/DB
chmod 600 artifacts/secrets-local/env.personal
```

## 3. Arrancar base de datos

```bash
set -a && source artifacts/secrets-local/env.personal && set +a
# Si el bridge Docker falla con timeouts TCP entre contenedores:
#   sudo iptables-legacy -P FORWARD ACCEPT
docker compose -f artifacts/docker-compose.personal.yml --env-file artifacts/secrets-local/env.personal up -d database redis
```

Comprobar: `docker compose -f artifacts/docker-compose.personal.yml ps` → database/redis **healthy**, puertos `127.0.0.1:5432` y `:6379`.

## 4. Construir imagen (reproducible)

```bash
export DOCKER_BUILDKIT=1
docker compose -f artifacts/docker-compose.personal.yml --env-file artifacts/secrets-local/env.personal build calcom
```

Notas:

- Build usa `network: host` + `BUILD_DATABASE_URL` a `127.0.0.1:5432` (Postgres ya publicado en loopback).
- Telemetría deshabilitada por defecto en el Dockerfile adaptado.
- Base Node: `node:22-bookworm@sha256:7702d8aa…` (ver Dockerfile).

## 5. Arrancar aplicación y migraciones

```bash
docker compose -f artifacts/docker-compose.personal.yml --env-file artifacts/secrets-local/env.personal up -d calcom
docker logs -f caldiy-personal-app
# Esperar: migrate deploy OK, seed apps, «Ready», HEALTHCHECK healthy
```

`scripts/start.sh` ejecuta `prisma migrate deploy` y seed del app-store automáticamente.

## 6. Smoke checks

```bash
curl -sI http://127.0.0.1:3000/auth/login    # 307 → /auth/setup (primera instalación)
curl -sI http://127.0.0.1:3000/auth/setup    # 307 → ?step=1
curl -sI 'http://127.0.0.1:3000/auth/setup?step=1'  # 200
docker exec caldiy-personal-app npx prisma migrate status --schema /calcom/packages/prisma/schema.prisma
```

Abrir en navegador local: `http://127.0.0.1:3000/auth/setup` y crear el usuario admin (datos de prueba).

## 7. Correo

Configurar SMTP real **más adelante**. En pruebas: `EMAIL_SERVER_HOST=127.0.0.1` / puerto `1025` (MailHog u otro sumidero). No enviar correo real desde este stack.

## 8. Mantenimiento / restauración

| Acción | Comando |
| --- | --- |
| Parar app | `docker compose -f artifacts/docker-compose.personal.yml stop calcom` |
| Backup DB | `docker exec caldiy-personal-db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \| gzip > backup.sql.gz` |
| Restaurar DB | `gunzip -c backup.sql.gz \| docker exec -i caldiy-personal-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"` |
| Logs | `docker logs --since 1h caldiy-personal-app` |
| Actualizar código | checkout nuevo commit auditado → rebuild → recreate calcom |
| Destruir volúmenes (borra datos) | `docker compose -f artifacts/docker-compose.personal.yml down -v` |

Volúmenes: `caldiy-personal_database-data`, `caldiy-personal_redis-data`.

## 9. Destino futuro VPS (sin ejecutar desde aquí)

- Host: Ubuntu 24.04, Docker 29, Compose 5, 4 vCPU / 16 GB / disco amplio.
- Colocar stack **aparte** de OpenWA (otros compose/project name/puertos).
- TLS: terminar en reverse proxy (Caddy/Nginx) con certificados reales; **no** desactivar TLS en producción.
- DNS `agenda.ciudalia.com`: cambiar solo cuando el proxy local responda en 443 (ahora Zoho — no alterar hasta cutover).
- Traslado imagen: ver `RESULTADOS.md` (`docker save | gzip`, checksum, canal privado). Alternativa: rebuild en el VPS desde este commit (recomendado si hay CPU/RAM).

## 10. Seguridad / licencia

- Conservar `LICENSE` (MIT) y avisos de copyright.
- No commitear `.env` ni `artifacts/secrets-local/`.
- No exponer Postgres/Redis fuera de loopback o red interna.
- No publicar la imagen OCI a registros externos sin permiso explícito.
- PR solo contra `Ciudalia/cal.diy`, nunca upstream `calcom/cal.diy` para este trabajo de despliegue personal.
