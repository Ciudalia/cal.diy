# Runbook: Cal.diy agenda personal / destino (Ciudalia)

## 1. Artefacto de imagen (export REAL)

En el VM del agente (ruta local, **no** git):

```
/workspace/artifacts/oci-image/caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz
```

- Bytes: `1563630359`
- SHA256: `b33da0f8f0fef04ea35cf7c5f55297055b60b4d56309abb4b9b5becaa3895f2c`
- Image ID: `sha256:60c19adab4ea654fab782afe355e0b7c16ecbc0429395e69351315010197c435`
- Tag: `caldiy-personal:2eb48ecc-agenda-amd64`
- Plataforma: `linux/amd64`

**Canal store del agente (`/opt/cursor/artifacts`)**: límite real ~96 MiB; el gzip no cabe. Solo hay manifiesto/checksum allí. Transportar el blob por canal privado del operador (scp/rsync/USB) capaz de ~1,5 GiB. No fragmentar ni publicar en registro externo.

```bash
sha256sum -c caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz.sha256
gunzip -c caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz | docker load
# o: docker load -i caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz
```

## 2. Secretos runtime (nuevos, fuera de git)

```bash
mkdir -p artifacts/secrets-local
cp artifacts/env.personal.example artifacts/secrets-local/env.destino.runtime
# Generar NEXTAUTH_SECRET, CALENDSO_ENCRYPTION_KEY, POSTGRES_PASSWORD, JWT_SECRET
# NEXT_PUBLIC_WEBAPP_URL=https://agenda.ciudalia.com
# EMAIL_SERVER_HOST=mailpit  EMAIL_SERVER_PORT=1025
chmod 600 artifacts/secrets-local/env.destino.runtime
```

No meter secretos en el export OCI ni en git.

## 3. Arranque destino

```bash
set -a && source artifacts/secrets-local/env.destino.runtime && set +a
docker compose -f artifacts/docker-compose.destino.yml --env-file artifacts/secrets-local/env.destino.runtime up -d
```

Propiedades del compose destino:

- **Sin `build:`** — solo imagen precargada
- **BD y Redis sin `ports:`** — solo red interna
- **Mailpit** sumidero SMTP interno (sin `ports:`)
- **App** publicada solo en `127.0.0.1:3000`
- TLS: terminar en reverse proxy del host (no desactivar TLS en producción)

## 4. Smoke

```bash
curl -sI http://127.0.0.1:3000/auth/setup?step=1
curl -sI -H 'Host: agenda.ciudalia.com' http://127.0.0.1:3000/auth/setup?step=1
./artifacts/scripts/smoke.sh
docker exec caldiy-destino-app npx prisma migrate status --schema /calcom/packages/prisma/schema.prisma
```

Primera visita → flujo `/auth/setup` para crear admin.

## 5. Correo

SMTP real **pendiente**. Con este stack, todo mail va a **Mailpit** (`mailpit:1025`) en la red compose. No hay publicación de puertos SMTP/UI al host; no hay envíos externos.

## 6. Mantenimiento

| Acción | Comando |
| --- | --- |
| Parar | `docker compose -f artifacts/docker-compose.destino.yml stop` |
| Backup DB | `docker exec caldiy-destino-db pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \| gzip > backup.sql.gz` |
| Restaurar | `gunzip -c backup.sql.gz \| docker exec -i caldiy-destino-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"` |
| Actualizar imagen | cargar nuevo tar verificado → `compose up -d calcom` |

## 7. VPS futuro (checklist, sin ejecutar desde aquí)

- Ubuntu 24.04, Docker 29, Compose 5; proyecto aparte de OpenWA
- Cargar imagen + compose destino; secretos solo en el host
- Reverse proxy TLS hacia `127.0.0.1:3000`
- DNS `agenda.ciudalia.com`: cutover solo cuando 443 local responda (hoy Zoho — no alterar aún)
- **No** aplicar workarounds iptables/FORWARD del entorno del agente cloud al VPS

## 8. Seguridad / alcance

- Licencia MIT conservada
- PR solo a `Ciudalia/cal.diy`
- Sin registros externos, sin credenciales VPS, sin tocar OpenWA/DNS/Zoho
