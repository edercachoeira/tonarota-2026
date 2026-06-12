class Estabelecimento {
  final String id;
  final String usuarioId;
  final String balnearioId;
  final String categoriaId;
  final String nomeFantasia;
  final String documento;
  final String endereco;
  final String telefone;
  final String whatsapp;
  final String instagram;
  final String descricao;
  final String logomarcaUrl;
  final String plano; // 'gratuito' | 'premium'
  final String status; // 'pendente' | 'ativo' | 'suspenso'
  final Map<String, dynamic> horarios;
  final double notaMedia;
  final int totalAvaliacoes;
  final int totalVisualizacoes;
  final int totalCliquesWhatsapp;
  final int totalCliquesInstagram;
  final DateTime createdAt;
  final DateTime updatedAt;

  Estabelecimento({
    required this.id,
    required this.usuarioId,
    required this.balnearioId,
    required this.categoriaId,
    required this.nomeFantasia,
    required this.documento,
    required this.endereco,
    required this.telefone,
    required this.whatsapp,
    required this.instagram,
    required this.descricao,
    required this.logomarcaUrl,
    required this.plano,
    required this.status,
    required this.horarios,
    required this.notaMedia,
    required this.totalAvaliacoes,
    required this.totalVisualizacoes,
    this.totalCliquesWhatsapp = 0,
    this.totalCliquesInstagram = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Estabelecimento.fromJson(Map<String, dynamic> json) {
    return Estabelecimento(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      balnearioId: json['balneario_id'] as String,
      categoriaId: json['categoria_id'] as String,
      nomeFantasia: json['nome_fantasia'] as String,
      documento: json['documento'] as String? ?? '',
      endereco: json['endereco'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      logomarcaUrl: json['logomarca_url'] as String? ?? '',
      plano: json['plano'] as String? ?? 'gratuito',
      status: json['status'] as String? ?? 'pendente',
      horarios: json['horarios'] as Map<String, dynamic>? ?? {},
      notaMedia: (json['nota_media'] as num?)?.toDouble() ?? 0.0,
      totalAvaliacoes: json['total_avaliacoes'] as int? ?? 0,
      totalVisualizacoes: json['total_visualizacoes'] as int? ?? 0,
      totalCliquesWhatsapp: json['total_cliques_whatsapp'] as int? ?? 0,
      totalCliquesInstagram: json['total_cliques_instagram'] as int? ?? 0,
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
      'usuario_id': usuarioId,
      'balneario_id': balnearioId,
      'categoria_id': categoriaId,
      'nome_fantasia': nomeFantasia,
      'documento': documento,
      'endereco': endereco,
      'telefone': telefone,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'descricao': descricao,
      'logomarca_url': logomarcaUrl,
      'plano': plano,
      'status': status,
      'horarios': horarios,
      'nota_media': notaMedia,
      'total_avaliacoes': totalAvaliacoes,
      'total_visualizacoes': totalVisualizacoes,
      'total_cliques_whatsapp': totalCliquesWhatsapp,
      'total_cliques_instagram': totalCliquesInstagram,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
