import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class AuditoriaView extends StatefulWidget {
  const AuditoriaView({super.key});

  @override
  State<AuditoriaView> createState() => _AuditoriaViewState();
}

class _AuditoriaViewState extends State<AuditoriaView> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = false;
  String? _error;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedAcao = 'Todos';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _acoesList = [
    'Todos',
    'LOGIN',
    'REGISTRO_CONTA',
    'ATUALIZAR_PERFIL',
    'CRIAR_BALNEARIO',
    'EDITAR_BALNEARIO',
    'EXCLUIR_BALNEARIO',
    'CRIAR_CATEGORIA',
    'EDITAR_CATEGORIA',
    'EXCLUIR_CATEGORIA',
    'EXCLUIR_GESTOR'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, String> queryParameters = {};
      
      if (_searchController.text.trim().isNotEmpty) {
        queryParameters['search'] = _searchController.text.trim();
      }
      
      if (_selectedAcao != 'Todos') {
        queryParameters['acao'] = _selectedAcao;
      }
      
      if (_startDate != null) {
        queryParameters['data_inicio'] = _startDate!.toIso8601String().substring(0, 10);
      }
      
      if (_endDate != null) {
        queryParameters['data_fim'] = _endDate!.toIso8601String().substring(0, 10);
      }

      final uriString = Uri(path: '/v1/auditoria', queryParameters: queryParameters).toString();
      final res = await _apiService.get(uriString);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List;
        setState(() {
          _logs = data;
          _isLoading = false;
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['error'] ?? 'Erro ao carregar logs do servidor.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao se conectar ao servidor.';
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedAcao = 'Todos';
      _startDate = null;
      _endDate = null;
    });
    _fetchLogs();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: isStart ? 'DATA INICIAL' : 'DATA FINAL',
      cancelText: 'CANCELAR',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Se data final for anterior à inicial, corrige
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
      _fetchLogs();
    }
  }

  Color _getActionColor(String acao) {
    if (acao.startsWith('CRIAR')) return Colors.green;
    if (acao.startsWith('EDITAR') || acao == 'ATUALIZAR_PERFIL') return Colors.blue;
    if (acao.startsWith('EXCLUIR')) return Colors.redAccent;
    if (acao == 'LOGIN') return Colors.teal;
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final secondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Logs de Auditoria & Rastreamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Recarregar Logs',
                  onPressed: _fetchLogs,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Limpar Filtros'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Painel de Filtros Avançados
        Card(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, color: AppTheme.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros de Auditoria',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    
                    final fields = [
                      // Busca textual
                      Expanded(
                        flex: isNarrow ? 0 : 3,
                        child: TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por usuário ou detalhes...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onFieldSubmitted: (_) => _fetchLogs(),
                        ),
                      ),
                      if (isNarrow) const SizedBox(height: 12),
                      // Dropdown de Ação
                      Expanded(
                        flex: isNarrow ? 0 : 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedAcao,
                          decoration: const InputDecoration(
                            labelText: 'Ação Realizada',
                            prefixIcon: Icon(Icons.settings_outlined),
                          ),
                          items: _acoesList.map((acao) {
                            return DropdownMenuItem(
                              value: acao,
                              child: Text(acao),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAcao = val;
                              });
                              _fetchLogs();
                            }
                          },
                        ),
                      ),
                      if (isNarrow) const SizedBox(height: 12),
                      // Período: dois campos compactos lado a lado
                      Expanded(
                        flex: isNarrow ? 0 : 3,
                        child: Row(
                          children: [
                            // Data Inicial
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _pickDate(isStart: true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'De',
                                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _startDate != null ? _formatDate(_startDate!) : 'Início',
                                    style: TextStyle(color: primaryColor, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Data Final
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _pickDate(isStart: false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Até',
                                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _endDate != null ? _formatDate(_endDate!) : 'Final',
                                    style: TextStyle(color: primaryColor, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            // Limpar
                            if (_startDate != null || _endDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Limpar período',
                                onPressed: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                  _fetchLogs();
                                },
                              ),
                          ],
                        ),
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: fields.map((f) => f is Expanded ? f.child : f).toList(),
                      );
                    }

                    return Row(
                      children: fields.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(width: constraints.maxWidth / 3.3, child: f),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de Logs de Auditoria
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchLogs, child: const Text('Tentar Novamente')),
                ],
              ),
            ),
          )
        else if (_logs.isEmpty)
          Expanded(
            child: Center(
              child: Text('Nenhum log de auditoria encontrado.', style: TextStyle(color: secondaryColor)),
            ),
          )
        else
          Expanded(
            child: Card(
              color: cardBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final acao = log['acao'] as String;
                    final actionColor = _getActionColor(acao);
                    
                    // Formatação da data para visualização humana
                    final parsedDate = DateTime.parse(log['created_at'] as String).toLocal();
                    final timeStr = '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: actionColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          acao,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      title: Text(
                        log['detalhes'] ?? 'Sem detalhes',
                        style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14, color: secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              log['usuario_nome'] as String,
                              style: TextStyle(color: secondaryColor, fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time_rounded, size: 14, color: secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(color: secondaryColor, fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.lan_outlined, size: 14, color: secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'IP: ${log['ip']}',
                              style: TextStyle(color: secondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
