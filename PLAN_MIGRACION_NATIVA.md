# Plan de Migración stampcamera: Flutter → Kotlin Multiplatform (Android primero, iOS después)

**App:** stampcamera v1.5.3 — Inspección vehicular portuaria, A&G Ajustadores
**Codebase verificado:** 65.317 LOC Dart · 170 archivos · 41 screens + 39 widgets
**Backend:** Django REST + WebSocket (`wss .../ws/app/`)
**Fecha:** 2026-06-03 · **Arquitecto líder:** síntesis de inventario + 3 verificaciones adversariales

---

## 📌 Decisiones y pendientes — sesión 2026-06-03 (LEER PRIMERO)

**Decisiones de alcance tomadas:**

- **Casos → FUERA del alcance.** El módulo de gestión documental (`explorador` + `casos_multi_camera`) NO se migra. Eliminar la **Fase 6** y sus ~3.7k LOC en la próxima revisión de fases.
- **Cámara = módulo de PRIMERA CLASE y dual-propósito** (reemplaza el hueco que deja Casos):
  - *Evidencia embebida*: dentro de los forms → foto VIN, presentación, daños (autos) y tickets (granos). Atada SOLO a su registro.
  - *Cámara standalone*: app de cámara pura → todo a la galería del teléfono, **con watermark** (logo + GPS + hora).
  - El motor de cámara + watermark (CameraX/AVFoundation + Canvas/CoreGraphics) es **infra COMPARTIDA** que alimenta ambos modos.
- **`RegistroVin.jornada` es server-side only** (verificado en código): el cliente Flutter NO la usa ni la manda; `obtener_jornada(nave, hora)` la calcula el backend al guardar, solo para agrupar el reporte de pedeteo en turnos de 8h. **El modelo cliente KMP NO lleva `jornada`** — un campo menos que arrastrar.

**PENDIENTE — Respaldo de cámara (DEFINIR en la próxima sesión):**

Feature nueva propuesta: que TODO lo capturado con la cámara standalone (**fotos Y videos** — el video sería capability nueva, hoy la app es solo fotos) se vincule a una **carpeta por usuario** y se respalde **temporalmente** en DigitalOcean Spaces.

- *Arquitectura propuesta:* subida **presigned directo a Spaces** (NO por worker Django, los videos tapan workers), en un **carril de baja prioridad** separado del SyncEngine de evidencia (que no se retrase la prueba legal por un video pesado); tabla `RespaldoCaptura` (usuario, key, tipo foto/video, fecha, GPS) como solo-metadato; retención + lifecycle del bucket + tarea Celery de limpieza.
- *4 decisiones abiertas:*
  1. **Retención "temporal":** ¿30 / 60 / 90 días y se borra solo? (define el costo en Spaces — los videos pesan).
  2. **¿El video lleva watermark?** Caro (recodificar con overlay) vs timestamp/GPS quemado vs video limpio y solo fotos selladas.
  3. **¿La carpeta del usuario es para CONSULTAR/restaurar desde la app, o solo red de seguridad write-only** (se recupera desde el admin)?
  4. **Alcance:** ¿solo cámara standalone, o también copia sombra de la evidencia (daños/fotos) por inspector?

---

## 1. Resumen ejecutivo y recomendación

### Recomendación

> **✅ DECISIÓN D1 RESUELTA (2026-06-03):** iOS confirmado como compromiso **FIRME** (iPhone 100% requerido; Android primero solo porque la cuenta Apple Developer está en trámite). La recomendación deja de ser condicional: **KMP es la opción DEFINITIVA**. Android primero entrega `commonMain`+`androidMain`; iOS engancha el MISMO framework al habilitarse la cuenta Apple. Confianza ajustada a **~0,80**. Cutover recomendado: **Opción A — app paralela** (segundo applicationId + piloto con un turno en Android / TestFlight en iOS). Ver §9 y §10.

**Adoptar KMP (Kotlin Multiplatform) con lógica compartida en `commonMain` + UI 100% nativa (Jetpack Compose en Android, SwiftUI en iOS), CONDICIONADO a un compromiso real de iOS.** Confianza: **0,72**.

Esta no es una recomendación incondicional. La decisión correcta **depende de una pregunta que el usuario debe responder** (ver §10, Decisión D1):

- **Si iOS es un ítem firme del roadmap** → KMP es la opción correcta AHORA. Se escribe UNA sola vez la capa más riesgosa (auth/refresh, WebSocket, colas offline, contrato API contra Django) y iOS la consume sin reescribir el dominio.
- **Si iOS es meramente aspiracional** → el camino de menor riesgo es **Kotlin + Compose nativo Android puro (NO multiplataforma)**, estructurando la lógica en módulos Kotlin limpios que se pueden *promover* a `commonMain` más adelante cuando iOS tenga presupuesto. Esto captura casi toda la disciplina de KMP sin pagar su impuesto de tooling (`expect/actual`, interop Kotlin→Swift) mientras solo existe Android.

> **Honestidad crítica:** KMP solo paga su dividendo cuando iOS realmente se entrega. Con iOS diferido ("ideal, después"), el día del lanzamiento **una sola plataforma** consume `commonMain`, así que el ahorro por no-duplicar es CERO hasta que iOS shippea, mientras el costo de complejidad de KMP se paga desde el día 1. No ocultamos esta condicionalidad.

### Por qué KMP y no las alternativas

| Opción | Veredicto | Razón decisiva (verificada en código) |
|---|---|---|
| **KMP shared + Compose/SwiftUI** ✅ | **Recomendada (si iOS firme)** | La separación lógica/UI es REAL: models 0/16, services 18/20, providers 17/19 NO importan UI de Flutter. La capa más propensa a bugs (auth refresh thread-safe, WS, colas) se escribe una vez. |
| **Full-native independiente** (Kotlin/Swift sin compartir) | Descartada | DUPLICA el dominio offline-first más frágil en Kotlin Y Swift = dos fuentes de verdad para `http_service` (572 LOC), `app_socket_service` (397 LOC) y las colas. En una app offline-first portuaria es el peor lugar para duplicar. |
| **Compose Multiplatform** (UI también compartida) | Descartada | App cámara-pesada: **5 superficies de cámara + 2 de scanner** (verificado). El "feel" nativo y el control de cámara/batería exigen CameraX/AVFoundation; CMP sigue siendo un canvas Skia = "cambiar Flutter por otro Flutter en Kotlin". Contradice el driver principal del usuario. |
| **Stay Flutter + optimizar** | Descartada (no cumple constraint) | No abandona Flutter. Techos estructurales persisten: jank de platform-views de cámara, watermark atado a `dart:ui`, background sync en isolate principal (NO WorkManager). Útil solo como ancla de costo de oportunidad. |

### Ajustes de honestidad aplicados (vs el análisis inicial)

Los verificadores rechazaron tres afirmaciones infladas del borrador. **Las corregimos aquí:**

1. **Los 19 providers NO se "portan 1:1" — se REESCRIBEN.** Los 19/19 importan Riverpod y se construyen sobre `StateNotifier`/`AsyncNotifier`/`Ref` (6.284 LOC). Esa maquinaria reactiva no tiene equivalente mecánico en Kotlin; es una reescritura completa a coroutines/`Flow`/`StateFlow`. Solo `http_service` (3/20 con Riverpod) y el socket (Dart plano) portan casi 1:1. **Presupuestar esos 6.284 LOC como reescritura.**
2. **La cifra "35-45% compartido" estaba inflada. El real es ~28% del LOC.** Por LOC verificados: models 5.029 + services 7.147 + providers 6.284 = 18.460 de 65.317 = **~28%**. Y dentro de "services", `camera_service`, `update_service` e `image_processor` (781 LOC `dart:ui`) NO son compartibles. La UI (screens 24.330 aprox + widgets 12.180 + core ~8.836 + routes 457) es **~70%** y se reescribe de todas formas. El 28% sí es el 28% *más riesgoso*, pero es menor de lo que se dijo.
3. **El bug "cola `PendingRequest` nunca procesada" es real pero INMATERIAL como driver.** `processPendingRequests()` y `cleanExpiredRequests()` están definidos pero tienen **cero llamadores** (verificado por grep: solo la definición). Es código muerto, no un defecto funcional del path offline real (que usa las 3 colas de SharedPreferences). Lo citamos como deuda a limpiar, no como justificación de la migración.

---

## 2. Arquitectura objetivo por capas

### Qué vive en `commonMain` (compartido) vs UI nativa

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          UI NATIVA (NO compartida ~70% LOC)               │
│                                                                           │
│   ANDROID (androidMain)                    iOS (iosMain)                   │
│   Jetpack Compose Material3                SwiftUI                         │
│   - 41 screens + 39 widgets pixel-perfect  - List/NavigationStack         │
│   - LazyColumn/LazyVerticalGrid            - .sheet/fullScreenCover        │
│   - ModalBottomSheet (forms slide-up)      - .badge() (conteos)           │
│   - BadgedBox (badges de tabs)             - consume el MISMO framework    │
│   - Theme desde design_tokens portados     - cero reescritura de dominio  │
└───────────────────────────────┬───────────────────────────────────────────┘
                                 │  llamadas a UseCases / observa StateFlow
┌───────────────────────────────▼───────────────────────────────────────────┐
│              COMMONMAIN — LÓGICA COMPARTIDA (~28% LOC, el 28% más riesgoso) │
│                                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │ Domain / Modelos │  │  Casos de uso /  │  │  Estado reactivo         │ │
│  │ 16 data classes  │  │  Repositories    │  │  StateFlow/Flow          │ │
│  │ @Serializable    │  │  (REESCRITOS     │  │  (reemplaza Riverpod —   │ │
│  │ (kotlinx.ser.)   │  │  desde 19 prov.) │  │  REESCRITURA, no port)   │ │
│  └──────────────────┘  └──────────────────┘  └──────────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │ Network: Ktor    │  │ WebSocket: Ktor  │  │ Persistencia: SQLDelight │ │
│  │ Client (port 1:1 │  │ WS (port de      │  │ COLA UNIFICADA (reemplaza│ │
│  │ de http_service: │  │ app_socket_svc:  │  │ queue_records +          │ │
│  │ refresh Mutex,   │  │ ticket→ws/app/,  │  │ offline_first_queue +    │ │
│  │ X-Device-ID,     │  │ heartbeat 30s,   │  │ pending_registros)       │ │
│  │ retry 401)       │  │ backoff EXP+jit) │  │ + SyncEngine + lease     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────────────────┘ │
└──────┬──────────────────────────────────────────────────────┬─────────────┘
       │ expect/actual                                         │ expect/actual
┌──────▼──────────────────────┐                  ┌─────────────▼──────────────┐
│  PLATAFORMA Android          │                  │  PLATAFORMA iOS             │
│  - Keystore/EncryptedSharedP │                  │  - Keychain (Security fwk)  │
│  - ConnectivityManager       │                  │  - NWPathMonitor            │
│    (NET_CAPABILITY_VALIDATED)│                  │  - NSDocumentDirectory      │
│  - CameraX + ML Kit          │                  │  - AVFoundation + Vision    │
│  - android.graphics.Canvas   │                  │  - CoreGraphics (watermark) │
│  - FusedLocation             │                  │  - CoreLocation             │
│  - WorkManager (drena cola)  │                  │  - URLSession background +   │
│  - BiometricPrompt+CryptoObj │                  │    BGTaskScheduler (reprog.) │
│  - Play Core in-app update   │                  │  - LAContext (FaceID)        │
│                              │                  │  - (in_app_update = no-op)  │
└──────────────────────────────┘                  └─────────────────────────────┘
```

### Tabla de capas

| Capa | Tecnología | ¿Compartida? | Notas verificadas |
|---|---|---|---|
| Domain / Modelos | Kotlin + kotlinx.serialization | ✅ Sí | 16 models → data classes. Consolidar duplicados: **FieldPermission tiene 4 definiciones Dart** (contenedor_model, danos_options_models, registro_vin_options + doc) e **InformacionUnidad x2**. Corregir swap **`viajesMuelle`/`viajesBalanza`** (verificado líneas 675-676: leen las claves JSON cruzadas). |
| Casos de uso / Repos | Kotlin coroutines/Flow | ✅ Sí (**REESCRITO**) | 6.284 LOC de 19 providers Riverpod → UseCases. NO es port mecánico. Paginación `BaseListProvider`, merge optimista, interpretación de `field_permissions`/`initial_values`. |
| Network HTTP | Ktor Client (OkHttp Android / Darwin iOS) | ✅ Sí (port ~1:1) | Port de `http_service` (572 LOC): plugin auth, refresh thread-safe con **Mutex de coroutines** (equiv. a `List<Completer<bool>>` + `_isRefreshing`), header `X-Device-ID`, retry 401, **recreación de multipart en retry** (`_recreateFormData`). Eliminar la cola en memoria muerta. |
| WebSocket | Ktor WebSockets | ✅ Sí | Port de `app_socket_service` (397 LOC): ticket single-use `POST api/v1/ws/ticket/` → `wss .../ws/app/?ticket=`, heartbeat 30s, 4 eventos (`force_logout`, `permissions_updated`, `data_changed`, `notification`). **FIX:** backoff hoy es LINEAL (`_reconnectBaseDelay * (attempts+1)`) → cambiar a exponencial + jitter. |
| Persistencia local | SQLDelight | ✅ Sí | Cola UNIFICADA (ver §4). filePaths con `expect/actual` (Android `filesDir` / iOS `NSDocumentDirectory`). |
| Auth / Secure storage | `expect/actual`: Keystore (Android) / Keychain (iOS) | ⚠️ Orquestación sí, storage no | Orquestación (`loggedIn`/`loggedOut` vía `AuthStatus` enum — **no hay status `offline` discreto**, se maneja vía `AsyncValue`) en commonMain. Storage cifrado nativo. |
| UI Android | Jetpack Compose Material3 | ❌ No | 41 screens + 39 widgets pixel-perfect. |
| UI iOS | SwiftUI | ❌ No | Consume el mismo framework. |
| Cámara + pipeline imagen | CameraX + `android.graphics.Canvas` / AVFoundation + CoreGraphics | ❌ No | Watermark usa `dart:ui` Canvas/PictureRecorder/TextPainter (verificado líneas 459-577) → reimplementar nativo. |
| Background sync | WorkManager / URLSession-background + BGTaskScheduler | ❌ No | Hoy es `Timer` en isolate principal (verificado, NO WorkManager). |
| In-app update | Play Core / no-op iOS | ❌ No | `in_app_update ^4.2.5` con `performImmediateUpdate()` (verificado). Sin equivalente en App Store. |

---

## 3. Tabla maestra de plugins: Flutter → nativo → KMP

> Versiones verificadas en `pubspec.yaml`. **🔴 = BLOCKER de paridad.**

| Plugin Flutter | Android nativo | iOS nativo | KMP compartido | Riesgo / Esfuerzo |
|---|---|---|---|---|
| **camera ^0.11.2** | CameraX (camera-core/camera2/lifecycle/view); PreviewView + ImageCapture | AVCaptureSession + AVCapturePhotoOutput; preview vía `UIViewRepresentable` | ❌ Solo la máquina de estados (flag capturing, retry resolución, lista capturas) | **med / high** — `ReusableCameraCard` = 964 LOC (verificado), archivo más complejo de portar. Retry `veryHigh→high→medium` verificado. |
| **mobile_scanner ^7.0.1** | ML Kit Barcode + CameraX ImageAnalysis | Vision (`VNDetectBarcodesRequest`) o `DataScannerViewController` (iOS 16+) | ❌ Solo validación VIN 17 chars + dedup en common | **low / med** — usado en `scanner_widget` y `vin_scanner_screen` (verificado). |
| **geolocator ^14.0.2** | FusedLocationProviderClient (`Priority.HIGH_ACCURACY`) | CoreLocation `CLLocationManager` | `expect/actual`; cache 5 min + timeout 10s en common | **low / low** |
| **geocoding ^4.0.0** | `Geocoder.getFromLocation` (⚠️ síncrono <API 33 → executor IO; callback en 33+) | `CLGeocoder.reverseGeocodeLocation` | `expect/actual`; timeout 5s en common (verificado) | **low / low** |
| **local_auth ^2.3.0** | `BiometricPrompt` + `BiometricManager` + **CryptoObject** | `LAContext.evaluatePolicy` (distingue Face/Touch ID) | ❌ `expect/actual` obligatorio | **med / med** — `stickyAuth` NO existe nativo en iOS (ajustar UX). **Corrección del verificador:** la password NO está "en plano" — se guarda con `flutter_secure_storage` (CIFRADA en reposo, verificado `_storage.write`). El issue real es que **NO está ligada criptográficamente a la biometría vía CryptoObject**. El fix con BiometricPrompt+CryptoObject lo resuelve. |
| **flutter_secure_storage ^9.2.4** | EncryptedSharedPreferences (Keystore AES256_GCM) | Keychain (`kSecAttrAccessibleAfterFirstUnlock`) | multiplatform-settings cifrado o `expect/actual` | **med / med** — 🔴 **RIESGO DE CORTE:** el cifrado está atado a la firma del binario. La app nativa nueva NO podrá leer datos del binario Flutter → re-login forzado de TODOS los usuarios (confirmado por comentario en `storage_health_service`). |
| **dio ^5.8.0+1** | Retrofit + OkHttp | URLSession | ✅ **Ktor Client** (OkHttp/Darwin) | **low / med** — excelente candidato. Edge case verificado: recrear multipart en retry (el body se consume). |
| **web_socket_channel ^3.0.2** | OkHttp WebSocket | URLSessionWebSocketTask | ✅ **Ktor WebSockets** | **low / med** — **Corrección del verificador:** el endpoint real es **`/ws/app/`**, NO `/ws/presencia/`. Y `force_logout` se emite **UNA sola vez** (verificado: `return` antes del `add` final, línea 290) — el "doble-emit" del borrador NO aplica. Sí corregir backoff lineal→exponencial. |
| **connectivity_plus ^6.1.4** | `ConnectivityManager.NetworkCallback` + `NET_CAPABILITY_VALIDATED` | `NWPathMonitor` | `expect/actual` → `Flow<ConnectivityState>` | **low / low** — FIX confirmado: hoy usa solo `checkConnectivity()` (interfaz, no alcanzabilidad) → falsos online en WiFi cautivo portuario. |
| **shared_preferences ^2.5.3** | DataStore (flags) + SQLDelight (colas) | UserDefaults (flags) + SQLDelight | multiplatform-settings (flags); **SQLDelight (colas)** | **low / med** — backend de las 3 colas offline (`queue_records`, `offline_first_queue`, `pending_registros`, verificado). Mover a SQLDelight (atómico, sin ANR por XML grande). |
| **flutter_image_compress ^2.3.0** | `Bitmap.compress(JPEG)` | `UIImage.jpegData` | ❌ `expect/actual` | **low / low** — va con el watermark nativo. |
| **image_picker ^1.1.2** | Photo Picker (`PickMultipleVisualMedia`, sin permiso) | PHPicker (sin permiso Photos) | ❌ lanzamiento nativo, resultado en common | **low / low** — Photo Picker/PHPicker eliminan el permiso de almacenamiento. |
| **permission_handler ^12.0.1** | `ActivityResultContracts.RequestPermission` | API de cada framework | ❌ `expect/actual` | **low / low** |
| **in_app_update ^4.2.5** | Play Core (`performImmediateUpdate`) | — **(no existe equivalente)** — | ❌ `expect/actual` con no-op iOS | 🔴 **BLOCKER iOS / low Android** — actualización inmediata FORZADA, ya gateado `if(!Platform.isAndroid) return`. iOS gestiona updates vía App Store; el flujo desaparece. |
| **file_picker ^8.1.6** | Storage Access Framework (SAF) | `UIDocumentPickerViewController` | ❌ nativo | **low / low** — usado en Casos/Explorador. |
| **share_plus ^11.0.0** | `Intent.ACTION_SEND` | `UIActivityViewController` | ❌ nativo | **low / low** |
| **cached_network_image ^3.4.1** | Coil | Kingfisher/AsyncImage | ❌ nativo (la caché es de UI) | **low / low** |
| **url_launcher ^6.3.1** | `Intent.ACTION_VIEW` | `UIApplication.open` | ❌ nativo | **low / low** |
| **package_info_plus ^8.3.0** | `PackageManager` | `Bundle.main` | `expect/actual` | **low / low** |
| **timezone ^0.11.0** | `java.time` / kotlinx-datetime | Foundation | ✅ kotlinx-datetime en common | **low / low** |
| **path_provider ^2.1.5** | `Context.filesDir` | `NSDocumentDirectory` | `expect/actual` | **low / low** |
| **go_router ^16.0.0** | Navigation Compose | NavigationStack | ❌ por plataforma | **med / med** — replicar guard de 3 capas (privacidad→device→auth). |
| **flutter_riverpod ^2.6.1** | coroutines/Flow/StateFlow | (consume StateFlow) | ✅ commonMain (**REESCRITO**) | **n/a / high** — 6.284 LOC reescritos. |

---

## 4. Re-arquitectura offline-first (la parte crítica)

> **Veredicto del verificador sobre el diseño offline: NO sostiene tal cual** (confianza 0,78). Es direccionalmente correcto y superior al actual, pero **incompleto para Fase 1** por dos dependencias no resueltas. Aquí incorporamos las 6 correcciones obligatorias.

### Estado actual verificado (todo confirmado en código)

1. **Tres colas en SharedPreferences sin coordinación:** `queue_records` (queue_service), `offline_first_queue` (offline_first_queue), `pending_registros` (registro_vin_service). El pedeteo va al sistema viejo (sin procesador automático conectado); daños/fotos al nuevo.
2. **Bug `status=syncing` atascado:** `offline_first_queue` línea 338 escribe `syncing` y **persiste ANTES del try** (`_saveAllRecords`). El sync solo procesa `status==pending` (líneas 296-298, 313). Tras crash/kill, los records quedan en `syncing` para siempre.
3. **Cola en memoria muerta:** `http_service._pendingRequests` con `Completer` + timeout 5min. `processPendingRequests()` **nunca se llama** → editar/crear daños vía `requestWithConnectivity` que cae en error de red se encola en memoria y **se PIERDE al matar la app**.
4. **`_markAsCompleted` busca por VIN+status, no por id** → carrera con VIN duplicado offline (marca solo el primero).
5. **`background_queue_service` = `Timer` en isolate principal + `ProviderContainer` global** (verificado, NO WorkManager) → se pausa en background.
6. **Conectividad = solo interfaz:** `checkConnectivity()` (línea 285) → falsos online en WiFi cautivo de puerto, quema los 3 reintentos y marca `failed` datos válidos.
7. **Paths absolutos crudos:** `/storage/emulated/0/DCIM/StampCamera` (verificado línea 705) → rompe con scoped storage / cambio de UUID de contenedor iOS.

### Diseño objetivo (con las 6 correcciones del verificador)

**Una sola cola tipada en SQLDelight + SyncEngine con lease + WorkManager (Android) / URLSession-background (iOS).**

```sql
-- Esquema SQLDelight: cola unificada
CREATE TABLE sync_operation (
    id                TEXT NOT NULL PRIMARY KEY,   -- UUID
    operation_type    TEXT NOT NULL,               -- REGISTRO_VIN | FOTO_PRESENTACION | DANO | GENERIC_MUTATION
    http_method       TEXT NOT NULL,               -- POST | PATCH | ...
    endpoint          TEXT NOT NULL,
    payload_json      TEXT NOT NULL,               -- campos del form serializados
    file_paths_json   TEXT NOT NULL DEFAULT '[]',  -- paths RELATIVOS a filesDir/sync_pending
    idempotency_key   TEXT NOT NULL,               -- UUID generado en el cliente al encolar
    status            TEXT NOT NULL,               -- PENDING | SYNCING | COMPLETED | FAILED
    retry_count       INTEGER NOT NULL DEFAULT 0,
    lease_expires_at  INTEGER,                     -- epoch ms; null = sin lease
    created_at        INTEGER NOT NULL,
    last_error        TEXT
);
CREATE INDEX idx_status ON sync_operation(status);
```

**SyncEngine (commonMain):**
- Al arrancar: todo `SYNCING` con `lease_expires_at` vencido vuelve a `PENDING` (mata el bug del estado atascado).
- Toma de trabajo con **transacción IMMEDIATE** (`SELECT...UPDATE` atómico, no read-then-write) para no reintroducir doble-lease entre `CoroutineWorker` (su proceso) y el sync de foreground.
- Envía con header `Idempotency-Key`. En éxito → `COMPLETED`. En fallo de red → reachability probe antes de reintentar. En fallo 4xx no-idempotente → `FAILED`.

### Las 6 correcciones obligatorias (gates de Fase 1)

| # | Corrección | Por qué bloquea | Acción |
|---|---|---|---|
| **1** 🔴 | **Idempotencia en backend Django** | El SyncEngine es FIABLE reintentando. Un retry de un `POST /danos/` que ya tuvo éxito pero cuyo ACK se perdió **CREARÁ UN DAÑO DUPLICADO con fotos duplicadas**. Verificado: `DanosModel` y `RegistroVinImagenesModel` **NO tienen unique constraint** (solo `RegistroVinModel` tiene `unique_together=['vin','condicion']`). Hoy casi no pasa porque la cola en memoria pierde el request; con cola robusta, la mayor fiabilidad AUMENTA la tasa de duplicados. | **HACER el cambio backend PARTE de Fase 1**, no un "requiere": agregar `idempotency_key UNIQUE` (columna o tabla) en daños/fotos y honrar `Idempotency-Key` en los ViewSets ANTES de activar el SyncEngine. |
| **2** | **iOS background uploads** | `BGProcessingTask` NO garantiza ejecución (el SO decide; pueden pasar horas o nunca), wall-clock limitado, se cancela si el usuario mata la app. Para decenas/cientos de fotos por turno, las subidas quedarían pendientes indefinidamente. | Usar **URLSession background** (`discretionary=false`, multipart desde archivo en disco; `nsurlsessiond` sube fuera del proceso). BGTaskScheduler solo para reprogramar/limpiar, NO para la subida. Aceptable diferir a fase iOS SI Android es prioridad, pero **documentar "iOS background uploads = foreground-only en fase inicial"**, no como cubierto. |
| **3** 🔴 | **Reachability probe** | WorkManager `NetworkType.CONNECTED` y BGProcessing `requiresNetworkConnectivity` tienen EL MISMO defecto que `checkConnectivity()`: detectan interfaz, no alcanzabilidad. Es el **driver #2** de la migración (confiabilidad offline en WiFi cautivo portuario). | Añadir probe real (HEAD a `/health` timeout 3s, o tratar primer fallo como offline y reintentar) en el predicado de online. |
| **4** | **Mapeo operación-por-operación** | Hoy `createDanoWithFormData` (POST, DEBE ser offline) y `updateDano` (PATCH, online-only) usan el MISMO `requestWithConnectivity`. Sin mapeo explícito se pierde el offline de creación de daños. | Definir tabla: **creación** de registro/foto/daño → SÍ a `sync_operation`; **edits/PATCH** → online-only en fase inicial. |
| **5** | **Aislamiento del lease** | `OneTimeWork` + `PeriodicWork` de respaldo + sync de foreground pueden ejecutar `SyncEngine.syncOnce()` concurrentemente. El `CoroutineWorker` corre en su instancia y el foreground en otra. | Transacción **IMMEDIATE cross-process** (SQLite WAL lo permite). Especificar nivel de aislamiento; el default de SQLDelight deja ventana de doble-lease. |
| **6** | **Limpieza de `filesDir/sync_pending`** | Copiar fotos a `filesDir/sync_pending` + path relativo arregla el riesgo de paths absolutos, pero **duplica el archivo en disco** hasta confirmar sync. | Definir limpieza tras `COMPLETED` para no llenar disco. |

### Librerías y background

| Plataforma | Persistencia | Background sync | Conectividad |
|---|---|---|---|
| **commonMain** | SQLDelight | SyncEngine (coroutines) | `Flow<ConnectivityState>` + reachability |
| **Android** | SQLDelight Android driver | **WorkManager** (constraint red, drena con app cerrada) | `NetworkCallback` + `NET_CAPABILITY_VALIDATED` |
| **iOS** | SQLDelight Native driver | **URLSession background** (uploads) + BGTaskScheduler (reprog./limpieza) | `NWPathMonitor` + probe |

---

## 5. Ganancias de performance/batería/cámara + benchmarks baseline

### Por driver del usuario

| Driver | Problema actual (verificado) | Solución nativa | Ganancia esperada |
|---|---|---|---|
| **1. Performance / jank** | Platform-view de la cámara Flutter introduce jank de composición; watermark en `dart:ui` compite con el render UI en el mismo engine | CameraX `PreviewView` (Android) / `AVCaptureVideoPreviewLayer` (iOS) renderizan en su propia surface; watermark en hilo IO con `android.graphics`/CoreGraphics | Eliminación del jank de platform-view; preview fluido |
| **2. Confiabilidad offline** | `Timer` en isolate principal se pausa en background; `checkConnectivity()` da falsos online; cola en memoria pierde requests al matar app | WorkManager/URLSession-background drenan con app cerrada; reachability probe; SQLDelight transaccional | **Mejora REAL** — pero ajustar expectativa: WorkManager/BGTask tienen políticas de SO (Doze, presupuesto iOS); NO es ejecución garantizada inmediata |
| **3. Batería / cámara / APIs** | Plugin camera sin control fino de resolución/foco; geolocator bloquea en algunos devices | CameraX `CameraControl` (zoom/torch/foco); FusedLocation evita bloqueo | Control fino; menos drenaje en sesiones largas de inspección |

### Benchmarks baseline a CAPTURAR ANTES de migrar (sobre la app Flutter actual)

> Sin baseline no se puede demostrar la mejora. Capturar en device de campo real (gama media Android), no emulador.

1. **Cámara:** tiempo desde tap-capturar hasta thumbnail listo (incluye watermark+compress). Medir p50/p95 sobre 50 capturas.
2. **Jank:** % de frames > 16ms durante scroll de `RegistroScreen` (lista paginada) y durante preview de cámara. Usar DevTools timeline / `flutter run --profile`.
3. **Watermark:** ms de los 3 pasos (`image_processor` ya loggea: "Paso 3 - Watermark (Canvas): Xms", verificado). Capturar la salida JPEG byte-a-byte como **golden de referencia visual** (ver §10, riesgo de regresión).
4. **Cold start:** tiempo a primer frame interactivo.
5. **Batería:** drenaje en una sesión de pedeteo de 1h (N capturas + GPS + WS). Battery Historian.
6. **Offline:** tasa de sync exitoso de la cola tras reconexión en WiFi cautivo (medir cuántos `failed` falsos genera hoy).
7. **Tamaño de payload:** peso medio del JPEG subido (para validar que el resize >2560px funciona igual).

---

## 6. UX: estrategia pixel-perfect + mejoras nativas

### Design system

El proyecto ya está tokenizado (`config/`, design tokens). **Portar a un `Theme` de Compose Material3** (colores marino/naviero/turquesa/celeste/colonial/sabroso, tipografías) y a un theme de SwiftUI. Pixel-perfect significa: mismos colores, spacing, tipografías, jerarquía. Las animaciones (`AnimatedCrossFade`, `AnimatedRotation`) → `AnimatedVisibility`/`animateFloatAsState` (Compose) y transiciones SwiftUI.

### Mejoras nativas por módulo (oportunidades, no obligatorias en el corte pixel-perfect)

| Módulo | Mejora nativa |
|---|---|
| **RegistroScreen (filtros)** | FilterChip con Badge de conteo por categoría (hoy no muestra cuántos hay por filtro). Backend debería devolver aggregates. |
| **DetalleRegistroScreen (tabs)** | `BadgedBox` (Material3) para badges de conteo — hoy usa `Stack`+`Positioned(-8)` que se clipea en pantallas pequeñas. FAB → `ExtendedFAB` con texto que cambia por tab ("Agregar Daño"/"Agregar Foto") en vez de "+" ambiguo. |
| **DanoForm (1500 LOC)** | Dividir en **stepper de 3 pasos** (clasificación → detalles opcionales → fotos). Reduce errores de tap con guantes y pérdida de progreso. |
| **PedeteoScreen** | `LinearProgressIndicator` proporcional (hoy solo dos números). |
| **ResumenRegistros (acordeón 3 niveles)** | Reducir a 2 niveles directos (Día → VINs) con participante como filtro en AppBar. |
| **NaveSearchSheet** | Texto "Mostrando 15 más recientes, escribe para buscar" + **debounce** (hoy dispara GET por keystroke sin cancelar). |
| **Selector multi-zona (daños)** | `InputChip` inline dentro del campo (hoy doble representación confusa: texto + Wrap de chips externos). |

---

## 7. Catálogo de bugs a NO arrastrar

> Del audit, los marcados `doNotCarryOver: true` **NO se deben replicar en la migración**. Además, la migración es la oportunidad de cerrar varios bugs estructurales que el verificador confirmó.

### Explícitamente "no arrastrar" (doNotCarryOver: true)

| Bug | Acción en KMP |
|---|---|
| **debugPrint excesivos con datos sensibles** (`registro_detalle_provider`, decenas de prints con IDs, params de forms, paths) | Usar logging estructurado con niveles; nunca loggear payloads/paths en release. |

### Bugs estructurales a cerrar en la migración (verificados)

| Bug | Fix en KMP |
|---|---|
| **3 colas offline desconectadas** | Cola única SQLDelight (§4). |
| **`status=syncing` atascado tras crash** | Lease que revierte a PENDING al arrancar. |
| **`processPendingRequests()` nunca llamada (cola en memoria muerta)** | Eliminada; reemplazada por SQLDelight `GENERIC_MUTATION`. |
| **`_markAsCompleted` por VIN (carrera con duplicado)** | Buscar por `id` de operación. |
| **Backoff lineal del WS** | Exponencial + jitter. |
| **`checkConnectivity()` solo interfaz** | `NET_CAPABILITY_VALIDATED` / reachability probe. |
| **Swap `viajesMuelle`/`viajesBalanza` en DashboardKpis** (verificado: leen claves JSON cruzadas) | Corregir al portar el modelo. |
| **FieldPermission x4 / InformacionUnidad x2 (duplicados)** | Un único DTO en commonMain. |
| **Password biométrica no ligada a CryptoObject** | BiometricPrompt + CryptoObject. |
| **Asistencia 100% online (sin cola offline)** | Agregar offline-first (marcar entrada/salida). |
| **Graneles sin offline-first** | Agregar al portar. |
| **ViajeForm pierde borrador** | Borrador persistido en SQLDelight. |
| **Paths absolutos a DCIM** | Paths relativos a `filesDir/sync_pending`. |

### Bugs de UI a NO replicar (corregir al reescribir)

- `DanoForm._buildCameraCards`: `setState` durante build (mover init a estado inicial del ViewModel).
- `_applyInitialValues` con `addPostFrameCallback` → flash visible (resolver con estado inicial correcto).
- `DetalleRegistroScreen` FAB: `while(result=='create_another')` cierra todo el detalle al cancelar (rediseñar con Navigation results).
- `NaveSearchSheet` sin debounce (agregar debounce en el UseCase).
- `updateDano` parámetro sin tipo estático (Kotlin lo fuerza).

---

## 8. Plan por fases (Android primero → iOS)

> **Honestidad sobre esfuerzo (corrección del verificador de phasing, que rechazó el plan inicial):** el plan original cubría solo ~55-60% del LOC operativo (faltaban Graneles ~15k LOC y Casos ~3,7k LOC como fases). Aquí están completas. **Total Android feature-complete: ~10-15 meses. Con iOS: ~16-22 meses** para 1 dev / equipo pequeño. Los rangos llevan buffer +30-50% en fases con foco de regresión.

> **Sobre "strangler" (corrección crítica):** un strangler *module-by-module en un solo binario* entre Flutter y KMP es **técnicamente imposible** — son runtimes distintos (Dart/Skia vs JVM/ART) y un release de Play es atómico por binario. El "strangler" es solo **estrategia de SECUENCIACIÓN DE DESARROLLO interna**, NO de coexistencia en dispositivo. Ver §9.

> **Nota de numeración:** la Fase 4 (Autos: Inventario + Contenedores) quedó integrada dentro de la Fase 3; por eso la secuencia salta de 3 a 5.

| Fase | Alcance | Dependencias | Entregables | Rango |
|---|---|---|---|---|
| **0 — Cimientos KMP + backend idempotencia** | Módulo `shared` (commonMain+androidMain). Port Ktor de `http_service` (refresh Mutex, X-Device-ID, retry 401, multipart). Port Ktor WS (`ws/app/`, heartbeat, backoff exp+jitter). Esquema SQLDelight cola unificada. 16 models → `@Serializable`, consolidar duplicados, corregir swap KPIs. **Backend Django: `idempotency_key UNIQUE` en daños/fotos + honrar header.** | — | Shared module compila; contrato verificado contra Django; backend idempotente | 4-6 sem |
| **1 — Auth + shell Android** | `expect/actual` secure storage (Keystore) y connectivity (NetworkCallback + reachability). Compose: Splash, Login (BiometricPrompt+CryptoObject), DeviceRegistration, Home (grid por permisos), indicador WS. Navigation guard 3 capas. | F0 | APK navegable con login/permisos/WS | 4-6 sem |
| **2 — Asistencia + Cámara nativa** | RegistroAsistencia + GPS (FusedLocation). **Pipeline imagen nativo: CameraX + `android.graphics.Canvas`** (watermark logo+timestamp+GPS, calibrado pixel a pixel vs golden). `MediaScannerConnection`. **Agregar offline a asistencia.** | F1 | Cámara nativa con paridad visual de watermark | 6-9 sem |
| **3 — Autos (el grueso)** | registro/detalle/daños/pedeteo/inventario/contenedores. DanoForm → stepper. Scanner VIN (ML Kit). Rediseñar flujo encadenado RegistroVin→FotoPresentacion con Navigation results. Cola unificada sostiene crear registro/foto/daño. **(Foco de regresión: `dano_form` 1500 LOC + `registro_detalle_provider` 1119 LOC).** | F2 | Módulo Autos completo offline-first | **10-16 sem** (incl. buffer) |
| **5 — Graneles** | Dashboard (2007 LOC), ViajeForm wizard 3 pasos con **borrador persistido**, tabla jornadas (LazyColumn+LazyRow sticky, scroll sincronizado), silos/balanzas/temperatura/humedad/paralizaciones, tickets. `_parseDouble` String\|Double. **Agregar offline a graneles.** | F3 | Módulo Graneles completo | **10-14 sem** (incl. buffer) |
| **6 — Casos / Explorador** | Explorador de archivos WS-driven (1175 LOC) + provider (899 LOC), multi-camera, presencia WS, SAF para file picker, subir/mover. | F3 | Módulo Casos completo | 4-6 sem |
| **7 — Cutover Android (GATE)** | **Drenaje/migración OBLIGATORIA de las 3 colas Flutter pendientes en campo.** Re-login forzado. WorkManager hardening. Play Core in-app update. Staged rollout + plan de rollback. | F5, F6 | App Android en producción | 3-4 sem |
| **8 — iOS completa** | iosMain en shared (framework vía SPM/cocoapods). UI SwiftUI pixel-perfect de TODOS los módulos. `expect/actual`: Keychain, NWPathMonitor, NSDocumentDirectory. Cámara: AVFoundation + **CoreGraphics watermark** (paridad con Android). Vision (scanner VIN). LAContext (FaceID). URLSession-background sync. `in_app_update` → no-op. **Declarar NSCamera/NSLocation/NSPhotoLibrary UsageDescription + `PrivacyInfo.xcprivacy`** (hoy solo está NSFaceID, verificado; faltan → rechazo en App Store). Portrait salvo cámara. | F7 estable | App iOS en producción | **16-28 sem** |

**Notas de Fase 0/test:** construir suite de caracterización + golden del watermark es **frágil** porque el watermark depende de GPS/timestamp/geocoding en runtime → **no determinista**. Hay que **inyectar/mockear esos servicios primero** (trabajo previo, no subestimar). Sin tests previos, el riesgo de regresión se concentra en F3/F5.

---

## 9. Rollout y coexistencia con Flutter en producción

> **Corrección central del verificador:** NO existe strangler real a nivel de release entre Flutter y KMP. Hay que elegir explícitamente UNA de dos estrategias. **Esta es la Decisión D2 para el usuario (§10).**

### Opción A — App paralela (segundo applicationId)

- `com.aygajustadores.stampcamera.kmp` como **listing separado** en Play.
- **Implica:** dos fichas en Play; NO actualiza automáticamente a usuarios existentes; migración manual de instalaciones; **export/import de la cola offline** Flutter→KMP antes de desinstalar la vieja.
- **Pro:** se puede liberar a un grupo piloto (inspectores de un turno) sin tocar la app de producción.
- **Contra:** dos apps conviviendo en el device confunden; gestión de qué app es "la oficial".

### Opción B — Big-bang de binario (mismo applicationId)

- Reusar `com.aygajustadores.stampcamera`. Cada release de Play **reemplaza la app entera**.
- **Implica:** la app KMP debe estar **feature-complete** (todos los módulos) ANTES del swap. NO hay "mitad Flutter, mitad KMP" en el mismo device.
- **Pro:** sin confusión de dos apps; staged rollout de Play (5%→20%→100%) con rollback.
- **Contra:** no hay piloto modular; el corte es total.

### Gate de cutover OBLIGATORIO (ambas opciones)

**La migración de la cola offline pendiente es un GATE BLOQUEANTE, no un detalle.** Inspecciones/daños/fotos no sincronizadas viven en `queue_records` + `offline_first_queue` + `pending_registros`. Para una operación portuaria con **prueba documental legal**, perder una cola pendiente es un incidente de datos grave. Plan:

1. Antes del swap: **periodo de drenaje obligatorio** — forzar sync de las 3 colas Flutter en todos los devices (notificación + check al abrir).
2. Si Opción A: paso de export/import de la cola al instalar la KMP.
3. Comunicar el **re-login forzado** (secure storage Flutter ilegible) con ventana planeada. El workflow single-user / por turnos lo facilita.
4. Plan de rollback: mantener el APK Flutter disponible hasta confirmar estabilidad de la KMP en producción.

### Mantenimiento del contrato durante la transición

Mientras conviven Flutter (producción) y KMP (desarrollo), **cualquier cambio de serializer en Django debe reflejarse en commonMain Y en Flutter** → doble mantenimiento temporal del contrato hasta el corte definitivo. Minimizar cambios de API durante la ventana de migración.

---

## 10. Registro de riesgos y decisiones abiertas

### Riesgos

| Riesgo | Likelihood | Impacto | Mitigación |
|---|---|---|---|
| **Duplicación de daños/fotos al activar el SyncEngine sin idempotencia backend** | Alta | **Crítico** (integridad de datos legal) | Idempotency-Key en backend es GATE de Fase 0/1 (§4.1). No activar SyncEngine antes. |
| **Pérdida de cola offline en el cutover** | Media | **Crítico** (prueba legal) | Drenaje obligatorio + export/import como gate bloqueante (§9). |
| **Regresión visual del watermark** (dart:ui → android.graphics/CoreGraphics: antialiasing, 9 posiciones, GPS overlay, sombras) | Alta | Alto (fotos de evidencia cambian de aspecto) | Capturar golden byte-a-byte ANTES de migrar; calibrar pixel a pixel; mockear GPS/timestamp para determinismo. |
| **Madurez KMP en iOS / interop Kotlin→Swift** (Flow→async/await vía SKIE) | Media | Alto (cuello de botella) | Equipo debe dominar coroutines/Flow ANTES de Fase 0. Evaluar SKIE para suspend/Flow. |
| **iOS background uploads no garantizados** | Alta | Medio (degrada a foreground-only) | URLSession-background; documentar honestamente la limitación. |
| **Subestimar la UI (~70% LOC, reescrita 2 veces)** | Alta | Alto (rompe roadmap) | Buffer +30-50% en F3/F5; tabla jornadas y forms gigantes (DanoForm 1500, ViajeForm 1942) son los más caros. |
| **WiFi cautivo portuario quema reintentos** | Media | Medio (driver #2) | Reachability probe (§4.3). |
| **Rechazo App Store por falta de Privacy Manifest / usage descriptions** | Alta (si no se actúa) | Alto (bloquea release iOS) | Gate explícito en Fase 8 (verificado: falta todo salvo NSFaceID). |
| **Doble mantenimiento del contrato Django durante transición** | Media | Medio | Congelar cambios de API en la ventana; tests de contrato. |

### Decisiones abiertas para el usuario

- **D1 (la más importante):** **¿iOS es un compromiso firme del roadmap, o aspiracional?**
  - Firme → **KMP ahora** (confianza 0,72).
  - Aspiracional → **Kotlin + Compose nativo Android puro** (más simple, sin impuesto KMP), con módulos Kotlin limpios promovibles a commonMain cuando iOS se financie. **Recomiendo confirmar esto ANTES de fijar la complejidad `expect/actual` desde el día 1.**
- **D2:** Estrategia de cutover Android — **Opción A (app paralela, piloto modular)** vs **Opción B (big-bang feature-complete)** (§9). Recomendación: A si quieres piloto con un turno; B si prefieres corte limpio.
- **D3:** ¿Se prioriza cerrar la deuda offline (3 colas → SQLDelight) en una **rama Flutter previa** como mitigación de bajo costo mientras se construye KMP, o se difiere todo al port? (Reduce riesgo de pérdida de datos durante la ventana de transición.)
- **D4:** ¿El backend de idempotencia (D1 de §4) se aborda como trabajo Django independiente y previo, dado que beneficia incluso a la app Flutter actual?

---

**Confianza global del plan: ~0,80** (D1 resuelta: iOS firme → KMP definitivo). Toda afirmación load-bearing fue verificada contra el código real: `ws/app/` (no presencia), `force_logout` emitido una vez, backoff lineal, 3 colas SharedPreferences, `processPendingRequests` muerta, `status=syncing` atascado, `dart:ui` Canvas no portable, `Timer` en isolate (no WorkManager), swap KPIs, FieldPermission x4, Info.plist solo NSFaceID, in_app_update en uso, 65.317 LOC / 41 screens / 39 widgets / 19 providers Riverpod.