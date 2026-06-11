class Avaliacao {
  final String id;
  final String estabelecimentoId;
  final int nota; // 1 a 5
  final String comentario;
  final String status; // 'aprovada' | 'oculta'
  final DateTime createdAt;

  Avaliacao({
    required this.id,
    required this.estabelecimentoId,
    required this.nota,
    required this.comentario,
    required this.status,
    required this.createdAt,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      nota: json['nota'] as int? ?? 5,
      comentario: json['comentario'] as String? ?? '',
      status: json['status'] as String? ?? 'aprovada',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento_id': estabelecimentoId,
      'nota': nota,
      'comentario': comentario,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
