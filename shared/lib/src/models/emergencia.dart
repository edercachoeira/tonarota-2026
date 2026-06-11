class Emergencia {
  final String id;
  final String balnearioId;
  final String tipo; // 'Policia' | 'Bombeiros' | 'SAMU' | etc.
  final String nome;
  final String telefone;

  Emergencia({
    required this.id,
    required this.balnearioId,
    required this.tipo,
    required this.nome,
    required this.telefone,
  });

  factory Emergencia.fromJson(Map<String, dynamic> json) {
    return Emergencia(
      id: json['id'] as String,
      balnearioId: json['balneario_id'] as String,
      tipo: json['tipo'] as String,
      nome: json['nome'] as String,
      telefone: json['telefone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balneario_id': balnearioId,
      'tipo': tipo,
      'nome': nome,
      'telefone': telefone,
    };
  }
}
