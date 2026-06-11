class Camera {
  final String id;
  final String balnearioId;
  final String nome;
  final String urlStream;
  final String protocolo; // 'HLS' | 'RTSP'
  final bool online;

  Camera({
    required this.id,
    required this.balnearioId,
    required this.nome,
    required this.urlStream,
    required this.protocolo,
    required this.online,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as String,
      balnearioId: json['balneario_id'] as String,
      nome: json['nome'] as String,
      urlStream: json['url_stream'] as String,
      protocolo: json['protocolo'] as String? ?? 'HLS',
      online: json['online'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balneario_id': balnearioId,
      'nome': nome,
      'url_stream': urlStream,
      'protocolo': protocolo,
      'online': online,
    };
  }
}
