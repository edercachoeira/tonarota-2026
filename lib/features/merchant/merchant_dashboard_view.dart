import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../../core/theme/app_theme.dart';

class MerchantDashboardView extends StatelessWidget {
  const MerchantDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final est = Provider.of<Estabelecimento?>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

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
                  children: [
                    Text(
                      '👋 Bem-vindo de volta, ',
                      style: TextStyle(fontSize: 16, color: secondaryColor, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      est?.nomeFantasia ?? 'Lojista',
                      style: const TextStyle(fontSize: 16, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
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
                value: '${est?.totalVisualizacoes ?? 0}',
                subtitle: '+12% esta semana',
                icon: Icons.visibility_outlined,
                color: AppTheme.primaryTeal,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              _buildMetricCard(
                title: 'Avaliação Média',
                value: est?.notaMedia != null && est!.notaMedia > 0 
                    ? est.notaMedia.toStringAsFixed(1) 
                    : 'S/A',
                subtitle: est?.totalAvaliacoes != null && est!.totalAvaliacoes > 0
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
                value: '34', // Simulado
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
                value: '18', // Simulado
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
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
                      // simulated graph bars
                      SizedBox(
                        height: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar('Seg', 0.3, isDark),
                            _buildBar('Ter', 0.45, isDark),
                            _buildBar('Qua', 0.6, isDark),
                            _buildBar('Qui', 0.8, isDark),
                            _buildBar('Sex', 0.95, isDark),
                            _buildBar('Sáb', 0.7, isDark),
                            _buildBar('Dom', 0.5, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width > 950) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Container(
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
                  ),
                ),
              ],
            ],
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

  Widget _buildBar(String label, double fillPercent, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 28,
              height: 200 * fillPercent,
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
