import 'package:flutter/material.dart';
import '../db/app_db.dart';
import 'task_edit_page.dart';

class Task {
  final int id;
  final String title;
  final String date; // YYYY-MM-DD
  final String category;
  bool done;

  Task(this.id, this.title, this.date, this.category, this.done);
}

class TaskListPage extends StatefulWidget {
  final ThemeMode themeMode;
  final Future<void> Function() onToggleTheme;

  const TaskListPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final db = AppDb.instance;

  List<Task> _all = [];
  bool _loading = true;

  String _search = '';
  String _status = '全部'; // 全部/未完成/已完成
  String _sort = '日期'; // 日期/新增

  final _statusOptions = const ['全部', '未完成', '已完成'];
  final _sortOptions = const ['日期', '新增'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final orderBy = _sort == '新增'
        ? 'created_at DESC, id DESC'
        : 'date ASC, id DESC';
    final rows = await db.getTasks(orderBy: orderBy);

    _all = rows
        .map(
          (e) => Task(
            e['id'] as int,
            e['title'] as String,
            (e['date'] as String?) ??
                DateTime.now().toString().substring(0, 10),
            (e['category'] as String?) ?? '其他',
            (e['done'] as int) == 1,
          ),
        )
        .toList();

    setState(() => _loading = false);
  }

  List<Task> get _shown {
    Iterable<Task> t = _all;

    if (_status == '未完成') t = t.where((x) => !x.done);
    if (_status == '已完成') t = t.where((x) => x.done);

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      t = t.where((x) => x.title.toLowerCase().contains(q));
    }

    return t.toList();
  }

  int get _todayCount {
    final today = DateTime.now().toString().substring(0, 10);
    return _all.where((t) => t.date == today && !t.done).length;
  }

  int get _weekCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));

    bool inNext7Days(String ymd) {
      final d = DateTime.tryParse(ymd);
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      return (dd.isAtSameMomentAs(start) || dd.isAfter(start)) &&
          dd.isBefore(end);
    }

    return _all.where((t) => !t.done && inNext7Days(t.date)).length;
  }

  Color _badgeColor(String cat, BuildContext context) {
    switch (cat) {
      case '作業':
        return Colors.blue;
      case '考試':
        return Colors.red;
      case '社團':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<TaskEditResult>(
      context,
      MaterialPageRoute(builder: (_) => const TaskEditPage()),
    );
    if (result != null) {
      await db.addTask(
        title: result.title,
        date: result.date,
        category: result.category,
      );
      await _load();
    }
  }

  Future<void> _toggleDone(Task t, bool v) async {
    t.done = v;
    await db.updateDone(t.id, v);
    setState(() {});
  }

  Future<void> _delete(Task t) async {
    await db.deleteTask(t.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    final isDark =
        widget.themeMode == ThemeMode.dark ||
        (widget.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('校園生活提醒'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '深色模式切換',
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // 統計卡
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '今天未完成',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_todayCount 件',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '7 天內未完成',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_weekCount 件',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 搜尋列
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '搜尋事項名稱…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),

                  const SizedBox(height: 10),

                  // 篩選 + 排序
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          items: _statusOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _status = v ?? '全部'),
                          decoration: InputDecoration(
                            labelText: '篩選',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sort,
                          items: _sortOptions
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) async {
                            setState(() => _sort = v ?? '日期');
                            await _load();
                          },
                          decoration: InputDecoration(
                            labelText: '排序',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: Text('目前沒有符合的事項')),
                    )
                  else
                    ...shown.map((t) {
                      final badgeColor = _badgeColor(t.category, context);

                      return Dismissible(
                        key: ValueKey('task_${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('刪除事項'),
                                  content: Text('確定要刪除「${t.title}」嗎？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('刪除'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _delete(t),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: t.done,
                              onChanged: (v) => _toggleDone(t, v ?? false),
                            ),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: t.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: t.done ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: badgeColor.withOpacity(0.4),
                                      ),
                                      color: badgeColor.withOpacity(0.12),
                                    ),
                                    child: Text(
                                      t.category,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.calendar_month, size: 16),
                                  const SizedBox(width: 4),
                                  Text(t.date),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 70),
                ],
              ),
            ),
    );
  }
}
