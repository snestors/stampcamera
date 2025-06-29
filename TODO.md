# TODO: Correcciones Backend - Registro VIN

## ❌ PROBLEMA ACTUAL

### Respuesta Actual del API:

```json
{
  "vin": "SJNTAAJ12TA163765",
  "condicion": "ALMACEN",
  "zona_inspeccion": 6, // ❌ Solo ID numérico
  "bloque": 4, // ❌ Solo ID numérico
  "fila": null,
  "posicion": null,
  "foto_vin": "https://...",
  "contenedor": null
}
```

### Problema:

- **`zona_inspeccion`** viene como `int` (6) en lugar de objeto completo
- **`bloque`** viene como `int` (4) en lugar de objeto completo
- **Frontend espera objetos** con `id` y `label` según el modelo `RegistroVin`

## ✅ SOLUCIÓN REQUERIDA

### Respuesta Esperada del API:

```json
{
  "vin": "SJNTAAJ12TA163765",
  "condicion": "ALMACEN",
  "zona_inspeccion": {
    // ✅ Objeto completo
    "id": 6,
    "nombre": "GH CHANCAY - 5029"
  },
  "bloque": {
    // ✅ Objeto completo
    "id": 4,
    "nombre": "MUELLE 2"
  },
  "fila": null,
  "posicion": null,
  "foto_vin": "https://...",
  "contenedor": null,
  "fecha": "28/06/2025 15:30", // ✅ Agregar fecha de creación
  "create_by": "Juan Pérez" // ✅ Agregar usuario que creó
}
```

## 🔧 CAMBIOS EN BACKEND

### 1. Serializer de RegistroVin (Django)

```python
class RegistroVinSerializer(serializers.ModelSerializer):
    zona_inspeccion = ZonaInspeccionSerializer(read_only=True)  # ✅ Objeto completo
    bloque = BloqueSerializer(read_only=True)                   # ✅ Objeto completo

    class Meta:
        model = RegistroVin
        fields = [
            'vin',
            'condicion',
            'zona_inspeccion',  # Objeto con id y nombre
            'bloque',           # Objeto con id y nombre
            'fila',
            'posicion',
            'foto_vin',
            'foto_vin_thumbnail_url',
            'contenedor',
            'fecha',            # Fecha de creación formateada
            'create_by'         # Usuario que creó
        ]
```

### 2. Serializers Anidados

```python
class ZonaInspeccionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZonaInspeccion
        fields = ['id', 'nombre']

class BloqueSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bloque
        fields = ['id', 'nombre']
```

### 3. ViewSet de RegistroVin

```python
class RegistroVinViewSet(viewsets.ModelViewSet):
    def create(self, request, *args, **kwargs):
        # Lógica de creación actual...

        # ✅ Retornar con serializer completo
        return Response(
            RegistroVinSerializer(instance).data,  # Usa serializer con objetos anidados
            status=status.HTTP_201_CREATED
        )
```

## 📋 ARCHIVOS A MODIFICAR

### Backend (Django):

- [ ] `serializers.py` - Actualizar `RegistroVinSerializer`
- [ ] `serializers.py` - Crear `ZonaInspeccionSerializer` y `BloqueSerializer`
- [ ] `views.py` - Actualizar respuesta del `create()` en ViewSet
- [ ] Verificar que `fecha` y `create_by` se incluyan en respuesta

### Frontend (Flutter) - DESPUÉS del fix backend:

- [ ] Verificar que `RegistroVin.fromJson()` funcione con nueva estructura
- [ ] Actualizar `_buildInfoRow()` para mostrar nombres en lugar de IDs
- [ ] Probar que el state se actualice correctamente

## 🧪 PRUEBAS REQUERIDAS

### Backend:

- [ ] **POST** `/api/v1/autos/registro-vin/` - Verificar respuesta con objetos anidados
- [ ] **GET** `/api/v1/autos/registro-general/{vin}/` - Verificar lista de registros
- [ ] Verificar que `zona_inspeccion` sea objeto `{id, nombre}`
- [ ] Verificar que `bloque` sea objeto `{id, nombre}`

### Frontend:

- [ ] Crear registro VIN desde formulario
- [ ] Verificar que lista se actualice automáticamente
- [ ] Verificar que nombres se muestren correctamente (no IDs)
- [ ] Probar que estado se mantenga entre navegaciones

## ⚠️ WORKAROUND TEMPORAL

### En Frontend (mientras se corrige backend):

```dart
// En RegistroVin.fromJson(), agregar mapeo temporal:
factory RegistroVin.fromJson(Map<String, dynamic> json) {
  return RegistroVin(
    vin: json['vin'],
    condicion: json['condicion'],
    // ✅ Workaround temporal para zona_inspeccion
    zonaInspeccion: json['zona_inspeccion'] is int
      ? 'Zona ${json['zona_inspeccion']}'  // Temporal: mostrar "Zona 6"
      : json['zona_inspeccion']['nombre'], // Futuro: nombre real
    // ✅ Workaround temporal para bloque
    bloque: json['bloque'] is int
      ? 'Bloque ${json['bloque']}'         // Temporal: mostrar "Bloque 4"
      : json['bloque']['nombre'],          // Futuro: nombre real
    // ... resto de campos
  );
}
```

## 🎯 PRIORIDAD

**🔥 ALTA** - Este fix es crítico porque:

- Afecta la experiencia de usuario (muestra IDs en lugar de nombres)
- Puede causar errores de parsing en el frontend
- Es necesario para la consistencia de datos
- Impacta el estado local del provider

## 📅 ESTIMACIÓN

- **Backend:** 2-4 horas (serializers + pruebas)
- **Frontend:** 1 hora (verificación + cleanup del workaround)
- **Testing:** 1 hora (pruebas integradas)

---

**Creado:** 28/06/2025  
**Asignado a:** Equipo Backend  
**Estado:** Pendiente  
**Dependencias:** Ninguna
