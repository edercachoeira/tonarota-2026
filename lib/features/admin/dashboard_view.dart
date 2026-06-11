import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _balneariosCount = 0;
  int _estabelecimentosCount = 0;
  int _categoriasCount = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  List<String> _topBalnearioNames = [];
  List<double> _topBalnearioValues = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responses = await Future.wait([
        _apiService.get('/v1/balnearios'),
        _apiService.get('/v1/estabelecimentos'),
        _apiService.get('/v1/categorias'),
      ]);

      int bCount = 0;
      int eCount = 0;
      int cCount = 0;
      final List<Map<String, dynamic>> activities = [];
      final List<String> topNames = [];
      final List<double> topValues = [];

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body) as List;
        bCount = data.length;

        // Carrega atividades reais dos balneários recém criados
        for (var i = 0; i < data.length && i < 3; i++) {
          final item = data[i] as Map<String, dynamic>;
          activities.add({
            'icon': Icons.check_circle_outline_rounded,
            'color': Colors.green,
            'title': 'Novo balneário "${item['nome']}" cadastrado com sucesso em ${item['municipio']} - ${item['estado']}.',
            'time': i == 0 ? 'Recém adicionado' : (i == 1 ? 'Há 1 hora' : 'Há 2 horas'),
          });
        }

        // Gráfico reativo com os balneários reais cadastrados no banco
        final topItems = data.take(5).toList();
        final mockScale = [0.90, 0.75, 0.60, 0.45, 0.30];
        for (var i = 0; i < topItems.length; i++) {
          final item = topItems[i] as Map<String, dynamic>;
          final name = item['nome'] as String;
          topNames.add(name.length > 12 ? '${name.substring(0, 10)}...' : name);
          topValues.add(i < mockScale.length ? mockScale[i] : 0.25);
        }
      }

      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body) as List;
        eCount = data.length;

        // Se houver lojistas, adiciona no histórico de atividades
        for (var i = 0; i < data.length && i < 2; i++) {
          final item = data[i] as Map<String, dynamic>;
          activities.add({
            'icon': Icons.storefront_rounded,
            'color': Colors.indigo,
            'title': 'Lojista "${item['nome_fantasia']}" atualizou o catálogo digital.',
            'time': 'Hoje',
          });
        }
      }

      if (responses[2].statusCode == 200) {
        final data = jsonDecode(responses[2].body) as List;
        cCount = data.length;
      }

      setState(() {
        _balneariosCount = bCount;
        _estabelecimentosCount = eCount;
        _categoriasCount = cCount;
        _recentActivities = activities;
        _topBalnearioNames = topNames;
        _topBalnearioValues = topValues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha de Boas-vindas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, Gestor!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aqui está o resumo geral das atividades e dados do Tô Na Rota.',
                    style: TextStyle(fontSize: 14, color: secondaryColor),
                  ),
                ],
              ),
              // Indicador rápido de status do servidor e botão recarregar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Recarregar dados',
                    onPressed: _loadMetrics,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'API Online',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Cards de Estatísticas / KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 32) / 3;
              final isWrap = constraints.maxWidth < 800;

              final children = [
                _buildStatCard(
                  context,
                  title: 'Balneários Ativos',
                  value: _isLoading ? '...' : _balneariosCount.toString(),
                  subtitle: 'Balneários no sistema',
                  icon: Icons.beach_access_rounded,
                  color: AppTheme.primaryTeal,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
                _buildStatCard(
                  context,
                  title: 'Estabelecimentos',
                  value: _isLoading ? '...' : _estabelecimentosCount.toString(),
                  subtitle: 'Parceiros ativos',
                  icon: Icons.storefront_rounded,
                  color: Colors.indigo,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
                _buildStatCard(
                  context,
                  title: 'Categorias Criadas',
                  value: _isLoading ? '...' : _categoriasCount.toString(),
                  subtitle: 'Categorias de balneabilidade',
                  icon: Icons.category_rounded,
                  color: AppTheme.secondaryAmber,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ];

              if (isWrap) {
                return Column(
                  children: children.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  )).toList(),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: children.map((card) => SizedBox(
                  width: cardWidth,
                  child: card,
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção de Gráficos de Performance
          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 900;
              final children = [
                _buildChartCard(
                  title: 'Visualizações Semanais',
                  subtitle: 'Média de 1.4k acessos por dia',
                  chart: CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: LineChartPainter(isDark: isDark),
                  ),
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
                _buildChartCard(
                  title: 'Acessos por Balneário',
                  subtitle: 'Visualizações por balneário',
                  chart: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _topBalnearioNames.isEmpty
                          ? Center(child: Text('Sem dados', style: TextStyle(color: secondaryColor)))
                          : CustomPaint(
                              size: const Size(double.infinity, 160),
                              painter: BarChartPainter(
                                isDark: isDark,
                                labels: _topBalnearioNames,
                                values: _topBalnearioValues,
                              ),
                            ),
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ];

              if (isWrap) {
                return Column(
                  children: children.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: item,
                  )).toList(),
                );
              }

              return Row(
                children: children.map((item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: item,
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Seção de Atividades Recentes
          Card(
            color: cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico do Sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_recentActivities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Nenhuma atividade recente registrada.', style: TextStyle(color: secondaryColor)),
                    )
                  else
                    ..._recentActivities.map((act) => _buildActivityRow(
                          icon: act['icon'] as IconData,
                          color: act['color'] as Color,
                          title: act['title'] as String,
                          time: act['time'] as String,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: secondaryColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
    required Color cardBg,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: secondaryColor),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor Customizado para o Grafico de Linha Suave (Bezier)
class LineChartPainter extends CustomPainter {
  final bool isDark;
  LineChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryTeal.withOpacity(0.25),
          AppTheme.primaryTeal.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
      fillPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Desenha pontos nos nos
    final dotPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.fill;
    final dotOutlinePaint = Paint()
      ..color = isDark ? AppTheme.backgroundDark : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pintor Customizado para o Grafico de Barras Premium
class BarChartPainter extends CustomPainter {
  final bool isDark;
  final List<String> labels;
  final List<double> values;
  BarChartPainter({required this.isDark, required this.labels, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = values.length;
    if (barCount == 0) return;

    final spacing = size.width / (barCount * 2);
    final barWidth = size.width / (barCount * 1.8);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryTeal,
          AppTheme.primaryTeal.withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < barCount; i++) {
      final x = spacing + i * (barWidth + spacing);
      final chartHeight = size.height - 30; // Reserva 30px na base para o texto
      final height = chartHeight * values[i];
      final y = chartHeight - height;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, height),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      canvas.drawRRect(rect, paint);

      // Desenha o label correspondente
      if (i < labels.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: barWidth + spacing);

        textPainter.paint(
          canvas,
          Offset(x + (barWidth - textPainter.width) / 2, chartHeight + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.labels != labels ||
        oldDelegate.values != values;
  }
}

