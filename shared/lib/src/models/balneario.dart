class Balneario {
  final String id;
  final String nome;
  final String municipio;
  final String estado;
  final String descricao;
  final String imagemCapaUrl;
  final bool ativo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Balneario({
    required this.id,
    required this.nome,
    required this.municipio,
    required this.estado,
    required this.descricao,
    required this.imagemCapaUrl,
    required this.ativo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Balneario.fromJson(Map<String, dynamic> json) {
    return Balneario(
      id: json['id'] as String,
      nome: json['nome'] as String,
      municipio: json['municipio'] as String,
      estado: json['estado'] as String,
      descricao: json['descricao'] as String? ?? '',
      imagemCapaUrl: json['imagem_capa_url'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'municipio': municipio,
      'estado': estado,
      'descricao': descricao,
      'imagem_capa_url': imagemCapaUrl,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
