import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class MerchantDashboardView extends StatefulWidget {
  const MerchantDashboardView({super.key});

  @override
  State<MerchantDashboardView> createState() => _MerchantDashboardViewState();
}

class _MerchantDashboardViewState extends State<MerchantDashboardView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Métricas reais da API
  int _totalViews = 0;
  int _whatsappClicks = 0;
  int _instagramClicks = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  List<dynamic> _recentReviews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final est = Provider.of<Estabelecimento?>(context);
    if (est != null) {
      _loadDashboardData(est.id);
    }
  }

  Future<void> _loadDashboardData(String estId) async {
    try {
      final responses = await Future.wait([
        _apiService.get('/v1/metricas/estabelecimento/$estId'),
        _apiService.get('/v1/avaliacoes/estabelecimento/$estId'),
      ]);

      int views = 0;
      int whatsapp = 0;
      int instagram = 0;
      List<Map<String, dynamic>> weekly = [];
      List<dynamic> reviews = [];

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body) as Map<String, dynamic>;
        final acumulado = data['acumulado'] as Map<String, dynamic>;
        views = acumulado['visualizacao'] as int? ?? 0;
        whatsapp = acumulado['whatsapp'] as int? ?? 0;
        instagram = acumulado['instagram'] as int? ?? 0;

        final semanalList = data['semanal'] as List;
        weekly = semanalList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (responses[1].statusCode == 200) {
        reviews = jsonDecode(responses[1].body) as List;
      }

      if (mounted) {
        setState(() {
          _totalViews = views;
          _whatsappClicks = whatsapp;
          _instagramClicks = instagram;
          _weeklyData = weekly;
          _recentReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar métricas do painel lojista: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final est = Provider.of<Estabelecimento?>(context);
    if (est == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    // Acha o valor máximo para escalonar o gráfico de barras
    final maxQty = _weeklyData.isEmpty 
        ? 1 
        : _weeklyData.map<int>((e) => e['quantidade'] as int).fold(1, (max, val) => val > max ? val : max);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Header Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.primaryTeal.withOpacity(0.2), Colors.transparent]
                    : [AppTheme.primaryTeal.withOpacity(0.08), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '👋 Bem-vindo de volta, ',
                          style: TextStyle(fontSize: 16, color: secondaryColor, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          est.nomeFantasia,
                          style: const TextStyle(fontSize: 16, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Atualizar Painel',
                      onPressed: () => _loadDashboardData(est.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Este é o seu console de métricas e controle de catálogo do Tô Na Rota.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Cards Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width < 700 ? 1 : (MediaQuery.of(context).size.width < 1200 ? 2 : 4),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              _buildMetricCard(
                title: 'Visualizações do Perfil',
                value: '$_totalViews',
                subtitle: 'Acessos totais de turistas',
                icon: Icons.visibility_outlined,
                color: AppTheme.primaryTeal,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              _buildMetricCard(
                title: 'Avaliação Média',
                value: est.notaMedia > 0 
                    ? est.notaMedia.toStringAsFixed(1) 
                    : 'S/A',
                subtitle: est.totalAvaliacoes > 0
                    ? 'Baseado em ${est.totalAvaliacoes} opiniões'
                    : 'Nenhuma avaliação ainda',
                icon: Icons.star_border_rounded,
                color: AppTheme.secondaryAmber,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              _buildMetricCard(
                title: 'Cliques no WhatsApp',
                value: '$_whatsappClicks',
                subtitle: 'Contatos diretos no link',
                icon: Icons.phone_outlined,
                color: Colors.green,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              _buildMetricCard(
                title: 'Cliques no Instagram',
                value: '$_instagramClicks',
                subtitle: 'Redirecionamentos de rede',
                icon: Icons.camera_alt_outlined,
                color: Colors.purple,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Graph / Analytics section
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;
              final leftCol = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desempenho Semanal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acessos diários ao perfil nos últimos 7 dias',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _weeklyData.isEmpty
                              ? Center(child: Text('Sem histórico de dados', style: TextStyle(color: secondaryColor)))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: _weeklyData.map((e) {
                                    final label = e['dia'] as String;
                                    final qty = e['quantidade'] as int;
                                    final fill = qty / maxQty;
                                    return _buildBar(label, fill, qty, isDark);
                                  }).toList(),
                                ),
                    ),
                  ],
                ),
              );

              final rightCol = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dicas de Performance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 24),
                    _buildTipItem(
                      icon: Icons.photo_library_outlined,
                      title: 'Mantenha fotos atualizadas',
                      desc: 'Estabelecimentos com fotos reais geram até 60% mais contatos de WhatsApp.',
                    ),
                    const Divider(height: 24),
                    _buildTipItem(
                      icon: Icons.access_time_outlined,
                      title: 'Configure seus horários',
                      desc: 'Manter os horários em dia evita frustrações de clientes fora do expediente.',
                    ),
                    const Divider(height: 24),
                    _buildTipItem(
                      icon: Icons.stars_outlined,
                      title: 'Peça avaliações',
                      desc: 'Peça para seus clientes avaliarem no app. Melhores notas aparecem no topo.',
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: leftCol),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: rightCol),
                  ],
                );
              }

              return Column(
                children: [
                  leftCol,
                  const SizedBox(height: 24),
                  rightCol,
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Seção de Avaliações Recentes do Lojista
          Card(
            color: cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedbacks e Avaliações de Clientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opiniões de turistas que visitaram seu estabelecimento',
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_recentReviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: secondaryColor.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'Você ainda não possui avaliações.',
                              style: TextStyle(color: secondaryColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentReviews.take(5).map((rev) {
                      final nota = rev['nota'] as int;
                      final comentario = rev['comentario'] as String;
                      final dateVal = rev['created_at'].toString().split('T').first;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.backgroundDark : Colors.grey.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      Icons.star_rounded,
                                      color: starIdx < nota
                                          ? AppTheme.secondaryAmber
                                          : Colors.grey.withOpacity(0.3),
                                      size: 18,
                                    );
                                  }),
                                ),
                                Text(
                                  dateVal,
                                  style: TextStyle(fontSize: 12, color: secondaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comentario.isNotEmpty ? '"$comentario"' : 'Avaliado sem comentário escrito.',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: comentario.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                                color: primaryColor.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryColor),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: secondaryColor.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double fillPercent, int quantity, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$quantity',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 28,
              height: 180 * (fillPercent.isNaN ? 0.0 : fillPercent),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryTeal, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
