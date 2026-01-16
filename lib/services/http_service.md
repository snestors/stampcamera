# Manual Completo: HttpService con Soporte Offline en Flutter

## 📋 Índice

1. [Arquitectura General](#arquitectura-general)
2. [Componentes Principales](#componentes-principales)
3. [Configuración Inicial](#configuración-inicial)
4. [Uso en Providers](#uso-en-providers)
5. [Uso en Widgets](#uso-en-widgets)
6. [Casos de Uso Comunes](#casos-de-uso-comunes)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## 🏗️ Arquitectura General

### Stack Tecnológico

- **Flutter**: Framework principal
- **Riverpod**: State management
- **Dio**: HTTP client
- **connectivity_plus**: Detección de conectividad
- **flutter_secure_storage**: Persistencia segura

### Flujo de Datos

```
UI → Provider → HttpService → Backend API
 ↕      ↕           ↕
ConnectivityProvider ← → Storage
```

---

## 🧩 Componentes Principales

### 1. HttpService

**Ubicación**: `lib/services/http_service.dart`

Singleton que maneja:

- Requests HTTP con Dio
- Refresh automático de tokens JWT
- Interceptores para autenticación
- Manejo inteligente de errores de conectividad

### 2. ConnectivityProvider

**Ubicación**: `lib/providers/simple_connectivity_provider.dart`

StateNotifier que:

- Detecta conectividad del dispositivo
- Provee estado en tiempo real
- Permite verificación manual

### 3. AuthProvider

**Ubicación**: `lib/providers/auth_provider.dart`

StateNotifier que:

- Maneja autenticación JWT
- Persiste estado de usuario
- Mantiene sesión offline
- Distingue errores de red vs autenticación

### 4. ConnectivityAppBar

**Ubicación**: `lib/widgets/connectivity_app_bar.dart`

Widget que:

- Muestra indicador visual de conectividad
- Reemplaza AppBar estándar
- Proporciona feedback inmediato al usuario

---

## ⚙️ Configuración Inicial

### 1. Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  connectivity_plus: ^6.0.5
  go_router: ^13.0.0
```

### 2. Estructura de Archivos

```
lib/
├── models/
│   ├── auth_state.dart
│   └── user_model.dart
├── providers/
│   ├── auth_provider.dart
│   └── simple_connectivity_provider.dart
├── services/
│   └── http_service.dart
├── widgets/
│   └── connectivity_app_bar.dart
└── main.dart
```

### 3. Inicialización en main.dart

```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tu App',
      routerConfig: router,
      theme: yourTheme,
    );
  }
}
```

---

## 🔄 Uso en Providers

### 1. Provider Básico con Conectividad

```dart
final dataProvider = AsyncNotifierProvider<DataNotifier, List<Item>>(
  DataNotifier.new,
);

class DataNotifier extends AsyncNotifier<List<Item>> {
  final _http = HttpService();

  @override
  Future<List<Item>> build() async {
    ref.keepAlive(); // Mantener datos en cache
    return await _loadData();
  }

  Future<List<Item>> _loadData() async {
    try {
      final response = await _http.dio.get('/api/v1/items/');
      return (response.data['results'] as List)
          .map((e) => Item.fromJson(e))
          .toList();
    } catch (e) {
      // El HttpService ya maneja conectividad
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _loadData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addItem(Item item) async {
    try {
      await _http.dio.post('/api/v1/items/', data: item.toJson());
      await refresh(); // Actualizar lista
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### 2. Provider con Verificación de Conectividad

```dart
class DataNotifierWithConnectivity extends AsyncNotifier<List<Item>> {
  final _http = HttpService();

  Future<bool> addItemSafe(Item item) async {
    // Verificar conectividad antes de hacer request
    final canMakeRequest = ref.read(canMakeRequestsProvider);

    if (!canMakeRequest) {
      // Mostrar mensaje o guardar para más tarde
      return false;
    }

    try {
      await _http.dio.post('/api/v1/items/', data: item.toJson());
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 🎨 Uso en Widgets

### 1. Widget Básico con Conectividad

```dart
class ItemListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: ConnectivityAppBar(
        title: Text('Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isOnline
                ? () => ref.read(dataProvider.notifier).refresh()
                : null,
          ),
        ],
      ),
      body: dataState.when(
        data: (items) => ItemList(items: items),
        loading: () => CircularProgressIndicator(),
        error: (error, _) => ErrorWidget(error: error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isOnline ? () => _showAddDialog(context, ref) : null,
        child: Icon(Icons.add),
        backgroundColor: isOnline ? null : Colors.grey,
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    // Dialog para agregar item
  }
}
```

### 2. Widget con Manejo de Estado Offline

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: ConnectivityAppBar(title: Text('Perfil')),
      body: authState.when(
        data: (state) {
          if (state.isOfflineMode) {
            return Column(
              children: [
                Container(
                  color: Colors.orange[100],
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Modo offline - datos no actualizados'),
                    ],
                  ),
                ),
                Expanded(child: ProfileContent(user: state.user)),
              ],
            );
          }

          return ProfileContent(user: state.user);
        },
        loading: () => CircularProgressIndicator(),
        error: (error, _) => ErrorWidget(error: error),
      ),
    );
  }
}
```

### 3. Widget con Refresh Pull-to-Refresh

```dart
class RefreshableListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return RefreshIndicator(
      onRefresh: isOnline
          ? () => ref.read(dataProvider.notifier).refresh()
          : () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sin conexión para actualizar')),
              );
            },
      child: dataState.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ItemTile(items[index]),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

---

## 📝 Casos de Uso Comunes

### 1. Formulario con Validación de Conectividad

```dart
class FormScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sin conexión. Intenta más tarde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await ref.read(dataProvider.notifier)
          .addItem(Item(name: _nameController.text));

      if (success) {
        Navigator.pop(context);
      } else {
        _showErrorMessage('Error al guardar');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: ConnectivityAppBar(title: Text('Nuevo Item')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              if (!isOnline)
                Container(
                  color: Colors.red[100],
                  padding: EdgeInsets.all(8),
                  child: Text('Sin conexión - no se puede guardar'),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isOnline ? _submitForm : null,
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Lista con Paginación Offline-Aware

```dart
final paginatedProvider = AsyncNotifierProvider<PaginatedNotifier, PaginatedData>(
  PaginatedNotifier.new,
);

class PaginatedNotifier extends AsyncNotifier<PaginatedData> {
  final _http = HttpService();

  @override
  Future<PaginatedData> build() async {
    return await _loadPage(1);
  }

  Future<PaginatedData> _loadPage(int page) async {
    final response = await _http.dio.get(
      '/api/v1/items/',
      queryParameters: {'page': page},
    );

    return PaginatedData.fromJson(response.data);
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasNext) return;

    final canMakeRequest = ref.read(canMakeRequestsProvider);
    if (!canMakeRequest) return;

    try {
      final nextPage = await _loadPage(currentState.currentPage + 1);
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...nextPage.items],
        currentPage: nextPage.currentPage,
        hasNext: nextPage.hasNext,
      ));
    } catch (e, st) {
      // Mantener estado actual en caso de error
      state = AsyncValue.data(currentState);
    }
  }
}
```

### 3. Upload de Archivos con Manejo Offline

```dart
class FileUploadWidget extends ConsumerWidget {
  Future<void> _uploadFile(WidgetRef ref, File file) async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      // Guardar en cola local para subir más tarde
      await _queueFileForLater(file);
      _showMessage('Archivo guardado para subir cuando haya conexión');
      return;
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      await HttpService().dio.post('/api/v1/upload/', data: formData);
      _showMessage('Archivo subido exitosamente');
    } catch (e) {
      _showMessage('Error al subir archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickAndUploadFile(ref),
          child: Text(isOnline ? 'Subir Archivo' : 'Guardar para Subir'),
        ),
        if (!isOnline)
          Text(
            'Sin conexión - se subirá automáticamente',
            style: TextStyle(color: Colors.orange),
          ),
      ],
    );
  }
}
```

---

## 🔧 Troubleshooting

### Problemas Comunes

#### 1. "Se cierra la sesión al perder conexión"

**Causa**: AuthProvider no distingue errores de red vs autenticación
**Solución**: Verificar que `_isConnectionError()` funcione correctamente

#### 2. "Los datos no se persisten al cerrar la app"

**Causa**: Falta persistencia en storage
**Solución**: Implementar `_persistUserData()` en AuthProvider

#### 3. "El indicador de conectividad no cambia"

**Causa**: Provider de conectividad no está siendo watched
**Solución**: Verificar que widgets usen `ref.watch(connectivityProvider)`

#### 4. "Requests fallan sin mensaje claro"

**Causa**: Manejo de errores genérico
**Solución**: Implementar `_handleGenericError()` con casos específicos

### Debug Tips

```dart
// Para debug de conectividad
final connectivityState = ref.watch(connectivityProvider);
print('Connectivity: ${connectivityState.status}');

// Para debug de auth
final authState = ref.watch(authProvider);
print('Auth: ${authState.value}');

// Para debug de requests
HttpService().dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

---

## ✅ Best Practices

### 1. Manejo de Estado

- Usar `AsyncNotifier` para data que viene del backend
- Usar `StateNotifier` para estado local
- Implementar `keepAlive()` para cache importante
- Siempre manejar estados loading/error/data

### 2. Conectividad

- Verificar conectividad antes de requests críticos
- Mostrar feedback visual claro del estado
- Permitir operaciones offline cuando sea posible
- Implementar retry automático para requests fallidas

### 3. UX/UI

- Usar indicadores visuales claros (colores, iconos)
- Mostrar mensajes informativos, no técnicos
- Permitir interacción offline cuando sea posible
- Implementar pull-to-refresh para datos importantes

### 4. Performance

- Cachear datos localmente con `keepAlive()`
- Implementar paginación para listas grandes
- Usar loading states específicos por sección
- Evitar requests innecesarios

### 5. Seguridad

- Nunca guardar tokens en logs
- Usar `flutter_secure_storage` para datos sensibles
- Implementar timeout apropiados
- Validar responses del backend

---

## 🚀 Comando Rápido de Implementación

```bash
# 1. Agregar dependencias
flutter pub add flutter_riverpod dio flutter_secure_storage connectivity_plus

# 2. Crear estructura
mkdir -p lib/{models,providers,services,widgets}

# 3. Copiar archivos base
# - HttpService → lib/services/
# - AuthProvider → lib/providers/
# - ConnectivityProvider → lib/providers/
# - ConnectivityAppBar → lib/widgets/

# 4. Configurar main.dart con ProviderScope
# 5. Usar ConnectivityAppBar en lugar de AppBar
# 6. Verificar conectividad antes de requests críticos
```

---

## 📞 Soporte

Para dudas específicas o problemas:

1. Verificar que todos los providers estén configurados
2. Revisar logs de connectivity y auth providers
3. Confirmar que HttpService esté conectado con AuthProvider
4. Verificar permisos de conectividad en platform específica

---

**Versión**: 1.0  
**Última actualización**: Junio 2025  
**Compatible con**: Flutter 3.8+, Dart 3.0+
