class Produto {
  final String id;
  final String estabelecimentoId;
  final String titulo;
  final String descricao;
  final double preco;
  final String fotoUrl;
  final int ordem;
  final bool ativo;

  Produto({
    required this.id,
    required this.estabelecimentoId,
    required this.titulo,
    required this.descricao,
    required this.preco,
    required this.fotoUrl,
    required this.ordem,
    required this.ativo,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String? ?? '',
      preco: (json['preco'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: json['foto_url'] as String? ?? '',
      ordem: json['ordem'] as int? ?? 0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento_id': estabelecimentoId,
      'titulo': titulo,
      'descricao': descricao,
      'preco': preco,
      'foto_url': fotoUrl,
      'ordem': ordem,
      'ativo': ativo,
    };
  }
}
