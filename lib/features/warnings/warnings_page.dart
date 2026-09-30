import 'package:flutter/material.dart';
import 'package:personal_todo/services/warning_service.dart';

class WarningsPage extends StatefulWidget {
  const WarningsPage({super.key});

  @override
  State<WarningsPage> createState() => _WarningsPageState();
}

class _WarningsPageState extends State<WarningsPage> {
  String _content = '';
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await WarningService.instance.readAll();
    final count = await WarningService.instance.getWarningCount();
    if (mounted) {
      setState(() {
        _content = content;
        _count = count;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear warnings?'),
                  content: const Text('This will delete all logged warnings.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await WarningService.instance.clear();
                await _load();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '$_count warning(s) logged',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _content == 'No warnings logged yet.'
                      ? const Center(
                          child: Text(
                            'No warnings logged yet.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            _content,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
