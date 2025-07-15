# Instrucciones para Claude Code: Integrar Paleta de Colores

## Objetivo
Integrar una paleta de colores personalizada con soporte para tema claro y oscuro en un proyecto Flutter existente, basada en los colores: #001C26, #004D6B, #BEDBE1, #008B8B, #FFAF1D, #FF6800.

## Pasos a seguir:

### 1. Crear archivo de colores
Crear un archivo `lib/theme/app_colors.dart` con esta estructura:

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color deepBlue = Color(0xFF001C26);
  static const Color mediumBlue = Color(0xFF004D6B);
  static const Color lightBlue = Color(0xFFBEDBE1);
  static const Color teal = Color(0xFF008B8B);
  static const Color amber = Color(0xFFFFAF1D);
  static const Color orange = Color(0xFFFF6800);
  
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF2C2C2C);
}
```

### 2. Crear archivo de temas
Crear un archivo `lib/theme/app_theme.dart` que defina:

- `lightTheme`: Tema claro usando mediumBlue como primario, lightBlue para containers, teal para secondary
- `darkTheme`: Tema oscuro usando deepBlue como background, lightBlue como primario, teal para acentos
- Configurar AppBarTheme, ElevatedButtonTheme, CardTheme para ambos temas

### 3. Modificar main.dart
En el archivo `main.dart` existente:

- Importar `app_theme.dart`
- En MaterialApp, agregar:
  ```dart
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
  ```

### 4. Crear widget de cambio de tema (opcional)
Si se quiere control manual del tema, crear un StateManager o Provider para manejar el cambio entre claro/oscuro.

### 5. Actualizar widgets existentes
- Revisar widgets existentes que usen colores hardcodeados
- Reemplazar con `Theme.of(context).colorScheme.primary` o colores de AppColors
- Asegurar que el contraste sea correcto en ambos temas

## Colores asignados por función:

### Tema Claro:
- **Primary**: mediumBlue (#004D6B)
- **Secondary**: teal (#008B8B) 
- **Tertiary**: amber (#FFAF1D)
- **Error**: orange (#FF6800)
- **Background**: lightGray (#F5F5F5)
- **Surface**: white

### Tema Oscuro:
- **Background**: deepBlue (#001C26)
- **Primary**: lightBlue (#BEDBE1)
- **Secondary**: teal (#008B8B)
- **Surface**: derivado de deepBlue
- **Error**: versión suave de orange

## Notas importantes:
- Mantener la estructura existente del proyecto
- No cambiar navegación ni funcionalidad actual
- Solo integrar el sistema de colores
- Probar que los contrastes sean accesibles
- Verificar que funcione en ambos temas

## Resultado esperado:
Una aplicación que use consistentemente la paleta de colores definida, con soporte automático para tema claro/oscuro según preferencias del sistema, manteniendo toda la funcionalidad existente intacta.



NOTAS CRITICAS DE LOS USUARIOS DEVELOPERS. FALTA CORRGERIR BOTONES  EN ASISTENCIAS NO SE ESTA BLOQUEANDO. SECCION PEDETEO MEJORAR EL MENSAJE DE ERROR Y COLOCAR UN BOTON PARA ACTUALIZAR. LA VISTA..
