class Notificacao {
  final String id;
  final String titulo;
  final String corpo;
  final String imagemUrl;
  final String? balnearioId; // Nullable para envio global
  final DateTime enviadaEm;

  Notificacao({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.imagemUrl,
    this.balnearioId,
    required this.enviadaEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      corpo: json['corpo'] as String? ?? '',
      imagemUrl: json['imagem_url'] as String? ?? '',
      balnearioId: json['balneario_id'] as String?,
      enviadaEm: json['enviada_em'] != null 
          ? DateTime.parse(json['enviada_em'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'corpo': corpo,
      'imagem_url': imagemUrl,
      'balneario_id': balnearioId,
      'enviada_em': enviadaEm.toIso8601String(),
    };
  }
}
