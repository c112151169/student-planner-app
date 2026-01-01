import 'package:flutter/material.dart';

class TaskEditResult {
  final String title;
  final String date; // YYYY-MM-DD
  final String category;
  TaskEditResult(this.title, this.date, this.category);
}

class TaskEditPage extends StatefulWidget {
  const TaskEditPage({super.key});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final controller = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String category = '作業';

  final categories = const ['作業', '考試', '社團', '其他'];

  String get dateText => selectedDate.toString().substring(0, 10);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增事項')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '事項名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('日期：$dateText')),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('選擇日期'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => category = v ?? '作業'),
              decoration: const InputDecoration(
                labelText: '分類',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  context,
                  TaskEditResult(title, dateText, category),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }
}
