class Usuario {
  final String id;
  final String email;
  final String nome;
  final String role; // 'turista' | 'estabelecimento' | 'gestor'
  final bool ativo;
  final DateTime createdAt;

  Usuario({
    required this.id,
    required this.email,
    required this.nome,
    required this.role,
    required this.ativo,
    required this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nome: json['nome'] as String,
      role: json['role'] as String,
      ativo: json['ativo'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'role': role,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
