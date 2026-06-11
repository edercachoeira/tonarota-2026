import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha de Boas-vindas
        const Text(
          'Olá, Gestor!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aqui está o resumo geral das atividades e dados do Tô Na Rota.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryLight),
        ),
        const SizedBox(height: 32),

        // Cards de Estatísticas / KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - 48) / 3;
            final isWrap = constraints.maxWidth < 750;

            final children = [
              _buildStatCard(
                context,
                title: 'Balneários Ativos',
                value: '12',
                icon: Icons.beach_access,
                color: AppTheme.primaryTeal,
              ),
              _buildStatCard(
                context,
                title: 'Estabelecimentos',
                value: '45',
                icon: Icons.storefront,
                color: Colors.indigo,
              ),
              _buildStatCard(
                context,
                title: 'Categorias Criadas',
                value: '8',
                icon: Icons.category,
                color: AppTheme.secondaryAmber,
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
        const SizedBox(height: 32),

        // Seção Principal: Dicas de Operação / logs
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atividades Recentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildActivityRow(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          title: 'Novo balneário "Praia da Enseada" cadastrado com sucesso.',
                          time: 'Há 5 minutos',
                        ),
                        _buildActivityRow(
                          icon: Icons.info_outline,
                          color: Colors.blue,
                          title: 'Lojista "Restaurante do Mar" alterou informações de horário.',
                          time: 'Há 2 horas',
                        ),
                        _buildActivityRow(
                          icon: Icons.star_border,
                          color: Colors.orange,
                          title: 'Nova avaliação pendente de moderação para "Quiosque do Sol".',
                          time: 'Há 1 dia',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
                  ),
                ],
              ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryLight),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}
