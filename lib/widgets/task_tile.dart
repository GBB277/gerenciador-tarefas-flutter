import 'package:flutter/material.dart';

import '../models/task.dart';

Color priorityColor(Priority p) {
  switch (p) {
    case Priority.alta:
      return const Color(0xFFD32F2F);
    case Priority.media:
      return const Color(0xFFF57C00);
    case Priority.baixa:
      return const Color(0xFF388E3C);
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Trabalho':
      return Icons.work_outline;
    case 'Estudo':
      return Icons.school_outlined;
    case 'Pessoal':
      return Icons.person_outline;
    case 'Saúde':
      return Icons.favorite_border;
    default:
      return Icons.label_outline;
  }
}

String formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// "Hoje", "Amanhã", "Ontem" ou a data no formato dd/mm/aaaa.
String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  return formatDate(d);
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pColor = priorityColor(task.priority);
    final overdue = task.isOverdue;
    final muted = scheme.onSurfaceVariant;

    return Opacity(
      opacity: task.done ? 0.6 : 1,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: overdue ? scheme.error : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: pColor),
                Checkbox(
                  value: task.done,
                  shape: const CircleBorder(),
                  onChanged: (_) => onToggle(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                task.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: muted),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            _Meta(
                              icon: categoryIcon(task.category),
                              text: task.category,
                              color: muted,
                            ),
                            _Meta(
                              icon: Icons.flag,
                              text: task.priority.label,
                              color: pColor,
                            ),
                            if (task.dueDate != null)
                              _Meta(
                                icon: overdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.event_outlined,
                                text: overdue
                                    ? 'Atrasada · ${friendlyDate(task.dueDate!)}'
                                    : friendlyDate(task.dueDate!),
                                color: overdue ? scheme.error : muted,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
