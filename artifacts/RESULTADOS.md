# Resultados — export REAL + portabilidad destino

## Distinción explícita: disponible vs estimado

| Concepto | Estado |
| --- | --- |
| Tamaño imagen Docker (`docker image inspect`) | **MEDIDO**: `7477436455` bytes |
| Archivo `docker save \| gzip -1` | **EXPORT REAL en disco**: `1563630359` bytes |
| SHA256 del archivo gzip | **REAL**: `b33da0f8f0fef04ea35cf7c5f55297055b60b4d56309abb4b9b5becaa3895f2c` |
| Image ID completo | `sha256:60c19adab4ea654fab782afe355e0b7c16ecbc0429395e69351315010197c435` |
| Entrega vía `/opt/cursor/artifacts` (fuse.agent-store) | **BLOQUEADA por límite real ~96 MiB** (128 MiB falla al cerrar el archivo). El gzip de 1,46 GiB **no cabe**. No se fragmentó ni se publicó en registro. |
| Manifiesto + checksum en store del agente | **Disponible** (archivos pequeños): ver `/opt/cursor/artifacts/EXPORT-MANIFEST.md` |
| Blob OCI descargable desde el store del agente | **NO disponible** (limitación del canal) |
| Blob OCI en disco del VM del agente | **SÍ**: `/workspace/artifacts/oci-image/caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz` |

Verificación del export: `gzip -t` OK; `docker load` del archivo recargó la misma imagen con el mismo Image ID.

## Referencia

- Commit: `2eb48eccd8aca8a0c0ffabf28cf92e298b33ecee`
- Tag: `caldiy-personal:2eb48ecc-agenda-amd64`
- Plataforma: `linux/amd64`
- URL embebida (rebuild): `https://agenda.ciudalia.com`
- Telemetría: deshabilitada

## Auditoría de secretos / URL

| Chequeo | Resultado |
| --- | --- |
| Secretos de runtime NUEVOS en filesystem de la imagen | 0 coincidencias |
| Dummies de build en filesystem final | 0 coincidencias |
| Secretos en Env final de la imagen | no presentes (solo URL/NODE_ENV) |
| `127.0.0.1:5432` en capas | solo fixtures de tests de Prisma (`prisma+postgres://…/test`), sin password |
| Chunks estáticos con agenda URL | 14 archivos |
| Chunks estáticos con `http://127.0.0.1:3000` | 0 (tras rebuild) |

## Pruebas NUEVAS ejecutadas (esta iteración)

1. Rebuild con URL destino + secretos dummy de build (no runtime).
2. `docker save | gzip -1` → archivo real + `sha256sum` + `gzip -t`.
3. `docker load` del gzip → mismo Image ID.
4. Medición del límite del store FUSE (96 MiB OK / 128 MiB FAIL).
5. Stack `docker-compose.destino.yml`: sin `build:`, BD/Redis/Mailpit **sin ports**, app `127.0.0.1:3000`.
6. Smoke: `/auth/setup?step=1` → **200**; 595 migraciones up to date; health **healthy**.
7. Portabilidad: HTML contiene `agenda.ciudalia.com`; `Host: agenda.ciudalia.com` → 200 vía loopback (sin DNS).
8. SMTP: `EMAIL_SERVER_HOST=mailpit`, puerto 1025 alcanzable en red interna; **sin ports** al host; sin envíos externos.
9. Escaneo de secretos runtime/build en la imagen tras las pruebas.

## Compose destino

Ver `artifacts/docker-compose.destino.yml`.

## Runbook

Ver `artifacts/RUNBOOK.es.md` (sin recomendar iptables/FORWARD en VPS).
