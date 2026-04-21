import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'harian';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'harian',
            label: Text('Harian'),
            icon: Icon(Icons.calendar_today),
          ),
          ButtonSegment(
            value: 'mingguan',
            label: Text('Mingguan'),
            icon: Icon(Icons.date_range),
          ),
          ButtonSegment(
            value: 'bulanan',
            label: Text('Bulanan'),
            icon: Icon(Icons.calendar_month),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (Set<String> selection) {
          setState(() => _selectedPeriod = selection.first);
        },
      ),
    );
  }

  Widget _buildReportContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildPeriodCard(
          title: 'Hari Ini',
          subtitle: DateFormatter.formatFull(DateTime.now()),
          onTap: () => _navigateToDetail('hari_ini'),
        ),
        const SizedBox(height: 12),
        _buildPeriodCard(
          title: 'Kemarin',
          subtitle: DateFormatter.formatFull(DateTime.now().subtract(const Duration(days: 1))),
          onTap: () => _navigateToDetail('kemarin'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Minggu Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPeriodCard(
              title: DateFormatter.formatRelative(date),
              subtitle: DateFormatter.formatFull(date),
              onTap: () => _navigateToDetail(DateFormatter.formatFull(date)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPeriodCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _navigateToDetail(String period) {
    context.push('/reports/detail', extra: {'period': _selectedPeriod, 'date': period});
  }
}
