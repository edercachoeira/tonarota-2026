class Categoria {
  final String id;
  final String nome;
  final String icone;
  final String descricao;
  final int ordem;
  final String? parentId;
  final bool ativo;

  Categoria({
    required this.id,
    required this.nome,
    required this.icone,
    required this.descricao,
    required this.ordem,
    this.parentId,
    required this.ativo,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nome: json['nome'] as String,
      icone: json['icone'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      ordem: json['ordem'] as int? ?? 0,
      parentId: json['parent_id'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'icone': icone,
      'descricao': descricao,
      'ordem': ordem,
      'parent_id': parentId,
      'ativo': ativo,
    };
  }
}
