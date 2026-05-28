import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../services/history_service.dart';
import 'severity_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<AccidentReport> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(int index) async {
    await _historyService.deleteReport(index);
    _loadHistory();
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('INCIDENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.primaryRed),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _history.isEmpty
              ? const Center(child: Text("No incident history found.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDesign.standardPadding),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final report = _history[index];
                    return Dismissible(
                      key: Key(report.timestamp.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteReport(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.primaryRed,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        color: AppColors.surfaceCard,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeverityResultScreen(report: report, isFromHistory: true),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: report.severity == Severity.critical
                                ? AppColors.criticalRed
                                : (report.severity == Severity.moderate ? AppColors.warningOrange : AppColors.successGreen),
                            child: Icon(
                              report.severity == Severity.critical
                                  ? Icons.report_gmailerrorred_rounded
                                  : (report.severity == Severity.moderate ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            "${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year} ${report.timestamp.hour}:${report.timestamp.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(report.locationName, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
