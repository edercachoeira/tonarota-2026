import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';

void main() async {
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPortStr = Platform.environment['DB_PORT'] ?? '5432';
  final dbPort = int.tryParse(dbPortStr) ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'tonarota_dev';
  final dbUser = Platform.environment['DB_USER'] ?? 'postgres';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'postgres';

  print('Conectando ao banco de dados $dbName em $dbHost:$dbPort...');
  Connection? conn;
  try {
    conn = await Connection.open(
      Endpoint(
        host: dbHost,
        port: dbPort,
        database: dbName,
        username: dbUser,
        password: dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );

    print('Limpando dados anteriores...');
    await conn.execute(Sql('TRUNCATE TABLE balneario, categoria, usuario, estabelecimento, produto, avaliacao, estabelecimento_metrica CASCADE;'));

    print('Populando categorias...');
    final categories = [
      {'nome': 'Gastronomia', 'icone': 'restaurant', 'descricao': 'Quiosques, restaurantes e petiscarias', 'ordem': 1},
      {'nome': 'Hospedagem', 'icone': 'hotel', 'descricao': 'Pousadas, hotéis e áreas de camping', 'ordem': 2},
      {'nome': 'Lazer e Passeios', 'icone': 'directions_boat', 'descricao': 'Aluguel de caiaques, barcos e trilhas guiadas', 'ordem': 3},
      {'nome': 'Comércio Local', 'icone': 'shopping_bag', 'descricao': 'Lojas de conveniência, artesanatos e moda praia', 'ordem': 4},
    ];

    final Map<String, String> catIds = {};
    for (var cat in categories) {
      final res = await conn.execute(
        Sql.named(
          'INSERT INTO categoria (nome, icone, descricao, ordem, ativo) '
          'VALUES (@nome, @icone, @descricao, @ordem, TRUE) RETURNING id'
        ),
        parameters: {
          'nome': cat['nome'],
          'icone': cat['icone'],
          'descricao': cat['descricao'],
          'ordem': cat['ordem'],
        },
      );
      catIds[cat['nome'] as String] = res.first[0] as String;
    }

    print('Populando balneários...');
    final balnearios = [
      {
        'nome': 'Praia da Enseada',
        'municipio': 'São Francisco do Sul',
        'estado': 'SC',
        'descricao': 'Águas calmas e mornas, ideal para famílias com crianças. Excelente infraestrutura de quiosques.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Cachoeira do Salto',
        'municipio': 'Joinville',
        'estado': 'SC',
        'descricao': 'Uma queda d\'água exuberante de 15 metros com poço natural profundo para banho relaxante.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Praia Vermelha',
        'municipio': 'Penha',
        'estado': 'SC',
        'descricao': 'Cercada por costões rochosos e vegetação nativa preservada. Areias de tons avermelhados únicos.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=600&q=80',
      },
    ];

    final Map<String, String> balIds = {};
    for (var bal in balnearios) {
      final res = await conn.execute(
        Sql.named(
          'INSERT INTO balneario (nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at) '
          'VALUES (@nome, @municipio, @estado, @descricao, @imagem_capa_url, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id'
        ),
        parameters: {
          'nome': bal['nome'],
          'municipio': bal['municipio'],
          'estado': bal['estado'],
          'descricao': bal['descricao'],
          'imagem_capa_url': bal['imagem_capa_url'],
        },
      );
      balIds[bal['nome'] as String] = res.first[0] as String;
    }

    print('Populando usuários...');
    final passHashAdmin = BCrypt.hashpw('admin123', BCrypt.gensalt());
    final passHashLojista = BCrypt.hashpw('lojista123', BCrypt.gensalt());

    // 1. Usuário Gestor (Admin)
    final adminUserRes = await conn.execute(
      Sql.named(
        'INSERT INTO usuario (email, senha_hash, nome, role, ativo, created_at) '
        'VALUES (\'admin@tonarota.com\', @senhaHash, \'Carlos Gestor\', \'gestor\', TRUE, CURRENT_TIMESTAMP) RETURNING id'
      ),
      parameters: {'senhaHash': passHashAdmin},
    );

    // 2. Usuário Estabelecimento (Lojista 1)
    final lojista1Res = await conn.execute(
      Sql.named(
        'INSERT INTO usuario (email, senha_hash, nome, role, ativo, created_at) '
        'VALUES (\'lojista@tonarota.com\', @senhaHash, \'Alberto Silva\', \'estabelecimento\', TRUE, CURRENT_TIMESTAMP) RETURNING id'
      ),
      parameters: {'senhaHash': passHashLojista},
    );
    final lojista1Id = lojista1Res.first[0] as String;

    // 3. Usuário Estabelecimento (Lojista 2)
    final lojista2Res = await conn.execute(
      Sql.named(
        'INSERT INTO usuario (email, senha_hash, nome, role, ativo, created_at) '
        'VALUES (\'pousada@tonarota.com\', @senhaHash, \'Maria Souza\', \'estabelecimento\', TRUE, CURRENT_TIMESTAMP) RETURNING id'
      ),
      parameters: {'senhaHash': passHashLojista},
    );
    final lojista2Id = lojista2Res.first[0] as String;

    print('Populando estabelecimentos...');
    // Estabelecimento 1 - Lojista Alberto (Premium)
    final est1Res = await conn.execute(
      Sql.named(
        'INSERT INTO estabelecimento (usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at) '
        'VALUES (@usuarioId, @balnearioId, @categoriaId, \'Quiosque Beira Mar\', \'12.345.678/0001-90\', '
        '\'Av. Beira Mar, 450 - Enseada\', \'(47) 99912-3456\', \'5547999123456\', \'quiosque.enseada\', '
        '\'O melhor pastel de camarão da Enseada com cerveja super gelada. Atendimento na areia!\', '
        '\'https://images.unsplash.com/photo-1578496479531-32e296d5c6e1?auto=format&fit=crop&w=200&q=80\', '
        '\'premium\', \'ativo\', \'{}\'::jsonb, 4.8, 3, 450, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id'
      ),
      parameters: {
        'usuarioId': lojista1Id,
        'balnearioId': balIds['Praia da Enseada']!,
        'categoriaId': catIds['Gastronomia']!,
      },
    );
    final est1Id = est1Res.first[0] as String;

    // Estabelecimento 2 - Lojista Maria (Gratuito)
    final est2Res = await conn.execute(
      Sql.named(
        'INSERT INTO estabelecimento (usuario_id, balneario_id, categoria_id, nome_fantasia, documento, '
        'endereco, telefone, whatsapp, instagram, descricao, logomarca_url, plano, status, horarios, '
        'nota_media, total_avaliacoes, total_visualizacoes, created_at, updated_at) '
        'VALUES (@usuarioId, @balnearioId, @categoriaId, \'Pousada do Salto\', \'98.765.432/0001-21\', '
        '\'Estrada Geral do Salto, Km 4\', \'(47) 98877-6655\', \'5547988776655\', \'pousada.salto\', '
        '\'Hospedagem aconchegante cercada pela natureza com café da manhã artesanal completo.\', '
        '\'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=200&q=80\', '
        '\'gratuito\', \'ativo\', \'{}\'::jsonb, 4.5, 2, 180, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id'
      ),
      parameters: {
        'usuarioId': lojista2Id,
        'balnearioId': balIds['Cachoeira do Salto']!,
        'categoriaId': catIds['Hospedagem']!,
      },
    );
    final est2Id = est2Res.first[0] as String;

    print('Populando produtos...');
    final produtos = [
      {'estId': est1Id, 'titulo': 'Pastel de Camarão Especial', 'preco': 22.90, 'desc': 'Recheio farto de camarão legítimo da região com catupiry.'},
      {'estId': est1Id, 'titulo': 'Isca de Peixe à Milanesa', 'preco': 49.90, 'desc': 'Iscas de peixe espada fresquinho acompanhado de molho tártaro.'},
      {'estId': est1Id, 'titulo': 'Caipirinha Tradicional 500ml', 'preco': 18.00, 'desc': 'Limão, açúcar, gelo e cachaça artesanal de alambique.'},
    ];

    for (var prod in produtos) {
      await conn.execute(
        Sql.named(
          'INSERT INTO produto (estabelecimento_id, titulo, descricao, preco, foto_url, ordem, ativo) '
          'VALUES (@estId, @titulo, @desc, @preco, \'\', 0, TRUE)'
        ),
        parameters: {
          'estId': prod['estId'],
          'titulo': prod['titulo'],
          'desc': prod['desc'],
          'preco': prod['preco'],
        },
      );
    }

    print('Populando avaliações...');
    final reviews = [
      {'estId': est1Id, 'nota': 5, 'comentario': 'Lugar fantástico! O pastel de camarão é o melhor que já comi.', 'status': 'aprovada'},
      {'estId': est1Id, 'nota': 4, 'comentario': 'Cerveja trincando de gelada, atendimento rápido mesmo na areia.', 'status': 'aprovada'},
      {'estId': est1Id, 'nota': 5, 'comentario': 'Ambiente super limpo e aconchegante, volto sempre!', 'status': 'aprovada'},
      {'estId': est1Id, 'nota': 1, 'comentario': 'Comentário teste ocultado contendo spam ou xingamentos.', 'status': 'oculta'},
      
      {'estId': est2Id, 'nota': 5, 'comentario': 'Pousada maravilhosa! Café da manhã dos deuses, recomendo.', 'status': 'aprovada'},
      {'estId': est2Id, 'nota': 4, 'comentario': 'Muito calmo e relaxante, ideal para descansar no final de semana.', 'status': 'aprovada'},
    ];

    for (var rev in reviews) {
      await conn.execute(
        Sql.named(
          'INSERT INTO avaliacao (estabelecimento_id, nota, comentario, status, created_at) '
          'VALUES (@estId, @nota, @comentario, @status, CURRENT_TIMESTAMP)'
        ),
        parameters: {
          'estId': rev['estId'],
          'nota': rev['nota'],
          'comentario': rev['comentario'],
          'status': rev['status'],
        },
      );
    }

    print('Populando histórico de métricas diárias (últimos 7 dias)...');
    final tipos = ['visualizacao', 'whatsapp', 'instagram'];
    final randomScale = [24, 38, 42, 51, 65, 48, 30]; // 7 dias anteriores

    for (int i = 0; i < 7; i++) {
      final data = DateTime.now().subtract(Duration(days: 6 - i));
      final dataStr = '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      
      // Inserir métricas para Estabelecimento 1
      for (final tipo in tipos) {
        int qty = 5;
        if (tipo == 'visualizacao') qty = randomScale[i];
        if (tipo == 'whatsapp') qty = (randomScale[i] * 0.15).round();
        if (tipo == 'instagram') qty = (randomScale[i] * 0.08).round();

        await conn.execute(
          Sql.named(
            'INSERT INTO estabelecimento_metrica (estabelecimento_id, tipo, data, quantidade) '
            'VALUES (@estId, @tipo, CAST(@data AS DATE), @qty)'
          ),
          parameters: {
            'estId': est1Id,
            'tipo': tipo,
            'data': dataStr,
            'qty': qty,
          },
        );
      }

      // Inserir métricas para Estabelecimento 2
      for (final tipo in tipos) {
        int qty = 2;
        if (tipo == 'visualizacao') qty = (randomScale[i] * 0.4).round();
        if (tipo == 'whatsapp') qty = (randomScale[i] * 0.05).round();
        if (tipo == 'instagram') qty = (randomScale[i] * 0.03).round();

        await conn.execute(
          Sql.named(
            'INSERT INTO estabelecimento_metrica (estabelecimento_id, tipo, data, quantidade) '
            'VALUES (@estId, @tipo, CAST(@data AS DATE), @qty)'
          ),
          parameters: {
            'estId': est2Id,
            'tipo': tipo,
            'data': dataStr,
            'qty': qty,
          },
        );
      }
    }

    // Atualizar as médias com o trigger/lógica do banco
    await conn.execute(Sql(
      'UPDATE estabelecimento SET '
      'nota_media = COALESCE((SELECT AVG(nota)::NUMERIC(3,2) FROM avaliacao WHERE estabelecimento_id = estabelecimento.id AND status = \'aprovada\'), 0.0), '
      'total_avaliacoes = (SELECT COUNT(*) FROM avaliacao WHERE estabelecimento_id = estabelecimento.id AND status = \'aprovada\')'
    ));

    print('População de dados ricos para apresentação finalizada com sucesso!');
    await conn.close();
  } catch (e) {
    print('Erro geral na população de dados: $e');
  }
}
