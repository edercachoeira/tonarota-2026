class Evento {
  final String id;
  final String balnearioId;
  final String titulo;
  final DateTime dataHora;
  final String local;
  final String descricao;
  final String imagemUrl;
  final String linkExterno;

  Evento({
    required this.id,
    required this.balnearioId,
    required this.titulo,
    required this.dataHora,
    required this.local,
    required this.descricao,
    required this.imagemUrl,
    required this.linkExterno,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as String,
      balnearioId: json['balneario_id'] as String,
      titulo: json['titulo'] as String,
      dataHora: json['data_hora'] != null 
          ? DateTime.parse(json['data_hora'] as String)
          : DateTime.now(),
      local: json['local'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      imagemUrl: json['imagem_url'] as String? ?? '',
      linkExterno: json['link_externo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balneario_id': balnearioId,
      'titulo': titulo,
      'data_hora': dataHora.toIso8601String(),
      'local': local,
      'descricao': descricao,
      'imagem_url': imagemUrl,
      'link_externo': linkExterno,
    };
  }
}
