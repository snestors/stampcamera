# Play Store — gestión del listing por API

Assets y script para actualizar la ficha de Play Store de `com.nestorfar.stampcamera`
sin tocar el Play Console a mano.

## Contenido

| Archivo | Qué es |
|---|---|
| `assets/icon_512.png` | Ícono de la ficha (512×512, & blanco sobre azul #0A2D3E) |
| `assets/feature_graphic_1024x500.png` | Banner superior de la ficha |
| `assets/launcher_icon_1024.png` | Base para regenerar el launcher icon (azul + & blanco) |
| `assets/ic_foreground_1024.png` | Foreground para adaptive icon Android (con safe zone) |
| `listing.json` | Textos de la ficha: título, descripciones, notas de versión |
| `update_listing.py` | Sube todo vía Google Play Developer API |
| `keys/` | Service account JSON (**gitignored**, nunca commitear) |

## Setup de la service account (una sola vez)

1. **Google Cloud Console** (https://console.cloud.google.com):
   - Crear/elegir un proyecto → APIs y servicios → habilitar **Google Play Android Developer API**.
   - IAM y administración → Cuentas de servicio → **Crear cuenta de servicio** (ej. `play-publisher`).
   - En la cuenta creada → Claves → Agregar clave → **JSON** → descargar.
2. **Play Console** (https://play.google.com/console):
   - Usuarios y permisos → **Invitar usuario nuevo** → pegar el email de la service account
     (`play-publisher@<proyecto>.iam.gserviceaccount.com`).
   - Permisos de app → agregar **AYG** → marcar al menos:
     - *Ver información de la app*
     - *Administrar presencia en Google Play Store*
     - *Administrar versiones de prueba* (solo si se quieren editar notas de versión)
3. Guardar el JSON descargado en `playstore/keys/`.

## Uso

```bash
python update_listing.py show     # ver estado actual (verifica que la llave funciona)
python update_listing.py apply    # subir textos + ícono + feature graphic
python update_listing.py apply --notes   # además reescribir notas de la beta actual
```
