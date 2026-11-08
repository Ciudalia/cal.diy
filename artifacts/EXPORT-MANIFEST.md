# Manifiesto de exportación OCI — Cal.diy agenda personal

## Limitación REAL del canal de artefactos del agente

El mount `fuse.agent-store` en `/opt/cursor/artifacts` acepta escrituras hasta ~**96 MiB** (96 MiB OK; 128 MiB → `Invalid argument` al cerrar). El gzip de la imagen (**1 563 630 359 bytes**) **no cabe**. No se fragmentó ni se publicó en registro externo.

En el store del agente solo están este manifiesto, `EXPORT-REAL.txt` y el `.sha256` (metadatos).

## Export REAL (disco del VM del agente)

| Campo | Valor |
| --- | --- |
| Tipo | `docker save \| gzip -1` — **EXPORT REAL** |
| Ruta | `/workspace/artifacts/oci-image/caldiy-personal-2eb48ecc-agenda-amd64.docker.tar.gz` |
| Bytes | `1563630359` |
| SHA256 | `b33da0f8f0fef04ea35cf7c5f55297055b60b4d56309abb4b9b5becaa3895f2c` |
| Tag | `caldiy-personal:2eb48ecc-agenda-amd64` |
| Image ID | `sha256:60c19adab4ea654fab782afe355e0b7c16ecbc0429395e69351315010197c435` |
| Plataforma | `linux/amd64` |
| Verificado | `gzip -t` OK; `docker load` → mismo Image ID |

Copiar al box/VPS por canal privado del operador con capacidad ≥1,5 GiB.
