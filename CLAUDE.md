# Contexto del Proyecto - Migración Design System

## Resumen del Proyecto
Aplicación Flutter para gestión de vehículos con cámara de sellos. Se está migrando de componentes hardcodeados a un design system centralizado.

## Estado Actual de la Migración

### ✅ Completados
- **detalle_registro_screen.dart** - Pantalla principal con TabBar migrada
- **detalle_info_general.dart** - Información general del vehículo migrada
- **detalle_registros_vin.dart** - Historial de registros VIN migrado
- **detalle_fotos_presentacion.dart** - Galería de fotos migrada
- **detalle_danos.dart** - Migración completa a design system ✅
- **Limpieza de duplicados** - Eliminado custom_colors.dart duplicado
- **AppCard component** - Componente central creado y funcionando
- **AppEmptyState** - Componente para estados vacíos
- **AppSectionHeader** - Headers de sección estandarizados

### 🔄 En Progreso
- Ninguna

### 📋 Pendientes
- Ninguna (migración del design system pausada)

## Arquitectura del Design System

### Estructura de Archivos
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart       # Colores centralizados
│   │   ├── design_tokens.dart    # Tokens de diseño
│   │   └── app_theme.dart        # Tema principal
│   └── widgets/
│       └── common/
│           ├── app_card.dart         # Componente Card principal
│           ├── app_empty_state.dart  # Estados vacíos
│           ├── app_section_header.dart # Headers de sección
│           ├── app_search_select.dart  # ✅ Select con búsqueda
│           └── app_button.dart       # Botones estandarizados
└── widgets/
    └── autos/
        ├── detalle_registro_screen.dart      # ✅ Migrado
        ├── detalle_info_general.dart         # ✅ Migrado
        ├── detalle_registros_vin.dart        # ✅ Migrado
        ├── detalle_fotos_presentacion.dart   # ✅ Migrado
        ├── detalle_danos.dart                # ✅ Migrado
        └── forms/
            └── dano_form.dart                # ✅ AppSearchSelect implementado
```

### Componentes Principales

#### AppCard
```dart
// Tipos disponibles
AppCard.basic()     // Card básico sin elevación
AppCard.elevated()  // Card con sombra
AppCard.outlined()  // Card con borde
AppCard.filled()    // Card con fondo coloreado

// Ejemplo de uso
AppCard.elevated(
  child: Column(...),
)
```

#### DesignTokens
```dart
// Espaciado
DesignTokens.spaceXS   // 4px
DesignTokens.spaceS    // 8px
DesignTokens.spaceM    // 16px
DesignTokens.spaceL    // 24px
DesignTokens.spaceXL   // 32px

// Tipografía
DesignTokens.fontSizeXS     // 10px
DesignTokens.fontSizeS      // 12px
DesignTokens.fontSizeM      // 14px
DesignTokens.fontSizeL      // 16px

// Bordes
DesignTokens.radiusS    // 4px
DesignTokens.radiusM    // 8px
DesignTokens.radiusL    // 12px
```

#### AppColors
```dart
AppColors.primary      // Azul principal
AppColors.secondary    // Verde secundario
AppColors.accent       // Púrpura accent
AppColors.success      // Verde éxito
AppColors.warning      // Naranja advertencia
AppColors.error        // Rojo error
AppColors.textPrimary  // Negro texto principal
AppColors.textSecondary // Gris texto secundario
AppColors.surface      // Fondo de campos
AppColors.neutral      // Bordes neutros
```

#### AppSearchSelect
```dart
// Select con búsqueda como en la web
AppSearchSelect<int>(
  label: 'Tipo de Daño',
  hint: 'Seleccionar tipo de daño...',
  value: _selectedValue,
  isRequired: true,
  prefixIcon: const Icon(Icons.search),
  options: items.map<AppSearchSelectOption<int>>((item) {
    return AppSearchSelectOption<int>(
      value: item['value'],
      label: item['label'],
      subtitle: item['subtitle'], // Opcional
      leading: Widget(),          // Opcional
    );
  }).toList(),
  onChanged: (value) => setState(() => _selectedValue = value),
  validator: (value) => value == null ? 'Requerido' : null,
)
```

## Problemas Resueltos

### 1. BorderRadius en AppCard.elevated
**Error**: `The named parameter 'borderRadius' isn't defined`
**Solución**: Removido parámetro inválido, AppCard maneja border radius internamente

### 2. Fuentes muy grandes
**Error**: Fuentes demasiado grandes en home_screen.dart
**Solución**: Ajustados tamaños de fuente usando tokens apropiados

### 3. Duplicación de temas
**Error**: Existían app_theme.dart y custom_colors.dart
**Solución**: Eliminado custom_colors.dart y consolidado en core/theme/

### 4. Componentes faltantes
**Error**: AppEmptyState, AppSectionHeader no compilaban
**Solución**: Creados y exportados en core/core.dart

## Patrones de Migración

### Antes (Hardcoded)
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF003B5C).withOpacity(0.03),
    ),
    child: ...
  ),
)
```

### Después (Design System)
```dart
AppCard.elevated(
  child: ...
)
```

## Comandos Útiles

### Flutter
```bash
flutter pub get          # Instalar dependencias
flutter run              # Ejecutar aplicación
flutter build apk        # Generar APK
flutter analyze          # Análisis de código
flutter test             # Ejecutar tests
```

### Git
```bash
git add .
git commit -m "Continue design system migration"
git push origin main
```

## Feedback del Usuario

### Positivo
- "Quedo perfecto" - Migración de home_screen
- "ok perfecto" - Ajuste de fuentes  
- "ok quedo bien" - Migración de detalle_registros_vin

### Negativo
- "están muy grandes las fuentes" - Resuelto ajustando DesignTokens
- "Ta quedando algo feo =(" - Comentario final sobre aspecto visual

## ✅ Funcionalidades Completadas (Sesión Actual)

### **🔍 Sistema AppSearchSelect con Búsqueda**
Implementado sistema completo de select con búsqueda como en la web:

#### **AppSearchSelect - Componente Principal:**
- **Input funcional** - Campo de texto real donde se puede escribir para buscar
- **Búsqueda en tiempo real** - Filtra opciones mientras escribes  
- **Overlay inteligente** - Se abre al hacer focus, se cierra al tocar afuera
- **Fuente pequeña** - `DesignTokens.fontSizeS` para UI compacta
- **Offset customizable** - Posicionado a 60px del input
- **Crash protection** - Verificaciones de `mounted` en todos los métodos

#### **Implementado en Formulario de Daños:**
- ✅ **Tipo de Daño** - Con búsqueda y icono de problema  
- ✅ **Área de Daño** - Con búsqueda y icono de ubicación

#### **Dropdowns Normales Estandarizados:**
Aplicado mismo estilo visual a todos los dropdowns restantes:
- ✅ **Condición** - Bordes redondeados, fuente pequeña, colores design system
- ✅ **Severidad** - Mantuvo círculos de colores + nuevo estilo
- ✅ **Responsabilidad** - Estilo consistente y fuente pequeña  
- ✅ **Documento de Referencia** - Mantuvo iconos complejos + nuevo estilo

#### **Características Técnicas:**
```dart
// AppSearchSelect
AppSearchSelect<int>(
  label: 'Tipo de Daño',
  hint: 'Seleccionar tipo de daño...',
  value: _selectedTipoDano,
  isRequired: true,
  prefixIcon: const Icon(Icons.report_problem),
  options: tiposDano.map<AppSearchSelectOption<int>>((tipo) {
    return AppSearchSelectOption<int>(
      value: tipo['value'],
      label: tipo['label'],
    );
  }).toList(),
  onChanged: (value) => setState(() => _selectedTipoDano = value),
)

// Dropdown Estandarizado  
DropdownButtonFormField<int>(
  style: TextStyle(
    fontSize: DesignTokens.fontSizeS,
    color: AppColors.textPrimary,
  ),
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
    ),
    fillColor: AppColors.surface,
    filled: true,
  ),
)
```

### **🧹 Sistema de Limpieza de Providers**
Implementado sistema completo de gestión de estado entre sesiones:

#### **SessionManager con 3 Niveles:**
1. **`clearSession(ref)`** - Logout completo
   - Limpia TODOS los providers relacionados con datos de usuario
   - Usado en: `auth_provider.logout()`

2. **`onStartAssistance(ref)`** - Inicio de turno
   - Limpia datos del día anterior manteniendo configuraciones
   - Usado en: `asistencias_provider.marcarEntrada()`

3. **`onEndAssistance(ref)`** - Fin de turno  
   - Limpia datos de trabajo, mantiene configuraciones
   - Usado en: `asistencias_provider.marcarSalida()`

#### **Providers Limpiados:**
- ✅ Asistencia: `asistenciasDiariasProvider`, `asistenciaFormOptionsProvider`, `asistenciaStatusProvider`
- ✅ Registro General: `registroGeneralProvider`, `registroVinOptionsProvider`
- ✅ Pedeteo: `pedeteoOptionsProvider`, `pedeteoStateProvider`
- ✅ Registro Detalle: `detalleRegistroProvider`, `fotosOptionsProvider`, `danosOptionsProvider`
- ✅ Inventario: `inventarioBaseProvider`, `inventarioDetalleProvider`, `inventarioImageProvider`, `inventarioFormProvider`, `inventarioStatsProvider`
- ✅ Contenedores: `contenedorProvider`, `contenedorDetalleProvider`, `contenedorOptionsProvider`
- ❌ Excluidos: `queueStateProvider` (mantiene estado persistente), `themeProvider`, `connectivityProvider`

### **🐛 Corrección de Warnings y Errores**
Eliminados TODOS los warnings y errores de compilación:

#### **Warnings Iniciales (9 tipos):**
- ✅ `use_build_context_synchronously` - imagenes_tab_widget.dart
- ✅ `unused_result` - inventario_tab_widget.dart
- ✅ `deprecated_member_use` - app_text_field.dart (`scribbleEnabled` → `stylusHandwritingEnabled`)
- ✅ `overridden_fields` - app_text_field.dart, app_button.dart (uso de `super.key`)
- ✅ `body_might_complete_normally_catch_error` - registro_detalle_provider.dart
- ✅ `unnecessary_non_null_assertion` - app_error_state.dart
- ✅ `unnecessary_null_comparison` - app_error_state.dart
- ✅ `sort_child_properties_last` - app_card.dart (4 factory constructors)

#### **Issues de flutter_lints 6.0.0 (8 issues):**
- ✅ `strict_top_level_inference` (4 files) - Agregadas anotaciones de tipo explícitas
- ✅ `unnecessary_underscores` (4 files) - Reemplazado `(_, __)` por `(error, stackTrace)`

#### **Errores de Compilación:**
- ✅ `argument_type_not_assignable` - dano_form.dart (int? → int con operador !)
- ✅ `_AssertionError lifecycle.defunct` - AppSearchSelect crash al cerrar formulario

### **📦 Actualización de Dependencias**
Actualizadas dependencias críticas:
- ✅ **go_router**: `15.2.0` (retracted) → `16.0.0`
- ✅ **flutter_lints**: `5.0.0` → `6.0.0`
- ✅ **camera**: `0.11.1` → `0.11.2`
- ✅ **geolocator**: `14.0.1` → `14.0.2`
- ✅ **permission_handler**: `12.0.0+1` → `12.0.1`

## 📋 Tareas Pendientes

### **🧪 Testing y Validación - PRÓXIMA PRIORIDAD**
1. **Probar limpieza de providers**
   - Verificar logout completo limpia datos
   - Probar inicio/fin de asistencia
   - Validar que no quedan datos residuales

2. **Testing de navegación - go_router 16.0.0**
   - Verificar todas las rutas funcionan correctamente
   - Probar navegación entre pantallas
   - Validar que no hay breaking changes

3. **Validación general**
   - Ejecutar `flutter analyze` sin warnings
   - Probar funcionalidades críticas (cámara, GPS, permisos)
   - Verificar que la app compila y ejecuta sin errores

### **🎨 Design System (Pausado)**
- Migración pausada para enfocar en funcionalidad
- `detalle_danos.dart` parcialmente migrado
- Retomar después de validar testing

### Comando para Continuar
```bash
cd "C:\Users\Nestor\Desktop\Flutter\stampcamera"
claude-code .
```

## 🚨 **ISSUES CRÍTICOS PENDIENTES**

### **⚠️ Error Backend - Eliminación de Registros**
**Error 500**: No se puede eliminar `RegistroVinModel` por foreign keys protegidas
- **Causa**: `RegistroVinImagenesModel.registro_vin` impide eliminación
- **Solución Backend**: Implementar eliminación en cascada o validación previa
- **Registro**: VIN `LJ11RFCE9T1900765` con daños que tienen fotos

### **🎯 Tareas Backend Pendientes**
1. **Revisar modelo Django**: `RegistroVinImagenesModel` foreign key constraints
2. **Implementar cascada**: `on_delete=models.CASCADE` en relaciones
3. **Validación previa**: Verificar dependencias antes de eliminar
4. **Testing**: Probar eliminación con y sin dependencias

## 🏠 **ÚLTIMA SESIÓN COMPLETADA**

### **✅ Completado (2026-01-22) - v1.3.12+37**

#### **📊 Reporte de Pedeteo - Mejoras:**
1. **Restricción de acceso a Autos** - Solo usuarios de grupos "GESTORES COORDINACION AUTOS", "COORDINACION AUTOS" y superuser
2. **Filtros en Registro General** - Agregados filtros: Con Daños, Sin Reg. Puerto, Sin Recepción, Pedeteados
3. **Optimización de filtro "Con Daños"** - Cambiado de JOINs a `Exists` subqueries + índices en DB
4. **Reporte por jornadas** - Jornadas de 8 horas (23-07, 07-15, 15-23) con orden correcto
5. **Resumen por hora** - Al tocar en un empleado muestra desglose por hora con barra de progreso
6. **Orden nocturna corregido** - Horas ordenadas: 23:00 → 00:00 → 01:00 → ... → 06:00

#### **📁 Archivos Flutter Modificados:**
- `lib/models/user_model.dart` - Restricción `hasAutosAccess`
- `lib/providers/autos/registro_general_provider.dart` - Métodos `searchWithFilters`, `searchWithDanos`, `searchPedeteados`
- `lib/screens/autos/registro_general/registro_screen.dart` - Filter chips UI
- `lib/models/autos/reporte_pedeteo_model.dart` - Nuevo modelo con `ResumenHora`
- `lib/services/autos/reporte_pedeteo_service.dart` - Nuevo servicio
- `lib/screens/autos/reporte_pedeteo_screen.dart` - Nueva pantalla con desglose por hora

#### **📁 Archivos Backend Modificados:**
- `core/autos/apis/viewsapi.py`:
  - `RegistroGeneralFilter` - Filtros optimizados con `Exists`
  - `reporte_pedeteo_jornadas` - Endpoint con resumen por hora y orden nocturna
- `core/autos/models.py` - Índice en `DanosModel.vin` + índice compuesto

### **📍 Estado Actual - v1.3.12+37**
- ✅ Bundle generado: `build\app\outputs\bundle\release\app-release.aab` (56.3MB)
- ✅ Código limpio y funcional

## 📋 **PRÓXIMAS TAREAS PRIORITARIAS - PRÓXIMA SESIÓN**

### **🏗️ 1. REORGANIZACIÓN DEL PROYECTO - CRÍTICO**
El proyecto tiene mucho desorden de archivos que necesita reorganización:

#### **🗂️ Estructura Actual Problemática:**
```
lib/
├── screens/           # Mezcladas pantallas de diferentes módulos
├── widgets/           # Widgets sin organización por feature
├── providers/         # Providers sin agrupación lógica
├── services/          # Servicios esparcidos
├── models/            # Modelos sin organización
└── utils/             # Utilidades mezcladas
```

#### **🎯 Estructura Objetivo:**
```
lib/
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── models/
│   ├── asistencia/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── models/
│   ├── autos/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── models/
│   └── camera/
├── core/              # Design system, servicios globales
├── shared/            # Widgets, utils, servicios compartidos
└── config/            # Configuraciones, rutas, constantes
```

### **🔄 2. PANTALLAS DINÁMICAS SEGÚN ASISTENCIA Y USUARIO**
Implementar sistema de pantallas que se adapten según:

#### **📱 Estados de Asistencia:**
- **Sin Asistencia** - Solo mostrar botón "Marcar Entrada"
- **Asistencia Activa** - Mostrar todas las aplicaciones disponibles
- **Asistencia Pausada** - Mostrar opciones limitadas
- **Fin de Turno** - Solo mostrar "Marcar Salida"

#### **👤 Roles de Usuario:**
- **Inspector** - Acceso completo a autos, cámara, inventario
- **Supervisor** - Acceso a reportes, gestión de inspectores
- **Administrador** - Acceso total al sistema
- **Visitante** - Solo visualización limitada

#### **🎯 Check-Auth Mejorado:**
Expandir endpoint `api/v1/check-auth/` para incluir:
- Estado actual de asistencia del usuario
- Permisos específicos por rol
- Configuraciones dinámicas de UI
- Restricciones por ubicación/horario

### **🔧 3. SISTEMA DE ASISTENCIA MEJORADO**
Mejorar el sistema actual de asistencia:

#### **Frontend (Flutter):**
- **Geolocalización obligatoria** para marcar entrada/salida
- **Validación de horarios** según configuración del usuario
- **Estados intermedios** (pausa, almuerzo, break)
- **Notificaciones automáticas** para recordatorios
- **Sincronización offline** de marcajes

#### **Backend (Django):**
- **Validaciones de ubicación** con geofencing
- **Control de horarios** flexible por usuario/rol
- **Reportes automáticos** de asistencia
- **Notificaciones push** para supervisores
- **API mejorada** con más datos contextuales

### **🚀 4. FLUJO DE TRABAJO INTEGRADO**
Crear flujo completo que integre:

#### **Login → Check-Auth → Asistencia → UI Dinámica:**
```
1. Usuario hace login
2. check-auth devuelve: usuario + asistencia + permisos
3. UI se configura según estado de asistencia
4. Pantallas se adaptan según rol y permisos
5. Asistencia controla acceso a funcionalidades
```

### **📋 Plan de Implementación Sugerido:**

#### **Sesión 1: Reorganización de Archivos**
- Crear estructura de features
- Mover archivos a ubicaciones correctas
- Actualizar imports y referencias
- Testing que todo compile

#### **Sesión 2: Backend - Check-Auth Mejorado**
- Expandir modelo de asistencia
- Mejorar endpoint check-auth
- Agregar validaciones de ubicación
- Testing de API

#### **Sesión 3: Frontend - UI Dinámica**
- Implementar provider de estado de asistencia
- Crear widgets condicionales según estado
- Adaptar home_screen y navegación
- Testing de flujos

#### **Sesión 4: Integración y Testing**
- Testing completo del flujo integrado
- Corrección de bugs
- Optimizaciones de rendimiento
- Documentación

### **🎯 Comando para Próxima Sesión**
```bash
cd "C:\Users\Nestor\Desktop\Flutter\stampcamera"
claude-code .
```

**Decir a Claude:** "Revisa CLAUDE.md. El sistema de pedeteo y asistencia ya están pulidos. Ahora necesito reorganizar el proyecto en features y implementar pantallas dinámicas según estado de asistencia. ¿Por dónde comenzamos?"

### **📝 Notas Importantes:**
1. **Backup antes de reorganizar** - Es una refactorización grande
2. **Testing continuo** - Verificar que cada paso compile correctamente
3. **Trabajo Backend + Frontend** - Requerirá cambios en ambos lados
4. **Documentar cambios** - Mantener CLAUDE.md actualizado

### **✅ Lo que NO necesitas hacer**
- ❌ Corregir warnings (ya están todos eliminados)
- ❌ Actualizar dependencias (ya están actualizadas)
- ❌ Implementar sistema de providers (ya está completo)
- ❌ Crear AppSearchSelect (ya está implementado y funcionando)
- ❌ Fix biometría (ya fue removido completamente)
- ❌ Fix edición de fotos (ya usa PATCH correctamente)
- ❌ Fix permisos cámara/audio (ya tiene enableAudio: false)
- ❌ Fix coordinadores sin acceso (ya tienen acceso completo)

## Notas Técnicas

### Riverpod State Management
El proyecto usa Riverpod para gestión de estado. Los providers importantes:
- `detalleRegistroProvider(vin)` - Datos del vehículo
- Estados: loading, error, data

### Estructura de Datos
```dart
DetalleRegistroModel {
  String vin;
  List<Dano> danos;
  List<FotoPresentacion> fotosPresentacion;
  List<RegistroVin> registrosVin;
  InformacionUnidad? informacionUnidad;
}
```

### Helpers Utilizados
- `VehicleHelpers.getVehicleIcon()` - Íconos por marca
- `VehicleHelpers.getSeveridadColor()` - Colores por severidad
- `VehicleHelpers.getCondicionColor()` - Colores por condición

## Versiones
- **App**: 1.3.19+45
- **Flutter**: 3.38.7
- **Dart**: 3.10.7
- **flutter_riverpod**: ^2.6.1
- **go_router**: ^16.0.0

## ✅ **COMPLETADO - SESIÓN 2026-01-22 (Continuación)**

### **🏭 Módulo Graneles - Tabs Balanzas y Silos**
1. **BalanzaService** - Implementado `BaseService<Balanza>` con CRUD completo y paginación
2. **SilosService** - Implementado `BaseService<Silos>` con CRUD completo y paginación
3. **BalanzaNotifier** - Nuevo provider con `BaseListProviderImpl` para paginación y búsqueda
4. **SilosNotifier** - Nuevo provider con `BaseListProviderImpl` para paginación y búsqueda
5. **BalanzasTab** - Reescrito para funcionar igual que TicketsTab (global, sin necesidad de seleccionar servicio)
6. **SilosTab** - Reescrito para funcionar igual que TicketsTab (global, sin necesidad de seleccionar servicio)
7. **GranelesScreen** - Simplificado, ya no requiere servicio seleccionado para tabs

#### **Archivos Modificados:**
- `lib/services/graneles/graneles_service.dart` - BalanzaService y SilosService ahora implementan BaseService
- `lib/providers/graneles/graneles_provider.dart` - Nuevos providers: `balanzasListProvider`, `silosListProvider`
- `lib/screens/graneles/tabs/balanzas_tab.dart` - Reescrito con paginación y búsqueda global
- `lib/screens/graneles/tabs/silos_tab.dart` - Reescrito con paginación y búsqueda global
- `lib/screens/graneles/graneles_screen.dart` - Simplificado

## ✅ **COMPLETADO - SESIÓN 2026-01-23 - v1.3.14+39**

### **🚗 Mejoras UX Inventario - Detalle General**

#### **1. Botón "Versión / Inventario" rediseñado**
- Antes: fila idéntica a las demás (no se veía que era tocable)
- Ahora: botón con fondo de color (verde/naranja), borde, texto "Ver" + flecha, efecto ripple

#### **2. Vista General del vehículo rediseñada (estilo ticket graneles)**
- **Header con gradient**: VIN en grande, badges de Marca y Serie, icono de vehículo
- **Sección "Vehículo"**: Filas label:value (Modelo, Versión, Color) + botón inventario
- **Sección "Embarque"**: Filas label:value con toda la info de nave/embarque
- Unificado en un solo estilo consistente con el detalle de ticket en graneles

#### **3. Backend - Más datos de nave/embarque**
- Agregados campos: `puerto_descarga`, `fecha_atraque`, `destinatario`, `agente_aduanal`, `nombre_embarque`, `n_viaje`, `cantidad_embarque`
- Serializer con `SerializerMethodField` para relaciones profundas
- Queryset de retrieve separado sin `.only()` para evitar conflicto con `select_related`

#### **4. Filas de versiones en nave (inventario_detalle_nave_screen)**
- Antes: fila estática con flecha pequeña
- Ahora: tarjetas tocables con fondo color, efecto ripple, texto "Ver" + chevron

#### **Archivos Modificados Flutter:**
- `lib/widgets/autos/detalle_info_general.dart` - Rediseño completo
- `lib/models/autos/detalle_registro_model.dart` - 7 campos nuevos
- `lib/screens/autos/inventario/inventario_detalle_nave_screen.dart` - Versiones tocables
- `pubspec.yaml` - v1.3.14+39

#### **Archivos Modificados Backend:**
- `core/autos/apis/autos_serializers.py` - Campos nave/embarque en RegistroGeneralDetailSerializer
- `core/autos/apis/viewsapi.py` - Queryset retrieve con select_related adicional

### **📍 Estado: Bundle generado** - `build\app\outputs\bundle\release\app-release.aab` (56.4MB)

---

## ✅ **COMPLETADO - SESIÓN 2026-01-23 (Sesión 2) - v1.3.16+42**

### **🏠 Limpieza UI - Asistencia y Home**

#### **1. Asistencia - Vista activa unificada en una sola tarjeta**
- Antes: 3 widgets separados (LiveTimer + ResumenAsistenciaWidget + ListaAsistenciasWidget) con información repetida
- Ahora: Una sola tarjeta con gradient que muestra todo:
  - Indicador pulsante + "JORNADA ACTIVA"
  - Timer grande con tiempo transcurrido
  - Divider sutil
  - Filas de detalle: Entrada, Zona, Nave
- Eliminado `ResumenAsistenciaWidget` del screen (ya no se importa)
- Eliminado `ListaAsistenciasWidget` del screen (info integrada en la tarjeta)

#### **2. Home - Eliminadas cards "Próximamente"**
- Removido el loop que rellenaba el grid con cards de "Próximamente" para completar mínimo 4
- Ahora solo muestra los módulos reales del usuario

#### **3. Android 15 Edge-to-Edge Fix**
- **Problema**: Google Play advertía sobre APIs deprecadas (`setStatusBarColor`, `setNavigationBarColor`, `setNavigationBarDividerColor`)
- **Solución**:
  - `MainActivity.kt` - Agregado `enableEdgeToEdge()` en `onCreate()`
  - `styles.xml` (regular y night) - Removido `android:windowDrawsSystemBarBackgrounds=false`
- Esto resuelve el aviso de compatibilidad con Android 15+ (SDK 35+)

#### **Archivos Modificados:**
- `lib/screens/registro_asistencia_screen.dart` - Vista activa unificada en una tarjeta
- `lib/screens/home_screen.dart` - Removidas cards "Próximamente"
- `android/app/src/main/kotlin/.../MainActivity.kt` - `enableEdgeToEdge()`
- `android/app/src/main/res/values/styles.xml` - Edge-to-edge compatible
- `android/app/src/main/res/values-night/styles.xml` - Edge-to-edge compatible
- `pubspec.yaml` - v1.3.16+42

### **📍 Estado: Bundle generado** - `build\app\outputs\bundle\release\app-release.aab` (56.4MB)

---

## ✅ **COMPLETADO - SESIÓN 2026-01-24 - v1.3.19+45**

### **🔄 Fase 1: Migración navegación a go_router**
Migrados los últimos 3 archivos de `Navigator.push(MaterialPageRoute(...))` a `context.push()`:
- `detalle_fotos_presentacion.dart` — crear/editar foto
- `detalle_registro_screen.dart` — FAB de registroVin, foto, daño
- `contenedores_tab.dart` — crear/editar contenedor

**Quedan 2 `Navigator.push` intencionales** (no migrar):
- `detalle_imagen_preview.dart` — overlay fullscreen de imagen
- `registro_screen.dart` — escáner VIN con callback

### **⚡ Fase 2: Timers adaptativos + CachedNetworkImage**

#### Timers con backoff exponencial (10s → 120s):
- `lib/services/queue_service.dart` — Timer.periodic 30s → Timer adaptativo
- `lib/services/offline_first_queue.dart` — Timer.periodic 30s → Timer adaptativo

#### Image.network → CachedNetworkImage (10 instancias, 7 archivos):
- `lib/widgets/common/reusable_camera_card.dart` (2)
- `lib/widgets/autos/detalle_imagen_preview.dart` (2)
- `lib/screens/graneles/ticket_detalle_screen.dart` (1)
- `lib/screens/graneles/tabs/tickets_tab.dart` (1)
- `lib/screens/graneles/tabs/balanzas_tab.dart` (1)
- `lib/screens/graneles/tabs/almacen_tab.dart` (1)
- `lib/screens/autos/contenedores/contenedores_tab.dart` (2)

**Dependencia agregada:** `cached_network_image: ^3.4.1`

### **🎯 Fase 3: Optimización de rebuilds**
- `lib/screens/registro_asistencia_screen.dart` — Timer 1s con setState → `ValueNotifier<Duration>` + `ValueListenableBuilder` (eliminados 60 rebuilds/min)
- `lib/screens/autos/contenedores/contenedor_form.dart` — 4 setState consecutivos → 1 consolidado

### **🐛 Bug Fix: Formulario de daño con botón bloqueado**

**Síntoma:** Botón de submit queda deshabilitado permanentemente después de un intento fallido.

**Causa raíz:** `_hasSubmitted = true` nunca se reseteaba si la operación fallaba. Condición del botón: `(_isLoading || _hasSubmitted || !_canSubmit) ? null : _submitForm`

**Fixes aplicados (2 capas):**
1. `_hasSubmitted = false` en branches de error y catch
2. Timeout de 10s en llamadas offline-first (previene hang si SharedPreferences se bloquea)

**Archivos:**
- `lib/widgets/autos/forms/dano_form.dart`
- `lib/widgets/autos/forms/fotos_presentacion_form.dart`

### **📍 Estado: Bundle generado** - `build\app\outputs\bundle\release\app-release.aab` (56.6MB)

---

---

## 🔐 **SISTEMA DE PERMISOS UNIFICADO - Flutter/React (2026-01-30)**

### **Resumen**
Se unificó el endpoint `/api/v1/check-auth/` para que Flutter y React consuman el mismo formato de permisos con CRUD granular.

### **Endpoint: GET /api/v1/check-auth/**

```json
{
  "user": {
    "id": 123,
    "username": "jperez",
    "email": "jperez@empresa.com",
    "first_name": "Juan",
    "last_name": "Perez",
    "is_superuser": false,
    "groups": ["INSPECTOR", "AUTOS"],
    "ultima_asistencia_activa": {
      "id": 456,
      "zona_trabajo": "PUERTO",
      "nave_id": 789,
      "nave_nombre": "NAVE EJEMPLO",
      "rubro": "AUTOS"
    },
    "available_modules": [
      {
        "id": "camera",
        "name": "Cámara",
        "icon": "camera_alt",
        "requires_asistencia": false,
        "permisos": {
          "ver": true,
          "crear": true,
          "editar": false,
          "eliminar": false
        }
      },
      {
        "id": "autos",
        "name": "Autos",
        "icon": "directions_car",
        "requires_asistencia": true,
        "permisos": {
          "ver": true,
          "crear": true,
          "editar": true,
          "eliminar": false
        }
      }
    ]
  },
  "es_cliente": false,
  "cliente_empresa": null,
  "es_empleado": true,
  "empleado": {
    "id": 45,
    "nombre_completo": "Juan Perez",
    "cargo": "Inspector"
  }
}
```

### **Campos ELIMINADOS del Response**
Ya NO se envían (filtrado por queryset en backend):
- `puertos_permitidos`
- `talleres_clientes_ids`

### **Módulos Disponibles**

| ID | Descripción | Grupos |
|----|-------------|--------|
| `camera` | Cámara/Fotos | Todos (excepto clientes) |
| `asistencia` | Marcar entrada/salida | Todos (excepto clientes) |
| `autos` | Embarques, VINs, Daños | AUTOS, INSPECTOR, COORDINACION AUTOS, GESTORES |
| `granos` | Servicios, Tickets | GRANELES, INSPECTOR, COORDINACION GRANELES |
| `casos` | Casos y Documentos | CASOS Y DOCUMENTOS |

### **Implementación Flutter - Modelos**

```dart
// lib/models/permisos.dart

class ModuloPermiso {
  final String id;
  final String name;
  final String icon;
  final bool requiresAsistencia;
  final PermisosCRUD permisos;

  ModuloPermiso({
    required this.id,
    required this.name,
    required this.icon,
    required this.requiresAsistencia,
    required this.permisos,
  });

  factory ModuloPermiso.fromJson(Map<String, dynamic> json) {
    return ModuloPermiso(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      requiresAsistencia: json['requires_asistencia'] ?? false,
      permisos: PermisosCRUD.fromJson(json['permisos']),
    );
  }
}

class PermisosCRUD {
  final bool ver;
  final bool crear;
  final bool editar;
  final bool eliminar;

  PermisosCRUD({
    required this.ver,
    required this.crear,
    required this.editar,
    required this.eliminar,
  });

  factory PermisosCRUD.fromJson(Map<String, dynamic> json) {
    return PermisosCRUD(
      ver: json['ver'] ?? false,
      crear: json['crear'] ?? false,
      editar: json['editar'] ?? false,
      eliminar: json['eliminar'] ?? false,
    );
  }
}
```

### **Implementación Flutter - Helper en UserState**

```dart
class UserState {
  List<ModuloPermiso> availableModules;

  bool canAccess(String moduloId, {String accion = 'ver'}) {
    final modulo = availableModules.firstWhereOrNull((m) => m.id == moduloId);
    if (modulo == null) return false;

    switch (accion) {
      case 'ver': return modulo.permisos.ver;
      case 'crear': return modulo.permisos.crear;
      case 'editar': return modulo.permisos.editar;
      case 'eliminar': return modulo.permisos.eliminar;
      default: return false;
    }
  }

  bool hasModule(String moduloId) {
    return availableModules.any((m) => m.id == moduloId);
  }
}
```

### **Uso en Widgets**

```dart
// Antes - solo verificaba si tenía el módulo
if (user.availableModules.contains('autos')) { ... }

// Ahora - permisos granulares CRUD
if (user.canAccess('autos', accion: 'ver')) {
  // Mostrar módulo
}

if (user.canAccess('autos', accion: 'crear')) {
  FloatingActionButton(onPressed: () => crearRegistro())
}

// Deshabilitar si no tiene permiso
ElevatedButton(
  onPressed: user.canAccess('autos', accion: 'editar') ? () => editar() : null,
)
```

---

## 🌐 **WEBSOCKET DE PRESENCIA (Redis)**

### **Endpoint:** `wss://host/ws/presencia/`

### **Eventos Cliente → Servidor:**
```json
{"type": "heartbeat"}           // Mantener conexión (enviar cada 30s)
{"type": "route_change", "route": "/app/autos"}  // Cambio de pantalla
{"type": "ping"}                // Ping simple
```

### **Eventos Servidor → Cliente:**
```json
{"type": "force_logout", "reason": "user_deactivated", "message": "..."}
{"type": "permissions_updated", "grupos": [...], "modulos": {...}}
{"type": "asistencia_changed", "asistencia": {...}}
{"type": "pong"}
```

### **Características:**
- Presencia almacenada en **Redis** (no en base de datos)
- TTL: 10 minutos (renovado con heartbeat)
- Force logout cuando usuario es desactivado
- Actualización de permisos en tiempo real

### **Implementación Flutter (Opcional)**

```dart
class PresenciaWebSocket {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;

  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://tu-servidor/ws/presencia/?token=$token'),
    );

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'force_logout':
          // Cerrar sesión y redirigir a login
          break;
        case 'permissions_updated':
          // Actualizar permisos locales
          break;
        case 'asistencia_changed':
          // Actualizar estado de asistencia
          break;
      }
    });

    // Heartbeat cada 30 segundos
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'type': 'heartbeat'}));
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
  }
}
```

---

## 📋 **TAREAS PENDIENTES - PRÓXIMA SESIÓN**

### **🔐 PRIORITARIO: Implementar Sistema de Permisos Unificado**
**Estado:** PENDIENTE - Documentado arriba, falta implementar

1. **Crear modelos** - `ModuloPermiso` y `PermisosCRUD` (código arriba)
2. **Actualizar UserModel/AuthProvider** - Parsear `available_modules` del check-auth
3. **Agregar helper `canAccess()`** - Verificar permisos CRUD
4. **Actualizar widgets** - Usar `canAccess('autos', accion: 'crear')` en vez de `contains('autos')`
5. **Opcional: WebSocket presencia** - Para force_logout y actualizaciones en tiempo real

### **🚗 Inventario (Siguientes partes)**
1. **Vista de nave** - Mejorar UX: cargas lentas, diseño visual, usabilidad
2. **Sección resumen/avances de nave** - Poco intuitivo, mejorar
3. **Formulario de inventario** - Revisar flujo

### **🏭 Módulo Graneles**
1. **Formulario de Balanza** - Verificar que funciona correctamente
2. **Formulario de Silos** - Implementar (actualmente solo lectura)

### **🏗️ Reorganización del Proyecto (Cuando haya tiempo)**
- Reorganizar estructura en features
- Implementar pantallas dinámicas según asistencia

---

*Archivo generado automáticamente por Claude Code*
*Última actualización: 2026-01-24 - v1.3.19+45 - ✅ GO_ROUTER MIGRATION + ADAPTIVE TIMERS + CACHED IMAGES + BUGFIX*
---

## ✅ **COMPLETADO - SESIÓN 2026-06-12 - Filtros pedeteo + Lista Registro VIN + Recepción en inventarios**

### **1. PEDETEO - Filtro marca/modelo + mini dashboard**
- Filtros locales por Marca y Modelo (dropdowns sobre `vins_disponibles`, sin backend)
- Al cambiar marca se resetea el filtro de modelo
- Mini dashboard: pedeteados / pendientes / total (o "filtrados") + barra de progreso con %
- Archivos: `lib/providers/autos/pedeteo_provider.dart` (`pedeteoMarcaFilterProvider`, `pedeteoModeloFilterProvider`), `lib/screens/autos/pedeteo_screen.dart`

### **2. REGISTROS - Lista de registros VIN individuales (en pantalla "Registros VIN" del AppBar)**
- **OJO: la pantalla principal de REGISTRO (`registro_screen.dart`) NO se tocó** — mantiene su lista de unidades, filtro de nave y chips de estado
- Lo reemplazado es la pantalla del botón del AppBar (`/autos/resumen-registros` → `resumen_registros_screen.dart`): antes era el resumen agrupado día→hora→usuario, ahora es la lista plana práctica
- Nueva lista consume `/api/v1/autos/registro-vin/` (ordenada por -id = más reciente primero)
- Cada card muestra: VIN, marca/modelo, badge de condición, nave, **fecha dd/MM/yyyy + hora HH:mm** y **usuario registrador**
- Filtro por usuario registrador (`?create_by=<id>`) con bottom sheet; usuarios derivados de `resumen-registros/` (sin backend nuevo)
- Chips de condición (Puerto/Recepción/Almacén/PDI/Pre-PDI) → `?condicion=`
- Archivos nuevos: `lib/models/autos/registro_vin_list_model.dart`, `lib/services/autos/registro_vin_list_service.dart`, `lib/providers/autos/registro_vin_list_provider.dart`
- Reescrito: `lib/screens/autos/registro_general/resumen_registros_screen.dart`

### **3. INVENTARIOS - Recepción en cuadro de descarga + export de pendientes**
- Cuadro por marca ahora tiene 4 columnas: MODELO | TOTAL | DESC. | RECEP. (`descargado_recepcion`)
- Fila de totales y reporte PNG compartible también incluyen RECEPCIÓN
- Subtítulo de versión muestra conteo de recepcionados
- Botón de descarga en AppBar (menú): "Faltan pedetear (Excel)" y "Faltan recepcionar (Excel)" → descarga bytes y comparte con share_plus
- Archivos: `lib/screens/autos/inventario/inventario_detalle_nave_screen.dart`, `lib/services/autos/inventario_service.dart` (`descargarPendientesExcel`)

### **🎯 PENDIENTE BACKEND (sesión Django)**
1. **REQUERIDO** - Endpoint export de pendientes:
   `GET /api/v1/autos/registro-general/export-pendientes/?nave_descarga_id=<id>&tipo=pedeteo|recepcion`
   → HttpResponse xlsx (openpyxl, patrón de autos/excel/). Lógica:
   - tipo=pedeteo: unidades de la nave SIN RegistroVin con condicion in [PUERTO, ALMACEN]
   - tipo=recepcion: unidades de la nave SIN RegistroVin con condicion = RECEPCION
   - Columnas sugeridas: VIN, serie, marca, modelo, versión, color, embarque/BL, destinatario
2. *Opcional* - Action `usuarios/` en RegistroVinViewSet (lista limpia de registradores); hoy se deriva de `resumen-registros/` y funciona.

### **📍 Estado**: `flutter analyze` sin issues. Sin bump de versión (pendiente probar en dispositivo).

---

## ✅ **COMPLETADO - SESIÓN 2026-06-12 (Sesión 2) - Fix contenedores + Motor de watermark NATIVO**

### **1. FIX: Contenedores no aparecían en Registro VIN hasta reiniciar la app**
- **Causa raíz**: `registroVinOptionsProvider` (FutureProvider SIN autoDispose → cacheado indefinidamente) alimenta el dropdown de contenedores en `registro_vin_forms.dart`, y al crear/editar/eliminar un contenedor NADIE lo invalidaba. Solo se invalidaba en logout (SessionManager) — por eso "aparecían" al reiniciar la app.
- **Fix**: `ContenedorNotifier` ahora llama `_invalidateOpcionesDependientes()` (→ `ref.invalidate(registroVinOptionsProvider)`) tras create/update/updateWithFiles/delete exitosos. Cubre TODOS los call sites.
- Archivo: `lib/providers/autos/contenedor_provider.dart`

### **2. MOTOR DE WATERMARK NATIVO (portado del proyecto KMP `D:\AyG KMP`)**
El cuello #1 de la cámara era el post-procesado (watermark + compresión) corriendo en el main isolate de Dart (300-800ms de UI congelada por foto). Ahora todo el pipeline corre en Kotlin en un hilo de fondo:

- **`android/.../NativeImageProcessor.kt`** (NUEVO) — Port del `ImageProcessor.android.kt` del KMP:
  - Decodifica desde path con `inSampleSize` (máx 2560px), rotación EXIF, logo cacheado (decode 1 sola vez), texto con contorno+relleno, 9 posiciones, fuentes AUTO/S/M/L.
  - **Compresión adaptativa**: arranca en calidad 90 y baja de 7 en 7 (piso 60) hasta entrar en 950KB → fotos de ~400-600KB (antes: quality 100 sin techo).
  - Guarda en `DCIM/StampCamera` y registra en MediaStore (mismo dir/nombre `IMG_<millis>.jpg` que el pipeline Dart).
  - Agregado al KMP original: stacking de timestamp+ubicación cuando comparten posición (paridad con pipeline Dart).
- **`MainActivity.kt`** — Nuevo channel `image_processor_channel`, método `processAndSaveImage`, ejecuta en `Executors.newSingleThreadExecutor()` (serializa ráfagas, evita picos de RAM) y responde en main looper.
- **`lib/utils/image_processor.dart`** — `processAndSaveImage()` delega al nativo en Android (solo cruza el PATH por el channel, nunca los bytes de la foto; el logo sí se pasa como bytes y el nativo lo cachea). **Fallback automático al pipeline Dart** si el channel no existe (`MissingPluginException` → flag `_nativeEngineAvailable`) o si el nativo lanza error. iOS sigue usando el pipeline Dart.
- Dart sigue siendo dueño del formato: timestamp (`dd/MM/yyyy HH:mm:ss` con segundos) y texto de ubicación (LocationService con geocoding + caché 5min) se pasan ya formateados → no se portó LocationHelper ni se agregó NINGUNA dependencia Gradle.

**Cambios de comportamiento esperados (heredados del motor KMP, intencionales):**
- Fotos ahora pesan ~400-600KB (antes podían pasar 2-4MB con quality 100).
- Texto del watermark algo más grande (AUTO a 2560px: 48px vs 32px del pipeline Dart) — calibración del KMP v1.6.0.
- UI ya NO se congela al procesar: el isolate de Dart solo espera el path.

### **📍 Estado**: ✅ **PROBADO EN DISPOSITIVO (Galaxy S22)**: motor nativo procesando fotos en 70-300ms en hilo de fondo (antes 300-800ms bloqueando UI), watermark OK, fix de contenedores verificado.

---

## ✅ **COMPLETADO - SESIÓN 2026-06-12 (Sesión 3) - UI ligera + Pedeteo pulido (SECCIÓN CERRADA)**

### **1. ReusableCameraCard - decodes acotados y sin Hero**
- `Image.file` post-captura decodificaba la foto ORIGINAL completa (4000px) y luego la procesada → `cacheWidth: 1600` + `gaplessPlayback` (preview full-screen) y `cacheWidth: 1024` (preview card 200px); `memCacheWidth: 1024` en CachedNetworkImage.
- Botón fullscreen: `FloatingActionButton.small` → `Material`+`InkWell` (el heroTag default compartido crashea con varios cards en un form); obturador con `heroTag: null`.
- Eliminado overlay "Procesando imagen..." inalcanzable y la fila informativa "La foto será marcada automáticamente..."; título `titleLarge` → `titleMedium`.
- Color por defecto `0xFF0A2D3E` → `AppColors.primary` (también en pedeteo action_buttons y camera_card).

### **2. Scanner de pedeteo - rediseño + FIX de latencia de detección**
- **FIX CRÍTICO de latencia**: con `returnImage: true`, mobile_scanner codifica el frame COMPLETO a PNG (1920x1080 default) ANTES de disparar el callback → "detectaba" 2-3s después de quitar la cámara. Fix: `cameraResolution: Size(1280, 720)` + `formats:` restringidos a etiquetas VIN (code39, code128, dataMatrix, qrCode, pdf417). Proceso completo medido: ~800ms (incl. 500ms de pausa de confirmación).
- **Feedback inmediato**: `HapticFeedback.mediumImpact()` al detectar + overlay con check verde 72px + VIN leído en pill monospace + "Guardando foto..." → pausa 500ms (deliberada, para alcanzar a leer el VIN confirmado) → pop al formulario.
- **Rediseño visual**: header `AppColors.primary` con estado integrado, sin borde azul de 3px, sin "VIN" gigante, esquinas del visor ALINEADAS al marco (antes a 50px fijos del borde), sin footer redundante, sin texto debug "Estado: vinDetected".

### **3. Formulario de pedeteo**
- `FormFieldsCard` ("Datos del Registro"): mismo estilo de tarjeta que `DetalleRegistroCard` — blanco, radiusL, sombra sutil, **accent strip lateral 4px**, header con icono en chip + título azul corporativo. Shell reutilizado en loading/error (strip rojo en error).

### **4. Buscador de pedeteo - mínimo 3 caracteres**
- Con 1-2 caracteres el `contains` matcheaba media nave y el dropdown volcaba la lista completa. Guard en `pedeteoSearchResultsProvider` (`query.trim().length < 3` → vacío) y en `_onSearchChanged` (dropdown solo con ≥3 chars). Búsqueda automática a 17 chars intacta.

### **5. Scanner - flujo final y decisión sobre el fork**
- Eliminado delay muerto de 500ms + `Navigator.pop` fantasma post-escaneo (el scanner está embebido, no es ruta; `onBarcodeScanned` ya lo desmonta). Tiempos reales medidos en dispositivo: **150-275ms** del callback al formulario.
- **Latencia restante (~300-500ms)**: es el plugin `mobile_scanner` codificando el frame a **PNG calidad 100** ANTES de disparar el callback (visto en su código fuente, `MobileScanner.kt` línea ~186). DECISIÓN: **fork pospuesto**. Balas guardadas si se necesita más velocidad:
  - **Opción A**: vendorear `mobile_scanner 7.0.1` en `packages/` + cambiar 1 línea (`CompressFormat.PNG, 100` → `JPEG, 90`) + `dependency_overrides` → empaquetado ~50-80ms. Deuda: re-aplicar parche en cada upgrade del plugin (es solo Android).
  - **Opción B**: scanner propio con plugin `camera` + MLKit + `takePicture()` real (ISP hardware) — 2-3 días, es lo que hace la app KMP.

### **📍 Estado FINAL**: `flutter analyze` sin issues. Probado en Galaxy S22. **Pedeteo CERRADO.** Versión **1.5.4+66** (salto de +65 porque el proyecto KMP usa el mismo applicationId con versionCode 65). Bundle release generado.

---

## ✅ **COMPLETADO - SESIÓN 2026-07-07 - v1.5.5+67 - Flujo directo de almacén en graneles**

### **Flujo inspector zona ALMACÉN (tab Viajes de graneles)**
Si el usuario tiene asistencia activa en zona tipo `ALMACEN`/`ALMACEN-PDI` (vía `userGranelesPermissionsProvider.zonaTipo`, que viene de `user_permissions/`) y permiso `almacen.canAdd||canEdit`:
- Tocar ticket **Pend. Almacén** → DIRECTO al formulario de viaje paso 3 (`/graneles/viaje/editar/{id}?step=3&origen=lista`), sin pasar por el detalle
- **Guardar** → regresa a la lista de tickets (pop imperativo `Navigator.of(context).pop()` que NO consulta el PopScope)
- **Atrás sin guardar** → `pushReplacement` al detalle del ticket (para validar datos); atrás desde ahí cae en la lista
- Ticket **Completo** → detalle directo como siempre
- `pendiente_balanza` → detalle (el inspector de almacén no puede registrar balanza; backend `can_add=false`)

### **Implementación (`origen=lista` como flag de entrada)**
- `lib/screens/graneles/tabs/tickets_tab.dart` — `_onTicketTap()` con gate por zona+permisos
- `lib/routes/app_router.dart` — ruta `viaje/editar/:ticketId` lee `?origen=lista` → `cancelToDetail: true`
- `lib/screens/graneles/viaje_form_screen.dart` — param `cancelToDetail` en `.edit`; `_wrapCancelPop()` con `PopScope(canPop:false)` que redirige al detalle; submit usa pop imperativo cuando `cancelToDetail`
- Flujos existentes (detalle → editar) intactos: sin `origen=lista` no hay PopScope

### **⚠️ Deuda conocida (no tocada)**
- FABs de `almacen_tab.dart` y `balanzas_tab.dart` apuntan a rutas muertas (`/graneles/almacen/crear`, `/graneles/balanza/crear|editar` no existen en el router; los formularios viejos fueron eliminados). El registro real es vía `ViajeFormScreen`.

### **📍 Estado**: `flutter analyze` sin issues. Bundle generado: `build\app\outputs\bundle\release\app-release.aab` (57.6MB). ✅ **Probado en dispositivo** con inspector en zona almacén (confirmado 2026-07-16).

### **⚠️ NOTA**: La sección "Versiones" arriba en este archivo está desactualizada (decía 1.3.19+45); la versión real del proyecto va en pubspec.yaml.

---

## ✅ COMPLETADO - SESIÓN 2026-07-07 (Sesión 2) - Fix edge-to-edge: contenido tapado por barra de 3 botones

### Problema
Con `enableEdgeToEdge()` (obligatorio para Android 15), en teléfonos con barra de navegación de 3 botones (~48dp) el contenido inferior quedaba tapado en muchas pantallas. Con gestos casi no se notaba. No hay fix global en Flutter que no rompa las pantallas fullscreen (cámara/visores): se corrigió por pantalla.

### Reglas aplicadas
- Scroll full-screen → sumar `MediaQuery.of(context).padding.bottom` al padding bottom del scroll (ListView/GridView con padding explícito pierden el inset automático; SingleChildScrollView nunca lo tiene).
- Bottom sheets/modales → `viewInsets.bottom + padding.bottom` (teclado + barra; padding.bottom se vuelve 0 cuando el teclado está abierto, no se duplica). Sheets de solo lectura usan `viewPadding.bottom`.

### Archivos corregidos (21 puntos)
- Full-screen: `home_screen.dart`, `detalle_registro_screen.dart` (_buildScrollableTab cubre los 4 tabs), `reporte_pedeteo_screen.dart`, `ticket_detalle_screen.dart`, `servicio_dashboard_screen.dart`, `jornadas_screen.dart`, `resumen_registros_screen.dart` (lista + _UsuarioSearchSheet), `casos_home_screen.dart` (2 listas), `explorador_screen.dart`, `inventario_tab_widget.dart`, `imagenes_tab_widget.dart`, `inventario_detalle_nave_screen.dart`, `gallery_selector_screen.dart`
- Sheets/modales: `inventario_form.dart`, `simple_add_image_modal.dart`, `modal_entrada.dart`, `editar_nave_bottom_sheet.dart`, detail sheets de `paralizaciones_tab.dart` y `control_temperatura_tab.dart`, `_NaveSearchSheet` en `registro_screen.dart`
- Drawer: `queue_side_widget.dart` (cola offline pedeteo)

### Ya estaban bien (no tocados)
`autos_screen` (BottomNavigationBar de Material maneja el inset solo), `graneles_screen` (SafeArea en TabBar), `viaje_form_screen` (bottom bar ya sumaba padding.bottom), formularios de autos con SafeArea (dano_form, registro_vin_forms, fotos_presentacion_form, contenedor_form), forms de graneles con SizedBox + padding.bottom (paralizacion, control_humedad, silos_crear), login/camera/visores con SafeArea completo, `registro_asistencia_screen` (padding bottom 100).

### 📍 Estado: `flutter analyze` sin issues. Versión **1.5.6+68**. Bundle generado: `build\app\outputs\bundle\release\app-release.aab` (57.6MB). ✅ **Probado en dispositivo con barra de 3 botones** (confirmado 2026-07-16). Todo commiteado y pusheado a origin/main.

---

## ✅ COMPLETADO - SESIÓN 2026-07-17 - Configuración iOS + primera subida a App Store

### Configuración de firma iOS (primera vez)
- **Bundle ID iOS**: `com.nestorfar.stampcamera` (unificado con el applicationId de Android; antes decía com.aygajustadores.stampcamera)
- **Team**: A&G Ajustadores y Peritos de Seguros S.A.C — `DEVELOPMENT_TEAM = JZ4ZUD5L9A` en las 3 configs de Runner, firma automática
- **Info.plist**: agregados NSCameraUsageDescription, NSMicrophoneUsageDescription, NSLocationWhenInUseUsageDescription, NSPhotoLibraryUsageDescription (NSFaceIDUsageDescription ya existía)
- **iPhone de prueba registrado** en la cuenta (UDID 00008030-001D71C12199802E) — requerido para el perfil de desarrollo
- Llavero: clave privada del certificado con acceso permitido a todas las apps (evita el diálogo de codesign por cada framework)

### Build y subida
- `flutter build ipa --release` → `build/ios/ipa/stampcamera.ipa` (27MB), v1.5.6+68
- Subido a App Store Connect vía Xcode Organizer (Distribute App)
- `permission_handler` 9.4.7 (iOS) trae todos los macros en 0 por defecto → no hizo falta tocar el Podfile
- NOTA: archivar con `xcodebuild` crudo falla ("Flutter/Flutter.h not found" en geolocator); usar SIEMPRE `flutter build ipa`

### Próximos pasos iOS
- TestFlight: instalar y probar en iPhone (cámara, scanner, GPS, watermark — iOS usa el pipeline Dart, NO el motor nativo Kotlin)
- Completar ficha de App Store Connect: screenshots, descripción, política de privacidad, y enviar a revisión

---

## ✅ COMPLETADO - SESIÓN 2026-07-17 (continuación) - Fixes iOS probados en iPhone + App Store Connect

### Bugs iOS encontrados probando en iPhone 11 físico (v1.5.6+70/71)
1. **Galería de cámara vacía**: `camera_provider._loadImages()` buscaba en `/storage/emulated/0/DCIM/StampCamera` (ruta Android hardcodeada). Fix: iOS usa `Documents/StampCamera` (misma ruta donde guarda `ImageProcessor._saveProcessedImage`).
2. **Compartir crasheaba**: share_plus en iOS exige `sharePositionOrigin`. Fix: helper `shareOriginOf(context)` en `lib/utils/share_utils.dart`, aplicado a los 5 call sites de SharePlus.
3. **Fotos invisibles en WhatsApp/Fotos**: en iOS quedaban solo en la carpeta privada de la app. Fix: paquete `gal ^2.3.2` — tras guardar, `Gal.putImage()` copia al carrete (solo iOS, permiso add-only `NSPhotoLibraryAddUsageDescription`). Android intacto.

### App Store Connect (app "AYG APP", ID 6791653349)
- Builds subidos: 69 (solo-iPhone) por Organizer; **el definitivo es el 71** (con los 3 fixes)
- Capturas: `appstore_assets/final_65/` (1284×2778 - la cuenta pide 6,5"; las 6,9" en `final/`)
- Notas del revisor con credenciales y token: `appstore_assets/notas_revisor.md` (carpeta en .gitignore)
- Usuario demo Apple: appletest (token de dispositivo fijo, ver notas_revisor.md)
- Política de privacidad: https://www.aygajustadores.com/privacy-policy/

### ⚠️ Lecciones de esta Mac (228GB, siempre al límite)
- Cada `flutter build ipa` genera ~4GB en DerivedData → limpiar con `rm -rf ~/Library/Developer/Xcode/DerivedData` cuando falte espacio
- **NO borrar** el runtime del simulador (`xcrun simctl runtime delete`): en Xcode 26 esa plataforma también se necesita para instalar en iPhones físicos (re-descarga de ~4GB con `xcodebuild -downloadPlatform iOS`)
- Export de ipa por CLI falla (sin cert de distribución local); la subida SIEMPRE por Xcode Organizer (usa firma en la nube)

---

## ✅ COMPLETADO - SESIÓN 2026-07-20 - v1.6.0+73 - Autorización de equipos en login + FCM Android

### 🔐 1. Flujo de autorización de equipos DENTRO del login (contrato nuevo del backend admin-v2)
El backend tiene dos sistemas de login; la app ahora usa el NUEVO (`POST /api/v1/auth/login/start/`, `client_type: "api"`):
- `authenticated` → tokens directos (equipo de confianza, 365 días)
- `pending_otp` → código 6 dígitos al correo → `verify-otp/` (con botón "¿No te llegó? Pedir aprobación admin" → `request-admin-approval/`)
- `pending_admin` → pantalla con `user_code` (ABCD-2345) en grande + **polling cada 4s** a `device-approval/status/` hasta authenticated/rejected/expired
- El `flow_secret` viaja en el body JSON; el `device_id` (64 hex) lo genera el SERVIDOR y la app lo adopta
- **El WS DeviceFlowConsumer es solo web** (exige sesión Django); en móvil la espera es polling
- **Botón verde WhatsApp** (font_awesome_flutter) en la pantalla del código → share sheet del sistema (elegible WhatsApp/Business/SMS) con mensaje "Solicito aprobación... Usuario + Código"
- Gate pre-login `/device-registration` ELIMINADO del router; la ruta queda accesible solo manual (footer del login) para equipos compartidos por token
- "Cambiar equipo" ya no navega al registro: limpia y el próximo login re-verifica
- `http_service`: los 401 de `auth/login/*`, `auth/device-approval/*` y `api/v1/token/` ya NO disparan refresh de token (son credenciales inválidas)
- Biométrico: usa el mismo `login/start` (equipo confiable → directo); si el equipo fue revocado cae al flujo manual

**Archivos nuevos:** `lib/models/login_flow_model.dart`, `lib/services/login_flow_service.dart`, `lib/providers/login_flow_provider.dart`
**Modificados:** `auth_provider` (login vía start + `completeLoginWithTokens`), `login_screen` (3 fases en la misma pantalla), `device_provider` (`markRegistered` sin pasar por checking), `app_router`, `http_service`

### 🔔 2. Notificaciones push FCM (Android)
- **Backend (2 commits en admin-v2, repo Django):** `4a1747763` `/save-fcm-token/` ahora es vista DRF (acepta JWT del móvil además de sesión web) · `a718c3809` payload FCM con `data: {type, id, url, route}` en task Celery y management command (antes solo `type`; la URL iba en webpush que el móvil ignora)
- **Flutter:** `lib/services/push_notification_service.dart` — registro del token tras login (`mobile: true`), re-registro en `onTokenRefresh`, `deleteToken()` en logout, navegación al tocar la push mapeando `data.route` → rutas de la app. **Foreground NO muestra nada** (el WS ya entrega en vivo; FCM es respaldo para background/cerrada — la bandeja del sistema pinta sola)
- **Firebase:** proyecto `fcm-django-bd051` (sender 212704024550). La app Android `com.nestorfar.stampcamera` se registró VÍA API con el service account del backend (script en scratchpad; la CLI firebase de npm está rota) → `android/app/google-services.json` (commiteado, no es secreto). AppId: `1:212704024550:android:971de2234a042559202827`
- Gradle: plugin `com.google.gms.google-services 4.4.4` (settings + app, compatible AGP 9). Manifest: `POST_NOTIFICATIONS`
- Deps: `firebase_core 4.12.1`, `firebase_messaging 16.4.3`, `device_info_plus` (nombre legible del equipo), `font_awesome_flutter 11.0.0` (la 10.x NO compila en Flutter 3.44: extiende IconData que ahora es final)
- iOS queda PENDIENTE (subir clave APNs a Firebase + GoogleService-Info.plist; la app tolera la ausencia: sin config no hay push pero no crashea)

### ⚠️ Lecciones de esta PC (16GB RAM, disco 238GB al límite)
- Cada build release genera ~4GB de intermedios; con 6 builds el disco pasó de 10GB a 100MB libres → builds fallando por RAM (OOM del AOT de Dart) y luego por disco
- `gradle.properties` bajado a propósito a `-Xmx4G -XX:MaxMetaspaceSize=1G` (con 8G el daemon ahogaba al compilador) — NO subirlo
- Limpieza aplicada: cachés muertos Gradle 8.14 (~4.8GB) + `flutter clean`. El Temp de Windows quedó pendiente (tan grande que cuelga `du`)
- NUNCA `flutter build | tail && install`: el pipe enmascara el exit code y se instala un APK viejo. Usar guard con exit code + grep "√ Built"

### 📍 Estado
- ✅ Probado en Galaxy S22: flujo completo de aprobación (código → WhatsApp → admin aprueba → entra solo)
- ✅ Bundle: `build\app\outputs\bundle\release\app-release.aab` (73.8MB) v1.6.0+73
- ⏳ PENDIENTE: desplegar los 2 commits del backend admin-v2 (sin eso el registro del token FCM da 401 en producción)
- ⏳ PENDIENTE: probar push end-to-end tras el deploy · FCM iOS

---

## ✅ COMPLETADO - SESIÓN 2026-07-20 (Sesión 2) - Centro de notificaciones in-app + FCM iOS pre-configurado

### 🔔 1. Centro de notificaciones + emergentes en foreground
FCM solo cubre background/app cerrada; en foreground el WS entregaba las notificaciones a `wsNotificationsProvider` y NADIE las consumía. Ahora:

- **Banner emergente global** (`lib/widgets/common/in_app_notification_banner.dart`): montado sobre TODA la app vía `MaterialApp.router(builder:)` en main.dart. Escucha el WS, entra deslizando desde arriba, auto-cierra a los 5s, swipe-up descarta, tap navega vía route mapper. Color/icono según `tipo` (info/success/warning/error/message).
- **Centro de notificaciones** (`lib/screens/notificaciones_screen.dart`, ruta `/notificaciones`): **bandeja EFÍMERA espejo de la web** (decisión de producto): solo no-leídas, "marcar leída" ELIMINA en el servidor, y el Celery Beat del backend borra todo lo de >2 días. Lista con swipe→leída, botón "marcar todas" (con confirmación), pull-to-refresh, detalle en bottom sheet con botón "Abrir" si la URL mapea a ruta móvil.
- **Campanita con badge** de no-leídas en el AppBar del home (`home_screen.dart` → `_buildNotificationsBell`).
- **Provider** (`lib/providers/notificaciones_provider.dart`): carga REST inicial + prepend en vivo por WS + re-sync al reconectar el WS + markAsRead optimista. Registrado en SessionManager (limpieza en logout).
- **Modelo** (`lib/models/notificacion_model.dart`): parsea shape REST y shape WS (distintos). Filtro `esRuidoAutomatico` replica las exclusiones del backend ("Se ha registrado un nuevo ticket/VIN:") para que el WS no muestre lo que el REST oculta.
- **Route mapper compartido** (`lib/utils/notification_route_mapper.dart`): extraído de PushNotificationService, lo usan push FCM + banner + centro.

#### Backend (repo Django `Escritorio 2/django/core`, ⚠️ SIN commitear):
- `pushnotificacitons/views.py`: `get_notifications`, `mark_as_read`, `mark_all_as_read` convertidas a DRF `@api_view` + `IsAuthenticated` (antes `@login_required` solo-sesión → la app con JWT recibía redirect). La web sigue igual (SessionAuthentication + CSRF conviven, mismos paths y shapes). Campo aditivo `creado_en_iso` (la web usa `creado_en` timesince; la app formatea su propio tiempo relativo).

### 🔄 1b. Robustez del registro de token FCM (`push_notification_service.dart`)
- **`previous_token` en el POST**: el último token registrado con éxito se persiste en secure storage (`fcm_last_registered_token`); cuando getToken/onTokenRefresh devuelven uno distinto, viaja `previous_token` y el backend borra el Device viejo (anti-zombi). En logout NO se borra el persistido (a propósito: el siguiente login lo usa para limpiar).
- **Single-flight + dedupe por sesión**: getToken() y onTokenRefresh disparaban un doble POST al arranque (~1s de diferencia); ahora se serializan y un token ya registrado en la sesión no se re-postea. El dedupe se resetea en logout para que otro usuario en el mismo teléfono reasigne Device.user aunque el token no cambie.
- onTokenRefresh se cancela en logout y se re-arma en el siguiente registro; errores del listener capturados.
- Ya estaban desde antes (verificado): re-registro en login/arranque vía check-auth, `mobile: true`, `deleteToken()` en logout, deep-link con `data.route`.

### 🗑️ 1c. Eliminado registro legacy de equipos (decisión: solo flujo nuevo admin-v2)
- **Borrados de Flutter**: `device_registration_screen.dart` (pantalla completa con modos código-por-email y token), botón "Registrar equipo compartido" del footer del login, ruta `/device-registration` + sus redirects en el router, métodos `requestCode`/`registerWithCode`/`registerWithToken`/`backToRequestCode` y estados `awaitingCode`/`awaitingToken` del device_provider, clases `RequestCodeResult`/`RegisterDeviceResult` del device_service.
- **Se conserva**: `checkDevice()` → `GET api/v1/check-device/` (validación del device_id almacenado en el arranque), `markRegistered`, storage local del equipo, biométrico.
- Los equipos compartidos YA registrados siguen funcionando (sus filas `EquipoConfianza` con `is_global=True` pasan `is_device_valid`); lo que muere es la FORMA de registrar nuevos por token.
- ⚠️ **BACKEND (borrado planeado 2026-07-21)**: eliminar `device/request-code/` y `device/register/` de apis/urls.py + vistas en auth_views.py + sistema de tokens de registro. **NO borrar `check-device/`** (la app lo usa en cada arranque). Si a futuro se necesita registrar un equipo compartido nuevo, habrá que agregar el concepto "compartido/global" al flujo admin-v2 (hoy solo crea equipos personales).

### 🍎 2. FCM iOS pre-configurado (desde Windows, para la sesión en la Mac)
- **App iOS registrada en Firebase** `fcm-django-bd051` vía Management API con el service account del backend (script: scratchpad `register_ios_firebase.py`). AppId: `1:212704024550:ios:8384be3871ecce5b202827`
- `ios/Runner/GoogleService-Info.plist` descargado y **referenciado en project.pbxproj** (PBXFileReference + Resources build phase, UUIDs D5A1F00x...)
- `ios/Runner/Runner.entitlements` creado con `aps-environment = development` (Xcode lo cambia a production al exportar para App Store) + `CODE_SIGN_ENTITLEMENTS` en las 3 configs del target Runner
- El código Flutter ya toleraba iOS sin config; ahora con plist `Firebase.initializeApp()` funcionará

#### ⏳ PENDIENTE EN LA MAC (único paso que no se puede hacer desde Windows):
1. **Subir la clave APNs (.p8)** a Firebase Console → Project Settings → Cloud Messaging → app iOS (crear la clave en Apple Developer → Keys si no existe; team JZ4ZUD5L9A)
2. Al abrir el proyecto, Xcode con firma automática detectará el entitlement y agregará la capability Push Notifications al App ID
3. `flutter build ipa` y probar push en el iPhone 11 (con el backend ya desplegado)

### 📍 Estado
- ✅ `flutter analyze`: 0 errores, 0 warnings en el código de esta sesión. Quedan 31 `info` pre-existentes (`use_null_aware_elements`, lint nuevo del upgrade de Flutter) en archivos NO tocados — deuda menor.
- ✅ Versión **1.7.0+74**. Bundle generado: `build\app\outputs\bundle\release\app-release.aab` (73.9MB).
- ⏳ PENDIENTE deploy backend: los 2 commits FCM anteriores + el cambio de `pushnotificacitons/views.py` de esta sesión (sin commitear en el repo Django). Sin eso, la app recibe redirect/401 en `/notificaciones/`.
- ⏳ NO probado en dispositivo aún.
- 🧹 Disco: se liberó Temp de Windows y se **eliminó el AVD Pixel 9a (13GB)** — el testing es solo en dispositivos físicos, NO recrear emuladores. Estado final: **15GB libres** en C:. Si vuelve a faltar: `~/.gradle/caches` = 7.4GB (NUNCA borrarla con un build corriendo; modules-2 son 2.5GB re-descargables).

---

## ✅ COMPLETADO - SESIÓN 2026-07-21 (Mac) - iOS 1.7.0+74 listo para App Store + update forzado en iOS

### 🍎 Build iOS v1.7.0+74 (con FCM) validado y generado
- Flutter actualizado en esta Mac 3.38.7 → **3.44.7**; `pub get`, analyze y 32/32 tests OK
- **Deployment target iOS 13.0 → 15.0** (pbxproj x3 + Podfile): requisito de Firebase SDK 12 (firebase_messaging 16.x). Se pierden iPhone 6s/7/SE1 (iOS 13-14)
- **Migración a Swift Package Manager** (automática de Flutter 3.44): la mayoría de plugins ya no van por CocoaPods (Podfile.lock quedó casi vacío, aparecen `Package.resolved`); solo `flutter_secure_storage` sigue en pods. `AppFrameworkInfo.plist` ya no lleva MinimumOSVersion
- `analysis_options.yaml`: excluido `build/**` del analyzer — SPM descarga el FUENTE de los plugins ahí (examples/tests incluidos) y generaba 166 falsos errores
- Aplicado `dart fix` del lint nuevo `use_null_aware_elements` (31 casos, 9 archivos) → analyze en 0
- IPA: `build/ios/ipa/stampcamera.ipa` (28.6MB), firmado **Cloud Managed Apple Distribution** — el export CLI SÍ funciona ahora (Xcode 26 firma en la nube también desde `flutter build ipa`); Transporter u Organizer para subir
- OJO Organizer: los archives de `flutter build ipa` van a `build/ios/archive/Runner.xcarchive`, NO aparecen solos en Organizer — abrirlos con `open` para registrarlos

### 🔄 Actualización obligatoria ahora también en iOS
- `lib/services/update_service.dart` reescrito: Android sigue con In-App Updates de Play (intacto); iOS consulta iTunes lookup (`bundleId com.nestorfar.stampcamera`, store PE) al iniciar y al volver de background
- Si la versión instalada < versión publicada → **diálogo bloqueante** (PopScope canPop:false, sin dismiss) con única acción "Actualizar en App Store" (abre ficha id6791653349)
- Falla de red/timeout → silencioso, no bloquea (mismo criterio que Android). Comparación semver de `version`, no build number
- iTunes lookup puede tardar ~24h en reflejar una versión recién aprobada → el bloqueo se activa gradualmente tras cada release
- Wiring en `main.dart`: `UpdateService().initialize(navigatorKey: router.routerDelegate.navigatorKey)`

### 🧹 Limpieza de disco de esta Mac (estaba en 0 bytes, ahora ~8GB libres)
- Borrado: DerivedData (regenera ~4GB por build), iOS DeviceSupport 5.5GB (regenera al conectar iPhone), `~/.gradle/caches` 4.9GB, emulador Android + system-images + AVDs (~3GB), NDKs no usados 26.x/27.x/28.2 (8GB — el proyecto pinea 28.0.13004108, NO borrar esa)
- Candidatos restantes si falta espacio: Docker.raw 8GB reales (Docker Desktop colgado, pendiente), `com.apple.mediaanalysisd` 13GB (sistema, no tocar), Arduino15 9GB
- La subida a App Store falló el 20-jul por disco a 0 durante el zip de Transporter — con espacio libre funciona

### 📍 Estado
- ✅ IPA final (incluye update forzado) generado 21-jul 8:01, archive abierto en Organizer
- ⏳ Subir build 74 a App Store Connect (Organizer o Transporter) y enviar a revisión
- ✅ Clave APNs subida a Firebase (2026-07-21): Key ID `S27GY237NV`, team `JZ4ZUD5L9A`, en filas desarrollo Y producción de `fcm-django-bd051` → app `com.nestorfar.stampcamera`. El `.p8` lo guarda Nestor (no está en ningún repo). Push Android (S22) confirmado funcionando end-to-end
- ⏳ Probar en TestFlight: login con aprobación de equipo, push con app cerrada, tap→navegación

---

## 🔍 SESIÓN 2026-07-21 (Windows) - Skills + revisión de arquitectura + plan P0/P1/P2

### 🧰 Skills de agentes instaladas
- `npx skills add` de `flutter/agent-plugins`, `dart-lang/skills` y `flutter/skills` → 22 SKILL.md en `.agents/skills/` (commiteado junto con `skills-lock.json`)
- Revisadas: contenido benigno (solo documentación, sin scripts). Los flags "Critical/High Risk" del scanner son falsos positivos (docs de FFI que describen descargas de binarios y del package http)
- ⚠️ Duplicadas con `.claude/skills/` de una instalación anterior — a futuro consolidar en UNA sola ruta
- ⚠️ `flutter-use-http-package` enseña `package:http` + FutureBuilder; este proyecto usa **dio (http_service) + Riverpod** — no seguir esa skill aquí

### 🏠 Home: AppBar limpiado
- Eliminado botón de configuración del AppBar + `_showSettingsDialog` + `_showAboutDialog` (modal sin utilidad real, -156 líneas)
- Campana de notificaciones: era icono `AppColors.primary` en chip navy 10% sobre AppBar navy (0xFF003B5C sobre sí mismo = invisible). Ahora `IconButton` plano que hereda el foreground blanco del tema; badge rojo intacto

### 📋 REVISIÓN DE ARQUITECTURA (agente Opus, solo lectura) — salud 6.5/10
Funcional sano (analyze 0, natives post-merge iOS coherentes, timers/subs bien liberados, sin más casos navy-sobre-navy). Deuda en estructura y correctitud de datos.

#### Cambios propuestos — P0 (correctitud, ESTA sesión)
1. **Fuga de datos entre usuarios en logout**: `SessionManager._clearAllUserRelatedProviders` no invalida 7 providers sin autoDispose que cachean datos de usuario:
   - `registroVinListProvider` + `usuariosRegistradoresProvider` (autos/registro_vin_list_provider.dart)
   - `registrosConDanosProvider` + `registrosPedeteadosProvider` (autos/registro_general_provider.dart)
   - `paralizacionesListProvider` + `controlHumedadListProvider` (graneles/graneles_provider.dart) — OJO: el reporte del agente los llamó `paralizacionesProvider`/`controlHumedadProvider`, los nombres reales llevan `List`
   - `exploradorProvider` (casos/explorador_provider.dart) — además mantiene viva la suscripción WS del canal `casos` y un `_currentUserId` stale (atribución de subidas)
   → Fix: registrarlos en `_clearAllUserRelatedProviders`; los de trabajo diario (registroVinList, conDanos, pedeteados, paralizaciones, controlHumedad) también en `onStartAssistance`/`onEndAssistance`
2. **6 botones a rutas muertas en graneles** (no hay errorBuilder → pantalla de error go_router):
   - `almacen_tab.dart:93,203` FAB/botón "crear" y `:156` editar → `/graneles/almacen/*` NO existe. Fix: quitar FAB y botón crear (el alta real es vía ViajeFormScreen desde el tab Viajes); quitar editar (AlmacenGranel NO tiene ticketId para deep-link)
   - `balanzas_tab.dart:108,253` crear y `:182` editar → `/graneles/balanza/*` NO existe. Fix: quitar crear; editar SÍ se puede salvar → `/graneles/viaje/editar/{balanza.ticketId}?step=2` (Balanza tiene ticketId; step 1=muelle, 2=balanza, 3=almacén)

#### Cambios propuestos — P1 (sesión "design system")
- Unificar las dos carpetas `common` (`core/widgets/common` vs `widgets/common`) con regla clara
- Matar dropdown duplicado: `custom_dropdown_field` (solo lo usa pedeteo/form_fields_card) → migrar a `app_search_select` del core
- Renombrar `widgets/pedeteo/search_bar_widget.dart` → `pedeteo_search_bar.dart` (colisión de nombre con el común)
- Sweep de literales `Color(0xFF…)` → tokens: dano_form.dart (43), jornadas_screen.dart (19), fotos_presentacion_form.dart (14), detalle_danos.dart (13 — el "✅ migrado" de arriba en este archivo es FALSO), registro_asistencia_screen.dart (10), modal_entrada.dart (9)
- Agregar `errorBuilder` al GoRouter (que una ruta rota nunca más sea pantalla blanca de error cruda)

#### Cambios propuestos — P2 (higiene, cuando toque)
- Borrar código muerto: `core/widgets/app_bars/app_corporate_bar.dart`, `widgets/connectivity_app_bar.dart` (0 usos)
- Borrar `lib/features/` vacía o arrancar el piloto de migración con UN módulo (casos)
- Mover `lib/models/autos/Manual-API.md` y `lib/services/http_service.md` a `docs/`
- Package Kotlin `com.example.stampcamera` ≠ applicationId `com.nestorfar.stampcamera` (funciona; renombrar con calma)
- Testing (5 áreas de mayor retorno): SessionManager/logout, http_service refresh + colas offline, `canAccess()`, backoff de queue_service, parsers fromJson (notificacion doble shape, permisos, login_flow)

### ✅ P0 APLICADO (esta sesión)
1. **SessionManager**: los 7 providers registrados en `_clearAllUserRelatedProviders`; los 5 de trabajo diario también en `onStartAssistance`/`onEndAssistance`. `exploradorProvider` con nota: invalidar dispone el notifier → cancela WS del canal casos y descarta el userId stale
2. **almacen_tab**: FAB "Nuevo Almacén", botón "Crear primer registro" y lápiz de editar ELIMINADOS (el flujo real es ViajeFormScreen); parámetro `onEdit` de `_AlmacenCard` removido; padding inferior del ListView ahora usa `MediaQuery.padding.bottom` (antes +80 fijo para el FAB)
3. **balanzas_tab**: FAB y "Crear primera balanza" eliminados; **editar SÍ se conservó** → `/graneles/viaje/editar/{ticketId}?step=2` (guard: `canEdit && ticketId != null`); mismo ajuste de padding

### 🎨 UI extra (misma sesión, pedidos del usuario probando en S22)
- Home: whitelist de módulos implementados (`camera/asistencia/autos/graneles`) — fuera cards grises de módulos no implementados y el diálogo "Próximamente"
- Solicitudes de equipos: rediseñada con el shell canónico (`_CardShell`: blanco + sombra + strip 4px en color de estado + icono en chip); buscador "Aprobar por código"
- App renombrada a **"AYG APP"** en Android (`android:label`, estaba escapado como `A&amp;G`) e iOS (`CFBundleDisplayName`, decía "Stampcamera"). Razón social A&G en textos legales NO se tocó

### 🍎 Push iOS desbloqueado (lado servidor completo)
- Clave APNs creada y subida a Firebase (Key ID `S27GY237NV`, team `JZ4ZUD5L9A`, dev+prod). Android confirmado end-to-end en S22
- ⚠️ **Xcode Cloud tiene un workflow conectado al repo que falla en cada push** (no sabe compilar Flutter sin `ci_scripts/ci_post_clone.sh`) → correos de error por push. PENDIENTE decidir: desactivarlo en App Store Connect o configurarlo para Flutter

### 📍 Estado
- ✅ Versión **1.7.1+76**. Bundle Android: `build\app\outputs\bundle\release\app-release.aab` (73.9MB) listo para Play Console
- ✅ `flutter analyze`: 0 issues. Todo pusheado a origin/main
- ✅ Probado en S22: campana, sin cards grises, rediseño equipos, "AYG APP"
- ⏳ MAC: `git pull` → `flutter build ipa --release` → Organizer → TestFlight con archive **1.7.1 (76)** (borrar el archive viejo 74 del Organizer). Luego en iPhone: TestFlight → login → aceptar notificaciones → probar push con app cerrada
- ⏳ Probar en dispositivo: logout entre 2 usuarios (datos limpios), tabs balanzas/almacén de graneles
- ⏳ Próximas sesiones: P1 (design system) y P2 (higiene/testing) según plan de arriba
