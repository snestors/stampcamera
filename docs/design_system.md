# 🎨 Sistema de Diseño StampCamera

## Introducción

El sistema de diseño de StampCamera proporciona una base sólida y consistente para el desarrollo de la aplicación de inspección vehicular. Este documento describe la arquitectura, componentes y mejores prácticas para mantener una experiencia de usuario uniforme.

## 📁 Estructura del Sistema

### Estructura de Directorios

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart          # Colores corporativos
│   │   └── design_tokens.dart       # Tokens de diseño
│   ├── helpers/
│   │   ├── validators/
│   │   │   ├── form_validators.dart # Validadores de formularios
│   │   │   └── business_validators.dart # Validadores de negocio
│   │   ├── formatters/
│   │   │   ├── date_formatters.dart # Formateo de fechas
│   │   │   └── text_formatters.dart # Formateo de texto
│   │   └── ui_helpers/
│   │       └── vehicle_helpers.dart # Helpers para vehículos
│   ├── widgets/
│   │   ├── buttons/
│   │   │   └── app_button.dart      # Botones estándar
│   │   ├── forms/
│   │   │   └── app_text_field.dart  # Campos de texto
│   │   └── common/
│   │       ├── app_loading_state.dart # Estados de carga
│   │       └── app_error_state.dart # Estados de error
│   └── core.dart                    # Punto de entrada unificado
```

## 🎨 Colores Corporativos

### Colores Principales

```dart
// Colores corporativos
AppColors.primary      // #003B5C - Azul oscuro corporativo
AppColors.secondary    // #00B4D8 - Azul claro corporativo
AppColors.accent       // #059669 - Verde corporativo

// Estados
AppColors.success      // #059669 - Verde éxito
AppColors.warning      // #F59E0B - Naranja warning
AppColors.error        // #DC2626 - Rojo error
AppColors.info         // #00B4D8 - Azul info
```

### Colores de Texto

```dart
AppColors.textPrimary      // #1F2937 - Texto principal
AppColors.textSecondary    // #6B7280 - Texto secundario
AppColors.textLight        // #9CA3AF - Texto claro
```

### Colores de Condición (Específicos del Negocio)

```dart
AppColors.puerto       // #00B4D8 - Puerto
AppColors.recepcion    // #8B5CF6 - Recepción
AppColors.almacen      // #059669 - Almacén
AppColors.pdi          // #F59E0B - PDI
AppColors.prePdi       // #EF4444 - Pre-PDI
AppColors.arribo       // #0EA5E9 - Arribo
```

## 📏 Design Tokens

### Espaciado

```dart
DesignTokens.spaceXS     // 4px
DesignTokens.spaceS      // 8px
DesignTokens.spaceM      // 12px
DesignTokens.spaceL      // 16px
DesignTokens.spaceXL     // 20px
DesignTokens.spaceXXL    // 24px
DesignTokens.spaceXXXL   // 32px
```

### Tipografía

```dart
DesignTokens.fontSizeXXL    // 32px - Títulos principales
DesignTokens.fontSizeXL     // 28px - Títulos de sección
DesignTokens.fontSizeL      // 24px - Títulos de card
DesignTokens.fontSizeM      // 20px - Subtítulos
DesignTokens.fontSizeRegular // 16px - Texto normal
DesignTokens.fontSizeS      // 14px - Texto pequeño
DesignTokens.fontSizeXS     // 12px - Captions
```

### Border Radius

```dart
DesignTokens.radiusS     // 6px
DesignTokens.radiusM     // 8px
DesignTokens.radiusL     // 12px
DesignTokens.radiusXL    // 16px
DesignTokens.radiusXXL   // 20px
```

## 🔘 Componentes

### AppButton

Botón estándar con múltiples variantes y tamaños.

```dart
// Botón primario
AppButton.primary(
  text: 'Guardar',
  onPressed: () {},
  icon: Icons.save,
)

// Botón secundario
AppButton.secondary(
  text: 'Cancelar',
  onPressed: () {},
)

// Botón de error
AppButton.error(
  text: 'Eliminar',
  onPressed: () {},
  icon: Icons.delete,
)
```

**Variantes disponibles:**
- `primary` - Botón principal
- `secondary` - Botón secundario  
- `success` - Botón de éxito
- `warning` - Botón de advertencia
- `error` - Botón de error
- `ghost` - Botón transparente

**Tamaños disponibles:**
- `small` - 32px altura
- `medium` - 40px altura (por defecto)
- `large` - 48px altura
- `extraLarge` - 56px altura

### AppTextField

Campo de texto estándar con validación integrada.

```dart
// Campo de texto básico
AppTextField(
  label: 'Nombre',
  hint: 'Ingresa tu nombre',
  validator: FormValidators.validateRequired,
)

// Campo de email
AppTextField.email(
  label: 'Email',
  controller: emailController,
  validator: FormValidators.validateEmail,
)

// Campo de contraseña
AppTextField.password(
  label: 'Contraseña',
  controller: passwordController,
  canToggleObscureText: true,
)
```

### AppLoadingState

Estados de carga unificados.

```dart
// Loading circular
AppLoadingState.circular(
  message: 'Cargando datos...',
)

// Loading lineal
AppLoadingState.linear(
  message: 'Procesando...',
)

// Loading skeleton
AppLoadingState.skeleton()
```

### AppErrorState

Estados de error unificados.

```dart
// Error de red
AppErrorState.network(
  onRetry: () => _retry(),
)

// Error del servidor
AppErrorState.server(
  message: 'Error del servidor',
  onRetry: () => _retry(),
)

// Error personalizado
AppErrorState(
  type: AppErrorType.validation,
  title: 'Datos inválidos',
  message: 'Revisa los campos marcados',
  onRetry: () => _validateForm(),
)
```

### AppCard

Tarjeta estándar para contenedores de contenido.

```dart
// Tarjeta básica
AppCard(
  child: Column(
    children: [
      Text('Contenido'),
    ],
  ),
)

// Tarjeta elevada
AppCard.elevated(
  title: 'Título de la tarjeta',
  subtitle: 'Subtítulo opcional',
  leading: Icon(Icons.info),
  trailing: Icon(Icons.arrow_forward),
  child: Text('Contenido principal'),
  onTap: () => _onCardTap(),
)

// Tarjeta con borde
AppCard.outlined(
  title: 'Tarjeta con borde',
  borderColor: AppColors.primary,
  child: Text('Contenido'),
)

// Tarjeta rellena
AppCard.filled(
  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
  child: Text('Contenido'),
)
```

**Variantes disponibles:**
- `basic` - Tarjeta simple sin elevación
- `elevated` - Tarjeta con sombra (por defecto)
- `outlined` - Tarjeta con borde
- `filled` - Tarjeta con color de fondo

**Tamaños disponibles:**
- `small` - Padding 12px, margin 4px
- `medium` - Padding 16px, margin 8px (por defecto)
- `large` - Padding 20px, margin 12px

**Estados:**
- `isSelected` - Estado seleccionado
- `isDisabled` - Estado deshabilitado
- `onTap` - Interactividad opcional

### AppInfoCard

Tarjeta especializada para mostrar información.

```dart
AppInfoCard(
  title: 'Título principal',
  subtitle: 'Subtítulo',
  description: 'Descripción detallada',
  icon: Icons.info,
  iconColor: AppColors.primary,
  onTap: () => _showDetails(),
)
```

## 🛠️ Helpers

### FormValidators

Validadores estándar para formularios.

```dart
// Validación de VIN
FormValidators.validateVin(value)

// Validación de email
FormValidators.validateEmail(value)

// Validación requerida
FormValidators.validateRequired(value, fieldName: 'Nombre')

// Validación de números
FormValidators.validateNumber(value)

// Validación de teléfono
FormValidators.validatePhone(value)
```

### BusinessValidators

Validadores específicos del negocio.

```dart
// Validación de condición de inspección
BusinessValidators.validateInspectionCondition(value)

// Validación de marca de vehículo
BusinessValidators.validateVehicleBrand(value)

// Validación de severidad de daño
BusinessValidators.validateSeverity(value)
```

### DateFormatters

Formateo de fechas y horas.

```dart
// Formato completo
DateFormatters.toFullFormat(DateTime.now())
// "28/06/2025 15:30"

// Solo fecha
DateFormatters.toDateFormat(DateTime.now())
// "28/06/2025"

// Solo hora
DateFormatters.toTimeFormat(DateTime.now())
// "15:30"

// Formato relativo
DateFormatters.toRelativeFormat(DateTime.now())
// "Hace 5 minutos"
```

### TextFormatters

Formateo de texto y strings.

```dart
// Formatear VIN
TextFormatters.formatVin("abc123def456")
// "ABC123DEF456"

// Formatear nombre
TextFormatters.formatPersonName("JUAN CARLOS pérez")
// "Juan Carlos Pérez"

// Formatear teléfono
TextFormatters.formatPeruvianPhone("987654321")
// "+51 987 654 321"
```

### VehicleHelpers

Helpers específicos para vehículos.

```dart
// Obtener color por condición
VehicleHelpers.getCondicionColor('PUERTO')
// Color(0xFF00B4D8)

// Obtener icono por condición
VehicleHelpers.getCondicionIcon('ALMACEN')
// Icons.warehouse

// Verificar si requiere contenedor
VehicleHelpers.requiresContainer('ALMACEN')
// true
```

## 📋 Guía de Uso

### Importación

```dart
// Importar todo el sistema
import 'package:stampcamera/core/core.dart';

// O importar componentes específicos
import 'package:stampcamera/core/theme/app_colors.dart';
import 'package:stampcamera/core/widgets/buttons/app_button.dart';
```

### Mejores Prácticas

#### 1. Usar Colores Corporativos

```dart
// ✅ Correcto
Container(
  color: AppColors.primary,
  child: Text(
    'Texto',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// ❌ Incorrecto
Container(
  color: Color(0xFF003B5C), // Hardcoded
  child: Text(
    'Texto',
    style: TextStyle(color: Colors.black),
  ),
)
```

#### 2. Usar Design Tokens

```dart
// ✅ Correcto
Padding(
  padding: EdgeInsets.all(DesignTokens.spaceL),
  child: Text(
    'Texto',
    style: DesignTokens.getTextStyle('l'),
  ),
)

// ❌ Incorrecto
Padding(
  padding: EdgeInsets.all(16.0), // Hardcoded
  child: Text(
    'Texto',
    style: TextStyle(fontSize: 24), // Hardcoded
  ),
)
```

#### 3. Usar Componentes Estándar

```dart
// ✅ Correcto
AppButton.primary(
  text: 'Guardar',
  onPressed: _save,
)

// ❌ Incorrecto
ElevatedButton(
  onPressed: _save,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    // Estilos manuales...
  ),
  child: Text('Guardar'),
)
```

#### 4. Usar Validadores Centralizados

```dart
// ✅ Correcto
AppTextField(
  validator: FormValidators.validateVin,
)

// ❌ Incorrecto
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Campo requerido';
    }
    // Validación manual...
  },
)
```

## 🔄 Migración

### Pasos para Migrar Widgets Existentes

1. **Identificar componentes similares**
   ```dart
   // Antes
   ElevatedButton(...)
   
   // Después
   AppButton.primary(...)
   ```

2. **Reemplazar colores hardcodeados**
   ```dart
   // Antes
   Color(0xFF003B5C)
   
   // Después
   AppColors.primary
   ```

3. **Usar design tokens**
   ```dart
   // Antes
   fontSize: 16.0
   
   // Después
   DesignTokens.fontSizeRegular
   ```

4. **Aplicar validadores**
   ```dart
   // Antes
   validator: (value) => value?.isEmpty == true ? 'Requerido' : null
   
   // Después
   validator: FormValidators.validateRequired
   ```

## 📱 Responsive Design

### Breakpoints

```dart
DesignTokens.breakpointMobile   // 576px
DesignTokens.breakpointTablet   // 768px
DesignTokens.breakpointDesktop  // 992px
```

### Helpers Responsive

```dart
// Verificar dispositivo
if (DesignTokens.isMobile(context)) {
  // Layout móvil
} else if (DesignTokens.isTablet(context)) {
  // Layout tablet
} else {
  // Layout desktop
}
```

## 🔄 Actualizaciones Recientes

### v1.1.0 - Julio 2025

#### ✅ **Correcciones implementadas:**
- **Métodos deprecados**: Todos los `withOpacity()` actualizados a `withValues(alpha: value)`
- **BuildContext async**: Agregadas protecciones `context.mounted` en operaciones async
- **Constantes**: `neutral_semantic` → `neutralSemantic` (lowerCamelCase)
- **Login migrado**: `login_screen.dart` completamente migrado al sistema de diseño

#### 🚀 **Pantallas migradas:**
- ✅ `login_screen.dart` - Completamente migrado con todos los componentes del sistema

#### 🛠️ **Componentes utilizados:**
- `AppTextField` y `AppTextField.password`
- `AppButton.primary` y `AppButton.secondary`
- `AppInlineError` para mensajes de error
- `AppColors.*` para toda la paleta de colores
- `DesignTokens.*` para espaciado y tipografía

## 🎯 Próximos Pasos

### 📋 **Migración de Pantallas (Prioridad Alta)**

1. **Pantallas de Autos** (`/screens/autos/`)
   - `autos_screen.dart` - Pantalla principal
   - `inventario_screen.dart` - Lista de inventario
   - `pedeteo_screen.dart` - Registro de vehículos
   - `detalle_registro_screen.dart` - Detalles de registro

2. **Pantallas de Contenedores** (`/screens/autos/contenedores/`)
   - `contenedores_tab.dart` - Tab de contenedores
   - `contenedor_form.dart` - Formulario de contenedor

3. **Pantallas de Inventario** (`/screens/autos/inventario/`)
   - `inventario_detalle_screen.dart` - Detalles de inventario
   - `inventario_detalle_nave_screen.dart` - Detalles por nave

4. **Pantallas Generales**
   - `home_screen.dart` - Pantalla principal
   - `splash_screen.dart` - Pantalla de carga
   - `registro_asistencia_screen.dart` - Registro de asistencia

### 🧩 **Componentes Faltantes (Prioridad Media)**

1. ✅ **AppCard** - Para contenedores de contenido *(Implementado)*
   ```dart
   AppCard.elevated(
     title: 'Título',
     child: Column(...),
     onTap: () {},
   )
   ```

2. **AppModal** - Para diálogos y modales
   ```dart
   AppModal.alert(
     title: 'Título',
     content: 'Contenido',
     actions: [...]
   )
   ```

3. **AppDropdown** - Para selectores
   ```dart
   AppDropdown<String>(
     items: items,
     onChanged: (value) {},
     label: 'Seleccionar',
   )
   ```

4. **AppChip** - Para etiquetas y filtros
   ```dart
   AppChip(
     label: 'Etiqueta',
     onPressed: () {},
     color: AppColors.primary,
   )
   ```

### 🎨 **Mejoras del Sistema (Prioridad Baja)**

1. **Modo oscuro completo** - Implementar tema oscuro
2. **Más validadores** - Agregar validadores específicos del negocio
3. **Animaciones** - Transiciones consistentes
4. **Storybook** - Documentación interactiva de componentes

## 📋 Instrucciones para Migrar Pantallas

### 1. **Preparación**
```dart
// Agregar import del sistema de diseño
import 'package:stampcamera/core/core.dart';
```

### 2. **Colores**
```dart
// ❌ Antes
Container(color: Color(0xFF003B5C))

// ✅ Después  
Container(color: AppColors.primary)
```

### 3. **Componentes**
```dart
// ❌ Antes
TextFormField(...)

// ✅ Después
AppTextField(
  label: 'Campo',
  validator: FormValidators.validateRequired,
)
```

### 4. **Espaciado y Tipografía**
```dart
// ❌ Antes
EdgeInsets.all(16.0)
TextStyle(fontSize: 24)

// ✅ Después
EdgeInsets.all(DesignTokens.spaceL)
TextStyle(fontSize: DesignTokens.fontSizeXL)
```

### 5. **Errores y Estados**
```dart
// ❌ Antes
Text('Error', style: TextStyle(color: Colors.red))

// ✅ Después
AppInlineError(
  message: 'Error',
  dismissible: true,
)
```

### 6. **Métodos Deprecados**
```dart
// ❌ Antes
color.withOpacity(0.5)

// ✅ Después
color.withValues(alpha: 0.5)
```

### 7. **BuildContext en Async**
```dart
// ❌ Antes
Future<void> method() async {
  await something();
  ScaffoldMessenger.of(context).showSnackBar(...);
}

// ✅ Después
Future<void> method() async {
  await something();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

## 📞 Soporte

Para dudas o mejoras al sistema de diseño:
- Revisar este documento
- Consultar ejemplos en `login_screen.dart` (migrado)
- Verificar implementaciones en `/core/widgets/`
- Seguir las instrucciones de migración arriba

---

**Versión del Sistema:** 1.1.0  
**Última Actualización:** 09/07/2025