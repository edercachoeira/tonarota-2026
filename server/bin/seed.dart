import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPortStr = Platform.environment['DB_PORT'] ?? '5432';
  final dbPort = int.tryParse(dbPortStr) ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'tonarota_dev';
  final dbUser = Platform.environment['DB_USER'] ?? 'tonarota_app';
  final dbPassword = Platform.environment['DB_PASSWORD'] ?? 'tonarota_app';

  print('Conectando ao banco de dados $dbName em $dbHost:$dbPort...');
  try {
    final conn = await Connection.open(
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

    print('Limpando dados fictícios anteriores de balneario e categoria...');
    // Evita chaves estrangeiras quebrando se houver outros relacionamentos, mas como é dev:
    await conn.execute(Sql('TRUNCATE TABLE balneario, categoria CASCADE;'));

    print('Populando categorias...');
    final categories = [
      {'nome': 'Praias', 'icone': 'beach_access', 'descricao': 'Praias oceânicas e fluviais', 'ordem': 1},
      {'nome': 'Cachoeiras', 'icone': 'waterfall_chart', 'descricao': 'Quedas d\'água e poços naturais', 'ordem': 2},
      {'nome': 'Termas', 'icone': 'hot_tub', 'descricao': 'Águas termais e estâncias hidrominerais', 'ordem': 3},
      {'nome': 'Lagoas', 'icone': 'pool', 'descricao': 'Lagoas de águas tranquilas e límpidas', 'ordem': 4},
    ];

    for (var cat in categories) {
      await conn.execute(
        Sql.named(
          'INSERT INTO categoria (nome, icone, descricao, ordem, ativo) '
          'VALUES (@nome, @icone, @descricao, @ordem, TRUE)'
        ),
        parameters: {
          'nome': cat['nome'],
          'icone': cat['icone'],
          'descricao': cat['descricao'],
          'ordem': cat['ordem'],
        },
      );
      print('Categoria inserida: ${cat['nome']}');
    }

    print('Populando balneários...');
    final balnearios = [
      {
        'nome': 'Praia da Enseada',
        'municipio': 'São Francisco do Sul',
        'estado': 'SC',
        'descricao': 'Águas calmas e mornas, ideal para famílias com crianças. Excelente infraestrutura de quiosques e serviços à beira-mar.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Cachoeira do Salto',
        'municipio': 'Joinville',
        'estado': 'SC',
        'descricao': 'Uma queda d\'água exuberante de 15 metros com poço natural profundo para banho relaxante cercado de Mata Atlântica.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Praia Vermelha',
        'municipio': 'Penha',
        'estado': 'SC',
        'descricao': 'Cercada por costões rochosos e vegetação nativa preservada. Areias de tons avermelhados únicos, excelente para surf.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Balneário das Termas',
        'municipio': 'Gravatal',
        'estado': 'SC',
        'descricao': 'Piscinas de águas termais naturalmente aquecidas, com propriedades terapêuticas e relaxantes. Excelente complexo hoteleiro.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Cachoeira Escondida',
        'municipio': 'Corupá',
        'estado': 'SC',
        'descricao': 'Acesso por trilha moderada na mata fechada. Perfeita para quem busca aventura, contato intenso com a natureza e sossego absoluto.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=600&q=80',
      },
      {
        'nome': 'Praia Grande do Sul',
        'municipio': 'Imbituba',
        'estado': 'SC',
        'descricao': 'Extensa faixa de areia dourada e mar aberto com ondas de classe mundial propícias para a prática de surf e campeonatos esportivos.',
        'imagem_capa_url': 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80',
      },
    ];

    for (var bal in balnearios) {
      await conn.execute(
        Sql.named(
          'INSERT INTO balneario (nome, municipio, estado, descricao, imagem_capa_url, ativo, created_at, updated_at) '
          'VALUES (@nome, @municipio, @estado, @descricao, @imagem_capa_url, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)'
        ),
        parameters: {
          'nome': bal['nome'],
          'municipio': bal['municipio'],
          'estado': bal['estado'],
          'descricao': bal['descricao'],
          'imagem_capa_url': bal['imagem_capa_url'],
        },
      );
      print('Balneário inserido: ${bal['nome']}');
    }

    print('População de dados fictícios finalizada com sucesso!');
    await conn.close();
  } catch (e) {
    print('Erro geral na população de dados: $e');
  }
}
