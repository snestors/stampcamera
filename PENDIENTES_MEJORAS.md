# 📋 PENDIENTES Y CONTEXTO - MEJORAS STAMPCAMERA

> **Fecha de sesión:** 2026-01-14
> **Estado:** Cambios implementados en Flutter, pendiente testing y cambios en backend

---

## 🎯 RESUMEN EJECUTIVO

Se implementó un plan de mejoras en 4 fases para la aplicación Stampcamera:

| Fase | Descripción | Estado |
|------|-------------|--------|
| **Fase 1** | Corregir Watermarking (stamps feos/grandes) | ✅ Completado |
| **Fase 2** | Estandarizar UX (componentes comunes) | ✅ Completado |
| **Fase 3** | Sistema de roles y módulos por usuario | ✅ Completado (Flutter) |
| **Fase 4** | Estructura base módulo Granos | ✅ Completado |

**⚠️ PENDIENTE:** Testing de todos los cambios y modificaciones en backend Django.

---

## 📁 ARCHIVOS CREADOS EN ESTA SESIÓN

### Nuevos Componentes de UI
```
lib/core/widgets/feedback/
├── app_dialog.dart          # Diálogos estandarizados (confirm, success, error, warning, info, loading)
└── app_snackbar.dart        # SnackBars estandarizados (success, error, warning, info)

lib/core/widgets/app_bars/
└── app_corporate_bar.dart   # AppBar corporativo con variantes (normal, dark, light, transparent)
```

### Módulo Granos (Placeholder)
```
lib/features/granos/
├── granos.dart                      # Exportaciones del módulo
├── screens/
│   └── granos_screen.dart           # Pantalla placeholder "En desarrollo"
└── providers/
    └── granos_provider.dart         # Provider base vacío
```

---

## 📝 ARCHIVOS MODIFICADOS EN ESTA SESIÓN

### 1. `lib/utils/image_processor.dart`

**Cambios realizados:**

#### A) Nuevo enum FontSize con opción `auto`:
```dart
enum FontSize {
  auto,   // NUEVO - Calcula automáticamente según resolución
  small,  // arial14
  medium, // arial24
  large,  // arial48
}
```

#### B) Nuevos métodos en FontHelper:
```dart
// Calcula tamaño óptimo según resolución
static FontSize calculateOptimalSize(int imageWidth, int imageHeight) {
  final maxDimension = imageWidth > imageHeight ? imageWidth : imageHeight;
  if (maxDimension < 1920) return FontSize.small;
  return FontSize.medium; // NUNCA large para imágenes grandes
}

// Calcula ratio del logo según resolución
static double calculateLogoRatio(int imageWidth) {
  if (imageWidth < 1920) return 0.20;      // 20% para imágenes pequeñas
  else if (imageWidth < 3840) return 0.15; // 15% para Full HD/2K
  else return 0.12;                         // 12% para 4K+
}
```

#### C) WatermarkConfig con valores auto por defecto:
```dart
const WatermarkConfig({
  this.logoSizeRatio = 0.0,              // 0.0 = auto-calculate
  this.timestampFontSize = FontSize.auto, // Auto según resolución
  this.locationFontSize = FontSize.auto,  // Auto según resolución
  // ... resto igual
});
```

#### D) LocationService mejorado:
```dart
// Timeout reducido
static const Duration _gpsTimeout = Duration(seconds: 10); // Antes: 60s

// Cache de ubicación
static String? _cachedLocation;
static DateTime? _cacheTimestamp;
static const Duration _cacheValidDuration = Duration(minutes: 5);

// Nuevos métodos:
static Future<void> preloadLocation() async { ... }  // Precargar al abrir cámara
static void clearCache() { ... }                      // Limpiar cache
static String? getCachedLocation() => _cachedLocation; // Obtener cache
```

#### E) Nueva función _resolveAutoSizes():
```dart
// Resuelve valores "auto" a valores concretos basados en la resolución
WatermarkConfig _resolveAutoSizes(WatermarkConfig config, int width, int height) {
  // Calcula FontSize si está en auto
  // Calcula logoRatio si es 0.0
  // Retorna config con valores resueltos
}
```

---

### 2. `lib/models/user_model.dart`

**Cambios realizados:**

#### A) Nueva clase ModuleAccess:
```dart
class ModuleAccess {
  final String id;        // 'camera', 'asistencia', 'autos', 'granos'
  final String name;      // Nombre visible
  final String icon;      // Nombre del icono
  final bool isEnabled;   // Si está habilitado

  factory ModuleAccess.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### B) Nuevos campos en UserModel:
```dart
final List<ModuleAccess>? _availableModules; // Desde el backend (opcional)
```

#### C) Nuevos getters de acceso:
```dart
bool get hasAutosAccess =>
    isSuperuser ||
    groups.any((g) => ['AUTOS', 'PUERTO', 'ALMACEN', 'OFICINA', 'COORDINACION AUTOS'].contains(g));

bool get hasGranosAccess =>
    isSuperuser || groups.contains('GRANOS');

bool get hasAsistenciaAccess =>
    isSuperuser || !isCliente;
```

#### D) Getter availableModules con fallback:
```dart
List<ModuleAccess> get availableModules {
  // Si el backend envió módulos, usarlos
  if (_availableModules != null && _availableModules.isNotEmpty) {
    return _availableModules;
  }
  // Si no, calcular basándose en grupos
  return _calculateModulesFromGroups();
}
```

#### E) Método _calculateModulesFromGroups():
```dart
// Calcula módulos disponibles según grupos del usuario:
// - camera: todos los usuarios autenticados
// - asistencia: todos excepto CLIENTE
// - autos: AUTOS, PUERTO, ALMACEN, OFICINA, superuser
// - granos: GRANOS, superuser
```

---

### 3. `lib/screens/home_screen.dart`

**Cambios realizados:**

#### A) Método _buildApplicationsGrid() refactorizado:
- Ahora usa `authState.when()` para manejar estados
- Si hay usuario autenticado, llama a `_buildModulesGrid()`
- Si no, usa `_buildDefaultGrid()` como fallback

#### B) Nuevo método _buildModulesGrid():
```dart
Widget _buildModulesGrid(BuildContext context, dynamic user) {
  final modules = user.availableModules;
  final cards = <Widget>[];

  for (final module in modules) {
    cards.add(_buildModuleCard(context, module));
  }

  // Agregar "Próximamente" si hay espacio
  if (cards.length % 2 != 0 || cards.length < 4) {
    cards.add(_AppCard(title: 'Próximamente', ...));
  }

  return GridView.count(..., children: cards);
}
```

#### C) Nuevo método _buildModuleCard():
```dart
Widget _buildModuleCard(BuildContext context, dynamic module) {
  final moduleConfig = _getModuleConfig(module.id);
  return _AppCard(
    title: module.name,
    subtitle: moduleConfig.subtitle,
    icon: moduleConfig.icon,
    color: moduleConfig.color,
    onTap: () => _navigateToModule(context, module.id),
    isDisabled: !module.isEnabled,
  );
}
```

#### D) Nuevo método _getModuleConfig():
```dart
// Retorna configuración visual para cada módulo:
// - camera: Icons.camera_alt, AppColors.primary, 'Captura y gestiona fotos'
// - asistencia: Icons.access_time, AppColors.secondary, 'Registro de entrada y salida'
// - autos: Icons.directions_car, AppColors.accent, 'Gestión de vehículos'
// - granos: Icons.agriculture, AppColors.warning, 'Gestión de granos'
```

#### E) Nuevo método _navigateToModule():
```dart
void _navigateToModule(BuildContext context, String moduleId) {
  switch (moduleId) {
    case 'camera': context.push('/camera', ...); break;
    case 'asistencia': context.pushNamed('asistencia'); break;
    case 'autos': context.push('/autos'); break;
    case 'granos': _showComingSoonDialog(context); break; // Placeholder
  }
}
```

#### F) SnackBars migrados a AppSnackBar:
```dart
// ANTES:
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Container(...), backgroundColor: Colors.green[600], ...
));

// DESPUÉS:
AppSnackBar.success(context, 'Mensaje');
AppSnackBar.warning(context, 'Mensaje');
AppSnackBar.error(context, 'Mensaje');
```

#### G) Diálogo "Próximamente" migrado a AppDialog:
```dart
// ANTES:
showDialog(context: context, builder: (context) => AlertDialog(...));

// DESPUÉS:
AppDialog.info(context, title: 'Próximamente', message: '...');
```

#### H) Nueva clase _ModuleConfig:
```dart
class _ModuleConfig {
  final IconData icon;
  final Color color;
  final String subtitle;
}
```

---

### 4. `lib/core/core.dart`

**Nuevas exportaciones añadidas:**
```dart
// Feedback widgets (diálogos, snackbars)
export 'widgets/feedback/app_dialog.dart';
export 'widgets/feedback/app_snackbar.dart';

// App Bars
export 'widgets/app_bars/app_corporate_bar.dart';
```

---

## 🔧 PENDIENTE: CAMBIOS EN BACKEND DJANGO

> **Ubicación:** `/mnt/c/Users/Nestor/Desktop/Escritorio 2/django/core`

### 1. Crear grupo GRANOS en Django Admin
```
URL: http://localhost:8000/admin/auth/group/
Acción: Crear nuevo grupo con nombre "GRANOS"
```

### 2. Modificar UserSerializer para incluir available_modules

**Archivo:** `apis/serializers.py`

```python
class UserSerializer(serializers.ModelSerializer):
    available_modules = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'ultima_asistencia_activa', 'groups', 'is_superuser',
            'available_modules',  # NUEVO
        )

    def get_available_modules(self, user):
        """Retorna módulos disponibles según grupos del usuario"""
        groups = set(user.groups.values_list('name', flat=True))

        modules = []

        # Cámara - todos los usuarios autenticados
        modules.append({'id': 'camera', 'name': 'Cámara', 'icon': 'camera_alt'})

        # Asistencia - todos excepto CLIENTE
        if 'CLIENTE' not in groups:
            modules.append({'id': 'asistencia', 'name': 'Asistencia', 'icon': 'access_time'})

        # Autos - AUTOS, PUERTO, ALMACEN, OFICINA, superuser
        autos_groups = {'AUTOS', 'PUERTO', 'ALMACEN', 'OFICINA', 'COORDINACION AUTOS'}
        if groups & autos_groups or user.is_superuser:
            modules.append({'id': 'autos', 'name': 'Autos', 'icon': 'directions_car'})

        # Granos - GRANOS, superuser (descomentar cuando esté listo)
        # if 'GRANOS' in groups or user.is_superuser:
        #     modules.append({'id': 'granos', 'name': 'Granos', 'icon': 'agriculture'})

        return modules
```

---

## ✅ TESTING PENDIENTE

### Tests manuales requeridos:

#### Fase 1 - Watermarking
- [ ] Tomar foto en resolución 4K → Verificar texto legible pero no gigante
- [ ] Tomar foto en resolución 720p → Verificar texto proporcional
- [ ] GPS debe obtener ubicación en < 10 segundos o continuar sin ella
- [ ] Verificar que timestamp y location no se superponen
- [ ] Verificar compresión consistente en todas las fotos

#### Fase 2 - Componentes UX
- [ ] AppDialog.confirm() muestra diálogo con 2 botones
- [ ] AppDialog.success/error/warning/info() muestran iconos correctos
- [ ] AppSnackBar.success/error/warning/info() muestran colores correctos
- [ ] AppCorporateBar se ve consistente en todas las pantallas

#### Fase 3 - Roles y Módulos
- [ ] Usuario con grupo CLIENTE solo ve módulo Cámara
- [ ] Usuario con grupo AUTOS ve Cámara, Asistencia, Autos
- [ ] Usuario superuser ve todos los módulos
- [ ] El grid de módulos se adapta al número de módulos disponibles

#### Fase 4 - Módulo Granos
- [ ] La pantalla placeholder se muestra correctamente
- [ ] El botón "Volver al inicio" funciona
- [ ] El diálogo de información se muestra

---

## 🐛 PROBLEMAS CONOCIDOS / POSIBLES ISSUES

### 1. Flutter no está en PATH
El usuario no tiene Flutter configurado en el PATH de Windows. Debe:
- Instalar Flutter y agregarlo al PATH, O
- Abrir el proyecto desde Android Studio/VS Code con Flutter plugin

### 2. Compilación no verificada
No se pudo ejecutar `flutter analyze` para verificar que no hay errores de compilación. Posibles issues:
- Imports faltantes
- Tipos incorrectos
- Errores de sintaxis

### 3. Backend no modificado
El backend Django NO fue modificado. Actualmente:
- El Flutter calcula `availableModules` basándose en grupos
- Cuando se modifique el backend, enviará `available_modules` en el JSON
- El Flutter usará los módulos del backend si vienen, si no calcula localmente

---

## 📚 DOCUMENTACIÓN DE COMPONENTES CREADOS

### AppDialog - Uso

```dart
// Confirmación (retorna bool?)
final confirmed = await AppDialog.confirm(
  context,
  title: 'Cerrar Sesión',
  message: '¿Estás seguro?',
  confirmText: 'Sí, cerrar',
  cancelText: 'Cancelar',
  isDanger: true, // Botón rojo
);

// Éxito
await AppDialog.success(context, title: 'Éxito', message: 'Operación completada');

// Error
await AppDialog.error(context, title: 'Error', message: 'Algo salió mal');

// Warning
await AppDialog.warning(context, title: 'Advertencia', message: 'Cuidado con...');

// Info
await AppDialog.info(context, title: 'Información', message: 'Sabías que...');

// Loading (sin botón de cerrar)
AppDialog.loading(context, message: 'Procesando...');
AppDialog.closeLoading(context); // Para cerrarlo

// Custom con widget
await AppDialog.custom<String>(
  context,
  title: 'Personalizado',
  content: MyCustomWidget(),
  actions: [MyButton(), MyButton()],
);
```

### AppSnackBar - Uso

```dart
AppSnackBar.success(context, 'Operación exitosa');
AppSnackBar.error(context, 'Ocurrió un error');
AppSnackBar.warning(context, 'Advertencia importante');
AppSnackBar.info(context, 'Información útil');

// Con acción
AppSnackBar.success(
  context,
  'Elemento eliminado',
  action: SnackBarAction(label: 'Deshacer', onPressed: () => ...),
);

// Custom
AppSnackBar.custom(
  context,
  message: 'Mensaje personalizado',
  icon: Icons.star,
  backgroundColor: Colors.purple,
);

// Ocultar/limpiar
AppSnackBar.hide(context);
AppSnackBar.clearAll(context);
```

### AppCorporateBar - Uso

```dart
// Normal (azul corporativo)
AppCorporateBar(
  title: 'Mi Pantalla',
  actions: [IconButton(...)],
)

// Oscuro (para cámara/galería)
AppCorporateBar.dark(
  title: 'Cámara',
  actions: [...],
)

// Claro (para formularios)
AppCorporateBar.light(
  title: 'Editar',
  actions: [...],
)

// Transparente (sobre imágenes)
AppCorporateBar.transparent(
  title: 'Vista previa',
)

// Con TabBar
AppCorporateBar(
  title: 'Tabs',
  bottom: TabBar(tabs: [...]),
)
```

---

## 🚀 COMANDOS PARA CONTINUAR

```powershell
# 1. Navegar al proyecto
cd C:\Users\Nestor\Desktop\Flutter\stampcamera

# 2. Obtener dependencias
flutter pub get

# 3. Analizar código (buscar errores)
flutter analyze

# 4. Ejecutar en dispositivo/emulador
flutter run

# 5. Build APK de prueba
flutter build apk --debug
```

---

## 📞 PRÓXIMA SESIÓN - CHECKLIST

1. [ ] Verificar que Flutter esté instalado y en PATH
2. [ ] Ejecutar `flutter pub get`
3. [ ] Ejecutar `flutter analyze` y corregir errores si hay
4. [ ] Probar cada fase manualmente
5. [ ] Implementar cambios en backend Django (si se requiere)
6. [ ] Agregar ruta `/granos` en `app_router.dart` cuando el módulo esté listo

---

## 🔗 ARCHIVOS RELACIONADOS

| Archivo | Propósito |
|---------|-----------|
| `CLAUDE.md` | Documentación general del proyecto |
| `PENDIENTES_MEJORAS.md` | Este archivo - contexto de mejoras |
| `/home/nestor/.claude/plans/gentle-hatching-garden.md` | Plan original aprobado |

---

*Generado automáticamente por Claude Code - 2026-01-14*
