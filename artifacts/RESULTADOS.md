# Resultados de construcción y smoke tests (Cal.diy personal)

**Estado: ÉXITO verificado en entorno remoto del agente** (no es simulación).

## Referencia exacta

| Campo | Valor |
| --- | --- |
| Fork | `Ciudalia/cal.diy` (parent `calcom/cal.diy`) |
| Commit | `2eb48eccd8aca8a0c0ffabf28cf92e298b33ecee` |
| Fecha | 2026-11-03T21:35:06Z |
| Mensaje | chore(atoms): stop publishing @calcom/atoms from cal.diy (#30445) |
| Imagen local | `caldiy-personal:local` (`sha256:805f72d0613a…`) |

## Build

| Métrica | Valor |
| --- | --- |
| Inicio UTC | 2026-11-08T21:23:02Z |
| Fin UTC | 2026-11-08T21:31:05Z |
| Duración | ~8 min |
| Dockerfile | `artifacts/Dockerfile` (Node bookworm fijado por digest) |
| Tamaño imagen sin comprimir | **7 477 407 377 bytes (~6,96 GiB)** |
| Estimación `docker save \| gzip` | **1 563 483 906 bytes (~1,46 GiB)** |
| Arquitectura | linux/amd64 |

No se publicó a Docker Hub, GHCR ni Scarf. No se usó imagen comunitaria no auditada.

## Smoke tests reales

Stack: PostgreSQL 16 + Redis 7 privados en red Compose; puertos solo en `127.0.0.1`. App en loopback `:3000`.

| Prueba | Resultado |
| --- | --- |
| Postgres healthy | OK |
| Redis healthy | OK |
| `prisma migrate deploy` | OK (595 migraciones; schema up to date) |
| Seed app-store | OK |
| `yarn start` / Next.js Ready | OK |
| `GET /auth/login` | **307 → /auth/setup** |
| `GET /auth/setup` | **307 → /auth/setup?step=1** |
| `GET /auth/setup?step=1` | **200** HTML (~348 KB) con señales setup/admin/password/Cal.diy |
| Docker HEALTHCHECK | **healthy** |
| SMTP real | No usado (host `127.0.0.1:1025`, sin envíos) |
| Telemetría | `CALCOM_TELEMETRY_DISABLED=1` |

## Incidente de red (documentado, resuelto)

En este host coexistían reglas **iptables-legacy** (FORWARD policy DROP) e **iptables-nft** (Docker). El bridge Compose resolvía DNS pero el TCP entre contenedores hacía timeout. Tras `iptables-legacy -P FORWARD ACCEPT`, la conectividad `database:5432` / `redis:6379` funcionó y el smoke pasó.

En un VPS Ubuntu 24.04 “limpio” con solo el backend nft de Docker suele no hacer falta; si aparece el mismo síntoma, aplicar la misma corrección o unificar el backend de iptables.

## Traslado OCI seguro (sin acceso VPS desde aquí)

```bash
# En la máquina de build (ejemplo)
docker save caldiy-personal:local | gzip -1 > caldiy-personal-local.tar.gz
sha256sum caldiy-personal-local.tar.gz > caldiy-personal-local.tar.gz.sha256
# Transferir por canal privado (scp/rsync/USB cifrado). NO subir a registro público sin permiso.
# En destino:
gunzip -c caldiy-personal-local.tar.gz | docker load
```

Tamaño esperado ~1,5 GiB comprimido. No se dejó el `.tar.gz` en git (ignorado).

## Límites conscientes

- No se alteró DNS de `agenda.ciudalia.com` ni se conectó al VPS.
- OpenWA y demás servicios del VPS no se tocaron.
- Secretos solo en `artifacts/secrets-local/` (gitignored), sintéticos.
- SMTP de producción pendiente; pruebas sin sends reales.
