# Propuesta de ThemeData mejorado

Se revisó todo el contenido de `lib/` para identificar patrones de UI y unificar la apariencia de la aplicación. Se creó un nuevo `ThemeData` en `lib/theme/app_theme.dart` que usa los colores corporativos definidos en `AppColors` y estandariza tipografías, botones y campos de texto.

## Puntos clave
- Se activa `useMaterial3` para aprovechar los últimos componentes.
- Se define un `ColorScheme` completo con `AppColors` para mantener coherencia de colores.
- Se agregan estilos predeterminados para `AppBar`, `TextTheme`, `ElevatedButton` e `InputDecoration`.
- El `scaffoldBackgroundColor` ahora usa `AppColors.backgroundLight`.

## APIs obsoletas
No se encontró uso de `withOpacity` o APIs marcadas como obsoletas. La mayoría de los widgets usan el nuevo método `Color.withValues`. Si en el futuro aparece código con `withOpacity`, se sugiere migrar a `withValues(alpha: …)` para mantener consistencia con el resto del proyecto.
