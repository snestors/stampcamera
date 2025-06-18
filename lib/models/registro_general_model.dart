class RegistroGeneral {
  final String vin;
  final String? serie;
  final String? modelo;
  final String? marca;
  final String? naveDescarga;
  final String? bl;
  final String? color;

  const RegistroGeneral({
    required this.vin,
    this.serie,
    this.modelo,
    this.marca,
    this.naveDescarga,
    this.bl,
    this.color,
  });

  factory RegistroGeneral.fromJson(Map<String, dynamic> json) {
    return RegistroGeneral(
      vin: json['vin'] ?? '',
      serie: json['serie'],
      modelo: json['informacion_unidad']?['modelo'],
      marca: json['informacion_unidad']?['marca']?['marca'],
      naveDescarga: json['embarque']?['nave_descarga']?['nombre_buque'],
      bl: json['bl'],
      color: json['color'],
    );
  }
}
