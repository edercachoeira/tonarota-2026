import 'package:test/test.dart';
import 'package:tonarota_shared/tonarota_shared.dart';

void main() {
  group('Usuario Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'user-123',
        'email': 'user@test.com',
        'nome': 'João da Silva',
        'role': 'turista',
        'ativo': true,
        'created_at': now.toIso8601String(),
      };

      final usuario = Usuario.fromJson(json);
      expect(usuario.id, 'user-123');
      expect(usuario.email, 'user@test.com');
      expect(usuario.nome, 'João da Silva');
      expect(usuario.role, 'turista');
      expect(usuario.ativo, true);
      expect(usuario.createdAt.year, now.year);

      final serialized = usuario.toJson();
      expect(serialized['id'], 'user-123');
      expect(serialized['email'], 'user@test.com');
      expect(serialized['nome'], 'João da Silva');
      expect(serialized['role'], 'turista');
      expect(serialized['ativo'], true);
      expect(serialized['created_at'], isNotNull);
    });
  });

  group('Balneario Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'balneario-123',
        'nome': 'Praia Grande',
        'municipio': 'Ubatuba',
        'estado': 'SP',
        'descricao': 'Bela praia',
        'imagem_capa_url': 'http://image.url',
        'ativo': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final balneario = Balneario.fromJson(json);
      expect(balneario.id, 'balneario-123');
      expect(balneario.nome, 'Praia Grande');
      expect(balneario.municipio, 'Ubatuba');
      expect(balneario.estado, 'SP');
      expect(balneario.descricao, 'Bela praia');
      expect(balneario.imagemCapaUrl, 'http://image.url');
      expect(balneario.ativo, true);

      final serialized = balneario.toJson();
      expect(serialized['id'], 'balneario-123');
      expect(serialized['nome'], 'Praia Grande');
      expect(serialized['created_at'], isNotNull);
    });
  });

  group('Categoria Model Tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': 'cat-123',
        'nome': 'Restaurantes',
        'icone': 'restaurant',
        'descricao': 'Comida boa',
        'ordem': 1,
        'parent_id': 'parent-456',
        'ativo': true,
      };

      final categoria = Categoria.fromJson(json);
      expect(categoria.id, 'cat-123');
      expect(categoria.nome, 'Restaurantes');
      expect(categoria.icone, 'restaurant');
      expect(categoria.descricao, 'Comida boa');
      expect(categoria.ordem, 1);
      expect(categoria.parentId, 'parent-456');
      expect(categoria.ativo, true);

      final serialized = categoria.toJson();
      expect(serialized['id'], 'cat-123');
      expect(serialized['parent_id'], 'parent-456');
    });
  });

  group('Estabelecimento Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'est-123',
        'usuario_id': 'user-123',
        'balneario_id': 'balneario-123',
        'categoria_id': 'cat-123',
        'nome_fantasia': 'Kiosque do Sol',
        'documento': '12.345.678/0001-99',
        'endereco': 'Av Atlantica, 100',
        'telefone': '1234-5678',
        'whatsapp': '98765-4321',
        'instagram': '@kiosquesol',
        'descricao': 'Melhor quiosque',
        'logomarca_url': 'http://logo.url',
        'plano': 'premium',
        'status': 'ativo',
        'horarios': {'segunda': '08:00 - 22:00'},
        'nota_media': 4.5,
        'total_avaliacoes': 10,
        'total_visualizacoes': 150,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final est = Estabelecimento.fromJson(json);
      expect(est.id, 'est-123');
      expect(est.nomeFantasia, 'Kiosque do Sol');
      expect(est.documento, '12.345.678/0001-99');
      expect(est.plano, 'premium');
      expect(est.status, 'ativo');
      expect(est.horarios['segunda'], '08:00 - 22:00');
      expect(est.notaMedia, 4.5);
      expect(est.totalAvaliacoes, 10);
      expect(est.totalVisualizacoes, 150);

      final serialized = est.toJson();
      expect(serialized['id'], 'est-123');
      expect(serialized['plano'], 'premium');
    });
  });

  group('Camera Model Tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': 'cam-123',
        'balneario_id': 'balneario-123',
        'nome': 'Camera da Orla',
        'url_stream': 'http://live.url/hls.m3u8',
        'protocolo': 'HLS',
        'online': true,
      };

      final camera = Camera.fromJson(json);
      expect(camera.id, 'cam-123');
      expect(camera.nome, 'Camera da Orla');
      expect(camera.urlStream, 'http://live.url/hls.m3u8');
      expect(camera.protocolo, 'HLS');
      expect(camera.online, true);

      final serialized = camera.toJson();
      expect(serialized['id'], 'cam-123');
      expect(serialized['protocolo'], 'HLS');
    });
  });

  group('Produto Model Tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': 'prod-123',
        'estabelecimento_id': 'est-123',
        'titulo': 'Suco Natural',
        'descricao': 'Suco de laranja natural 500ml',
        'preco': 12.50,
        'foto_url': 'http://image.url/suco.jpg',
        'ordem': 2,
        'ativo': true,
      };

      final prod = Produto.fromJson(json);
      expect(prod.id, 'prod-123');
      expect(prod.estabelecimentoId, 'est-123');
      expect(prod.titulo, 'Suco Natural');
      expect(prod.descricao, 'Suco de laranja natural 500ml');
      expect(prod.preco, 12.50);
      expect(prod.fotoUrl, 'http://image.url/suco.jpg');
      expect(prod.ordem, 2);
      expect(prod.ativo, true);

      final serialized = prod.toJson();
      expect(serialized['id'], 'prod-123');
      expect(serialized['preco'], 12.50);
      expect(serialized['ativo'], true);
    });
  });

  group('Evento Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'event-123',
        'balneario_id': 'balneario-123',
        'titulo': 'Show de Verão',
        'data_hora': now.toIso8601String(),
        'local': 'Arena da Praia',
        'descricao': 'Grande show gratuito',
        'imagem_url': 'http://image.url/show.jpg',
        'link_externo': 'http://tickets.url',
      };

      final event = Evento.fromJson(json);
      expect(event.id, 'event-123');
      expect(event.balnearioId, 'balneario-123');
      expect(event.titulo, 'Show de Verão');
      expect(event.dataHora.year, now.year);
      expect(event.local, 'Arena da Praia');
      expect(event.descricao, 'Grande show gratuito');
      expect(event.imagemUrl, 'http://image.url/show.jpg');
      expect(event.linkExterno, 'http://tickets.url');

      final serialized = event.toJson();
      expect(serialized['id'], 'event-123');
      expect(serialized['link_externo'], 'http://tickets.url');
    });
  });

  group('Avaliacao Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'eval-123',
        'estabelecimento_id': 'est-123',
        'nota': 4,
        'comentario': 'Muito bom atendimento',
        'status': 'aprovada',
        'created_at': now.toIso8601String(),
      };

      final eval = Avaliacao.fromJson(json);
      expect(eval.id, 'eval-123');
      expect(eval.estabelecimentoId, 'est-123');
      expect(eval.nota, 4);
      expect(eval.comentario, 'Muito bom atendimento');
      expect(eval.status, 'aprovada');

      final serialized = eval.toJson();
      expect(serialized['id'], 'eval-123');
      expect(serialized['nota'], 4);
    });
  });

  group('BannerModel Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'banner-123',
        'imagem_url': 'http://image.url/banner.jpg',
        'link_destino': 'http://destination.url',
        'data_inicio': now.toIso8601String(),
        'data_fim': now.toIso8601String(),
        'posicao': 'home',
        'status': 'ativo',
      };

      final banner = BannerModel.fromJson(json);
      expect(banner.id, 'banner-123');
      expect(banner.imagemUrl, 'http://image.url/banner.jpg');
      expect(banner.linkDestino, 'http://destination.url');
      expect(banner.posicao, 'home');
      expect(banner.status, 'ativo');

      final serialized = banner.toJson();
      expect(serialized['id'], 'banner-123');
      expect(serialized['posicao'], 'home');
    });
  });

  group('Emergencia Model Tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': 'emerg-123',
        'balneario_id': 'balneario-123',
        'tipo': 'Bombeiros',
        'nome': 'Corpo de Bombeiros',
        'telefone': '193',
      };

      final emerg = Emergencia.fromJson(json);
      expect(emerg.id, 'emerg-123');
      expect(emerg.balnearioId, 'balneario-123');
      expect(emerg.tipo, 'Bombeiros');
      expect(emerg.nome, 'Corpo de Bombeiros');
      expect(emerg.telefone, '193');

      final serialized = emerg.toJson();
      expect(serialized['id'], 'emerg-123');
      expect(serialized['telefone'], '193');
    });
  });

  group('Notificacao Model Tests', () {
    test('fromJson & toJson serialization', () {
      final now = DateTime.now();
      final json = {
        'id': 'notif-123',
        'titulo': 'Novos Eventos!',
        'corpo': 'Confira os novos eventos desta semana',
        'imagem_url': 'http://image.url/notif.jpg',
        'balneario_id': 'balneario-123',
        'enviada_em': now.toIso8601String(),
      };

      final notif = Notificacao.fromJson(json);
      expect(notif.id, 'notif-123');
      expect(notif.titulo, 'Novos Eventos!');
      expect(notif.corpo, 'Confira os novos eventos desta semana');
      expect(notif.imagemUrl, 'http://image.url/notif.jpg');
      expect(notif.balnearioId, 'balneario-123');

      final serialized = notif.toJson();
      expect(serialized['id'], 'notif-123');
      expect(serialized['balneario_id'], 'balneario-123');
    });
  });
}
