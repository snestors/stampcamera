class RegistroGeneral {
  final String vin;
  final String? serie;
  final String? modelo;
  final String? marca;
  final String? color;
  final String? naveDescarga;
  final String? bl;
  final bool pedeteado;
  final bool danos;
  final bool urgente;
  final String? version;

  const RegistroGeneral({
    required this.vin,
    this.serie,
    this.modelo,
    this.marca,
    this.color,
    this.naveDescarga,
    this.bl,
    required this.pedeteado,
    required this.danos,
    this.urgente = false,
    this.version,
  });

  factory RegistroGeneral.fromJson(Map<String, dynamic> json) {
    return RegistroGeneral(
      vin: json['vin'] ?? '',
      serie: json['serie'],
      modelo: json['modelo'],
      marca: json['marca'],
      color: json['color'],
      naveDescarga: json['nave_descarga'],
      bl: json['bl'],
      pedeteado: json['pedeteado'] ?? false,
      danos: json['danos'] ?? false,
      urgente: json['urgente'] ?? false,
      version: json['version'],
    );
  }
}
