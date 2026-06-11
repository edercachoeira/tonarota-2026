import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/image_crop_dialog.dart';
import 'merchant_layout.dart';

class MerchantPerfilView extends StatefulWidget {
  const MerchantPerfilView({super.key});

  @override
  State<MerchantPerfilView> createState() => _MerchantPerfilViewState();
}

class _MerchantPerfilViewState extends State<MerchantPerfilView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  late TextEditingController _nomeFantasiaController;
  late TextEditingController _documentoController;
  late TextEditingController _enderecoController;
  late TextEditingController _telefoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _instagramController;
  late TextEditingController _descricaoController;
  late TextEditingController _logomarcaController;

  Map<String, dynamic> _horarios = {};
  bool _saving = false;
  String? _message;
  bool _isSuccess = false;

  final List<String> _diasDaSemana = [
    'segunda',
    'terca',
    'quarta',
    'quinta',
    'sexta',
    'sabado',
    'domingo',
  ];

  final Map<String, String> _diasExibicao = {
    'segunda': 'Segunda-feira',
    'terca': 'Terça-feira',
    'quarta': 'Quarta-feira',
    'quinta': 'Quinta-feira',
    'sexta': 'Sexta-feira',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final est = Provider.of<Estabelecimento?>(context);
    if (est != null) {
      _nomeFantasiaController = TextEditingController(text: est.nomeFantasia);
      _documentoController = TextEditingController(text: est.documento);
      _enderecoController = TextEditingController(text: est.endereco);
      _telefoneController = TextEditingController(text: est.telefone);
      _whatsappController = TextEditingController(text: est.whatsapp);
      _instagramController = TextEditingController(text: est.instagram);
      _descricaoController = TextEditingController(text: est.descricao);
      _logomarcaController = TextEditingController(text: est.logomarcaUrl);
      
      // Inicializa os horários
      _horarios = Map<String, dynamic>.from(est.horarios);
      for (var dia in _diasDaSemana) {
        if (!_horarios.containsKey(dia)) {
          _horarios[dia] = {
            'aberto': false,
            'abertura': '08:00',
            'fechamento': '18:00',
          };
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    final est = Provider.of<Estabelecimento?>(context, listen: false);
    if (est == null) return;

    try {
      final response = await _api.put('/v1/estabelecimentos/${est.id}', {
        'balneario_id': est.balnearioId,
        'categoria_id': est.categoriaId,
        'nome_fantasia': _nomeFantasiaController.text.trim(),
        'documento': _documentoController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'logomarca_url': _logomarcaController.text.trim(),
        'plano': est.plano,
        'status': est.status,
        'horarios': _horarios,
      });

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Perfil atualizado com sucesso!';
          _isSuccess = true;
          _saving = false;
        });

        // Força recarregamento no layout pai para refletir mudanças no header/sidebar
        if (mounted) {
          context.findAncestorStateOfType<MerchantLayoutState>()?.loadEstabelecimento();
        }
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Erro ao salvar perfil.';
        throw Exception(err);
      }
    } catch (e) {
      setState(() {
        _message = 'Erro: $e';
        _isSuccess = false;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final est = Provider.of<Estabelecimento?>(context);
    if (est == null) {
      return const Center(child: Text('Nenhum estabelecimento encontrado.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configurações do Perfil',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
              ),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Salvar Alterações'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isSuccess ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
              ),
              child: Text(
                _message!,
                style: TextStyle(color: _isSuccess ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          TabBar(
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: 'Informações Básicas'),
              Tab(icon: Icon(Icons.contact_mail_outlined), text: 'Contatos & Endereço'),
              Tab(icon: Icon(Icons.access_time_rounded), text: 'Horários de Funcionamento'),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                children: [
                  // Tab 1: Informações Básicas
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logomarca Upload Section
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _logomarcaController.text.isNotEmpty
                                    ? NetworkImage(_logomarcaController.text)
                                    : null,
                                child: _logomarcaController.text.isEmpty
                                    ? const Icon(Icons.storefront, size: 48, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => ImageCropDialog(
                                      title: 'Logomarca (1:1)',
                                      aspectRatio: 1.0,
                                      onUploadSuccess: (url) {
                                        setState(() {
                                          _logomarcaController.text = url;
                                        });
                                      },
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                label: const Text('Alterar Logo'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          TextFormField(
                            controller: _nomeFantasiaController,
                            decoration: const InputDecoration(
                              labelText: 'Nome Fantasia',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Insira o nome fantasia.' : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _documentoController,
                            decoration: const InputDecoration(
                              labelText: 'Documento (CPF / CNPJ)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Insira o documento.' : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _descricaoController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Descrição Comercial / Sobre Nós',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 60.0),
                                child: Icon(Icons.description_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Contatos
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _whatsappController,
                            decoration: const InputDecoration(
                              labelText: 'Link WhatsApp Comercial',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _instagramController,
                            decoration: const InputDecoration(
                              labelText: 'Link Instagram',
                              prefixIcon: Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _enderecoController,
                            decoration: const InputDecoration(
                              labelText: 'Endereço Completo',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Insira o endereço.' : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 3: Horários
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _diasDaSemana.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final dia = _diasDaSemana[index];
                          final diaConfig = _horarios[dia] as Map<String, dynamic>;
                          final isAberto = diaConfig['aberto'] as bool? ?? false;

                          return Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  _diasExibicao[dia]!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Switch(
                                value: isAberto,
                                activeColor: AppTheme.primaryTeal,
                                onChanged: (val) {
                                  setState(() {
                                    diaConfig['aberto'] = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Opacity(
                                  opacity: isAberto ? 1.0 : 0.4,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: diaConfig['abertura'] as String? ?? '08:00',
                                          enabled: isAberto,
                                          decoration: const InputDecoration(
                                            labelText: 'Abertura',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (val) {
                                            diaConfig['abertura'] = val;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('até'),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: diaConfig['fechamento'] as String? ?? '18:00',
                                          enabled: isAberto,
                                          decoration: const InputDecoration(
                                            labelText: 'Fechamento',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (val) {
                                            diaConfig['fechamento'] = val;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
