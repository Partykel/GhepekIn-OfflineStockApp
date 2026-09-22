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
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pilih tanggal',
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Kembali ke hari ini',
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateBanner(),
          _buildPeriodSelector(),
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Periode dasar: ${DateFormatter.formatFull(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
    final baseDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    switch (_selectedPeriod) {
      case 'mingguan':
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildPeriodCard(
              title: '7 Hari dari Tanggal Dipilih',
              subtitle: DateFormatter.formatFull(baseDate),
              onTap: () => _navigateToDetail(baseDate, '7 Hari dari Tanggal Dipilih'),
            ),
            const SizedBox(height: 12),
            _buildPeriodCard(
              title: '6 Hari Sebelumnya',
              subtitle: DateFormatter.formatFull(baseDate.subtract(const Duration(days: 6))),
              onTap: () => _navigateToDetail(baseDate.subtract(const Duration(days: 6)), '6 Hari Sebelumnya'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Harian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (index) {
              final date = baseDate.subtract(Duration(days: 6 - index));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPeriodCard(
                  title: DateFormatter.formatRelative(date),
                  subtitle: DateFormatter.formatFull(date),
                  onTap: () => _navigateToDetail(date, DateFormatter.formatFull(date)),
                ),
              );
            }),
          ],
        );

      case 'bulanan':
        final monthLabel = DateFormatter.formatMonthYear(baseDate);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildPeriodCard(
              title: 'Bulan $monthLabel',
              subtitle: 'Data transaksi pada bulan yang dipilih',
              onTap: () => _navigateToDetail(baseDate, 'Bulan $monthLabel'),
            ),
            const SizedBox(height: 12),
            _buildPeriodCard(
              title: 'Rangkuman Mingguan',
              subtitle: '4 minggu dalam bulan terpilih',
              onTap: () => _navigateToDetail(baseDate, 'Rangkuman Mingguan'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mingguan Bulan Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (index) {
              final weekLabel = 'Minggu ${index + 1}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPeriodCard(
                  title: weekLabel,
                  subtitle: 'Periode agregasi mingguan',
                  onTap: () => _navigateToDetail(baseDate, weekLabel),
                ),
              );
            }),
          ],
        );

      default:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildPeriodCard(
              title: 'Tanggal Dipilih',
              subtitle: DateFormatter.formatFull(baseDate),
              onTap: () => _navigateToDetail(baseDate, 'Tanggal Dipilih'),
            ),
            const SizedBox(height: 12),
            _buildPeriodCard(
              title: 'Sehari Sebelumnya',
              subtitle: DateFormatter.formatFull(baseDate.subtract(const Duration(days: 1))),
              onTap: () => _navigateToDetail(baseDate.subtract(const Duration(days: 1)), 'Sehari Sebelumnya'),
            ),
            const SizedBox(height: 24),
            const Text(
              '7 Hari Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (index) {
              final date = baseDate.subtract(Duration(days: 6 - index));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPeriodCard(
                  title: DateFormatter.formatRelative(date),
                  subtitle: DateFormatter.formatFull(date),
                  onTap: () => _navigateToDetail(date, DateFormatter.formatFull(date)),
                ),
              );
            }),
          ],
        );
    }
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

  void _navigateToDetail(DateTime date, String label) {
    final iso = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.push('/reports/detail', extra: {
      'period': _selectedPeriod,
      'date': iso,
      'label': label,
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }
}
