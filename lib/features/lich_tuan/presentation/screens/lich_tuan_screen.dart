// lib/features/lich_tuan/presentation/screens/lich_tuan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/lich_tuan_entity.dart';
import '../providers/lich_tuan_provider.dart';

class LichTuanScreen extends ConsumerStatefulWidget {
  const LichTuanScreen({super.key});

  @override
  ConsumerState<LichTuanScreen> createState() => _LichTuanScreenState();
}

class _LichTuanScreenState extends ConsumerState<LichTuanScreen> {
  final _dayFmt = DateFormat('EEEE, dd/MM/yyyy', 'vi');
  final _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(lichTuanProvider.notifier).loadCurrentMonth());
    // Schedule reminders after data loads
    ref.listenManual(lichTuanProvider, (_, next) {
      next.whenData((list) {
        NotificationService.scheduleWeeklyScheduleReminders(list);
      });
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      locale: const Locale('vi'),
    );
    if (picked != null) {
      ref
          .read(lichTuanProvider.notifier)
          .fetch(start: picked.start, end: picked.end);
    }
  }

  bool _isToday(DateTime date) =>
      date.year == _today.year &&
      date.month == _today.month &&
      date.day == _today.day;

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(lichTuanGroupedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch tuần'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Chọn khoảng thời gian',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => ref.read(lichTuanProvider.notifier).refresh(),
          ),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('Không tải được lịch tuần\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(lichTuanProvider.notifier).refresh(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (grouped) {
          if (grouped.isEmpty) {
            return const Center(child: Text('Không có lịch trong khoảng thời gian này'));
          }
          final dates = grouped.keys.toList()..sort();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final events = grouped[date]!;
              final isToday = _isToday(date);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (isToday) ...[
                          Icon(Icons.today,
                              size: 18,
                              color: colorScheme.onPrimaryContainer),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _dayFmt.format(date).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isToday
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Hôm nay',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Events for this date
                  ...events.map((e) => _EventCard(
                        event: e,
                        isToday: isToday,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  const _EventCard({required this.event, required this.isToday});
  final LichTuanEntity event;
  final bool isToday;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.isToday) return cs.primaryContainer;
    return cs.surfaceContainerLow;
  }

  String _ttLabel(String tt) {
    switch (tt) {
      case 'BT':
        return 'Bình thường';
      case 'BS':
        return 'Bổ sung';
      case 'TD':
        return 'Thay đổi';
      default:
        return tt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final event = widget.event;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      color: _statusColor(context),
      elevation: widget.isToday ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: widget.isToday
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time + duration row
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    event.gio,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('(${event.thoiGian})',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (event.thayDoi.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _ttLabel(event.tt),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Subject
              Text(
                event.noiDung,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: _expanded ? null : 2,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: colorScheme.outline),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      event.diaDiem,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Host
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: colorScheme.outline),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      'Chủ trì: ${event.chuTri}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Expanded: participant detail (HTML)
              if (_expanded && event.thamGiaChitiet.isNotEmpty) ...[
                const Divider(height: 16),
                Text('Thành phần tham gia:',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Html(
                  data: event.thamGiaChitiet,
                  style: {
                    'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(13)),
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
