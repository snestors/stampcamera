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