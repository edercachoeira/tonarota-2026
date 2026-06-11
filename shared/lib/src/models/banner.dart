class BannerModel {
  final String id;
  final String imagemUrl;
  final String linkDestino;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String posicao; // 'home' | 'diretorio'
  final String status; // 'ativo' | 'agendado' | 'expirado'

  BannerModel({
    required this.id,
    required this.imagemUrl,
    required this.linkDestino,
    required this.dataInicio,
    required this.dataFim,
    required this.posicao,
    required this.status,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imagemUrl: json['imagem_url'] as String,
      linkDestino: json['link_destino'] as String? ?? '',
      dataInicio: json['data_inicio'] != null 
          ? DateTime.parse(json['data_inicio'] as String)
          : DateTime.now(),
      dataFim: json['data_fim'] != null 
          ? DateTime.parse(json['data_fim'] as String)
          : DateTime.now(),
      posicao: json['posicao'] as String? ?? 'home',
      status: json['status'] as String? ?? 'agendado',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagem_url': imagemUrl,
      'link_destino': linkDestino,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'posicao': posicao,
      'status': status,
    };
  }
}
