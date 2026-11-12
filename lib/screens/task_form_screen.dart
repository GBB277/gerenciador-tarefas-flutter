import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/task_tile.dart';

/// Tela de criar / editar tarefa. Devolve a [Task] via Navigator.pop,
/// ou o texto 'delete' quando o usuário exclui a tarefa em edição.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _category;
  late Priority _priority;
  DateTime? _dueDate;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? kCategories.first;
    _priority = t?.priority ?? Priority.media;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.task;
    final task = Task(
      id: base?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      priority: _priority,
      done: base?.done ?? false,
      createdAt: base?.createdAt ?? DateTime.now(),
      dueDate: _dueDate,
    );
    Navigator.of(context).pop(task);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: const Text('Você poderá desfazer logo em seguida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop('delete');
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _buildDueChips() {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final due = _dueDate == null ? null : _dateOnly(_dueDate!);
    final isToday = due == today;
    final isTomorrow = due == tomorrow;
    final isCustom = due != null && !isToday && !isTomorrow;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          showCheckmark: false,
          label: const Text('Sem prazo'),
          selected: due == null,
          onSelected: (_) => setState(() => _dueDate = null),
        ),
        ChoiceChip(
          showCheckmark: false,
          label: const Text('Hoje'),
          selected: isToday,
          onSelected: (_) => setState(() => _dueDate = today),
        ),
        ChoiceChip(
          showCheckmark: false,
          label: const Text('Amanhã'),
          selected: isTomorrow,
          onSelected: (_) => setState(() => _dueDate = tomorrow),
        ),
        ChoiceChip(
          showCheckmark: false,
          avatar: const Icon(Icons.event, size: 18),
          label: Text(isCustom ? formatDate(due!) : 'Outra data'),
          selected: isCustom,
          onSelected: (_) => _pickDate(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar tarefa' : 'Nova tarefa'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextFormField(
              controller: _title,
              autofocus: !_editing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ex.: Estudar para a prova',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe um título'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            _sectionTitle('Categoria'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kCategories)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(categoryIcon(c), size: 18),
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            _sectionTitle('Prioridade'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Priority>(
                showSelectedIcon: false,
                segments: [
                  for (final p in Priority.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(Icons.flag, color: priorityColor(p)),
                    ),
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ),
            _sectionTitle('Prazo'),
            _buildDueChips(),
          ],
        ),
      ),
      // Botão de salvar sempre visível, fixo na parte de baixo.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_editing ? 'Salvar alterações' : 'Criar tarefa'),
          ),
        ),
      ),
    );
  }
}
