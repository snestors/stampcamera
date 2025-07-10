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

## 🏠 **CONTINUAR DESDE CASA**

### **📍 Estado Actual - FUNCIONAL CON ISSUES**
El proyecto está **funcional** con mejoras implementadas:
- ✅ `flutter analyze` - **0 issues**
- ✅ Sistema de limpieza de providers completamente implementado  
- ✅ Todas las dependencias críticas actualizadas
- ✅ Código sin warnings ni errores
- ✅ **Fix dropdown asistencia** - Agregados equals/hashCode a ZonaTrabajo/Nave
- ✅ **Fix limpieza pedeteo** - Agregados todos los providers de pedeteo al SessionManager
- ✅ **Mejoras UI Design System** - Iconos más grandes, imágenes más grandes, AppCard.soft() con fondo suave

### **🎯 Próximos Pasos Prioritarios (En Casa)**

#### **1. 🧪 Testing del Sistema AppSearchSelect - CRÍTICO**
```bash
# Probar que la app ejecuta sin errores
flutter run

# Testing manual prioritario:
1. **AppSearchSelect** - Verificar nueva funcionalidad
   - Abrir formulario de daños → usar Tipo de Daño y Área de Daño
   - Escribir para buscar → verificar filtrado en tiempo real
   - Seleccionar opciones → verificar que se actualiza correctamente
   - Tocar afuera → verificar que se cierra el overlay
   - Cerrar formulario → verificar que no hay crashes

2. **Dropdowns Estandarizados** - Verificar estilos consistentes
   - Probar Condición, Severidad, Responsabilidad, Documento
   - Verificar que todos tienen el mismo estilo visual
   - Confirmar fuentes pequeñas y bordes redondeados
```

#### **2. 🧪 Testing del Sistema de Providers - CRÍTICO**
```bash
# Testing manual prioritario:
1. **Login/Logout** - Verificar que clearSession() funciona
   - Hacer login → trabajar un rato → logout
   - Verificar que no quedan datos del usuario anterior
   
2. **Inicio/Fin de Asistencia** - Verificar hooks funcionan  
   - Marcar entrada → verificar onStartAssistance()
   - Marcar salida → verificar onEndAssistance()
   - Confirmar que se limpian solo los datos apropiados

3. **Cambio de Usuario** - Verificar limpieza entre usuarios
   - Login Usuario A → trabajar → logout → login Usuario B
   - Confirmar que B no ve datos de A
```

#### **3. 🧭 Testing Navegación go_router 16.0.0**
- Probar todas las rutas principales de la app
- Verificar navegación entre pantallas funciona
- Buscar posibles breaking changes

#### **4. 📱 Testing Funcionalidades Críticas**
- **Cámara** - Tomar fotos, galería
- **GPS** - Ubicación en asistencia
- **Permisos** - Verificar que se piden correctamente

### **🚀 Comando para Empezar en Casa**
```bash
cd "C:\Users\Nestor\Desktop\Flutter\stampcamera"
claude-code .
```

**Decir a Claude:** "Revisa CLAUDE.md. He implementado AppSearchSelect con búsqueda como en la web y estandarizado todos los dropdowns. Necesito hacer testing del nuevo sistema de búsqueda y verificar que todo funciona correctamente. ¿Por dónde empezamos?"

### **📝 Si Encuentras Problemas**
1. **Error AppSearchSelect** → Revisar `lib/core/widgets/common/app_search_select.dart`
2. **Crash al cerrar formulario** → Verificar checks de `mounted` en overlay methods
3. **Error de providers** → Revisar SessionManager en `lib/providers/session_manager_provider.dart`
4. **Error de navegación** → Verificar rutas en go_router 16.0.0
5. **Error de dependencias** → Ejecutar `flutter pub get`

### **✅ Lo que NO necesitas hacer**
- ❌ Corregir warnings (ya están todos eliminados)
- ❌ Actualizar dependencias (ya están actualizadas)  
- ❌ Implementar sistema de providers (ya está completo)
- ❌ Crear AppSearchSelect (ya está implementado y funcionando)

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
- **Flutter**: 3.x+
- **Dart**: 3.x+
- **flutter_riverpod**: ^2.x
- **go_router**: Para navegación

---

*Archivo generado automáticamente por Claude Code*
*Última actualización: 2025-07-10 - ✅ APPSEARCHSELECT IMPLEMENTADO Y DROPDOWNS ESTANDARIZADOS*