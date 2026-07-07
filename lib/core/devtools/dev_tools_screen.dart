import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'dev_log_store.dart';

/// Панель разработчика: список HTTP-вызовов и логов приложения в реальном
/// времени. Открывается через плавающую шестерёнку ([DevToolsOverlay]) —
/// доступна только в dev-сборках (`AppConfig.devToolsEnabled`).
class DevToolsScreen extends StatelessWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dev Tools · ${AppConfig.appVersion}'),
        actions: [
          IconButton(
            tooltip: 'Скопировать всё',
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () => _copyAll(context),
          ),
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: devLogStore.clear,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: devLogStore,
        builder: (context, _) {
          final events = devLogStore.events;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Пока пусто.\nВыполните запрос в приложении.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.outline),
            itemBuilder: (context, index) {
              final event = events[index];
              if (event is DevHttpCall) return _HttpTile(call: event);
              if (event is DevLogLine) return _LogTile(line: event);
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  void _copyAll(BuildContext context) {
    final buffer = StringBuffer();
    for (final event in devLogStore.events.toList().reversed) {
      if (event is DevHttpCall) {
        buffer.writeln(_httpSummary(event));
      } else if (event is DevLogLine) {
        buffer.writeln('[${_time(event.timestamp)}] ${event.message}');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Лог скопирован')),
    );
  }
}

class _HttpTile extends StatelessWidget {
  const _HttpTile({required this.call});

  final DevHttpCall call;

  Color get _statusColor {
    if (call.isPending) return AppColors.textSecondary;
    if (call.isError) return AppColors.danger;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final path = Uri.tryParse(call.url)?.path ?? call.url;
    final status = call.isPending
        ? '…'
        : (call.error != null ? (call.statusCode?.toString() ?? 'ERR') : '${call.statusCode}');
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _statusColor.withValues(alpha: 0.15),
        child: Text(
          status,
          style: TextStyle(
            color: _statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        '${call.method} $path',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_time(call.startedAt)}'
        '${call.duration != null ? ' · ${call.duration!.inMilliseconds} мс' : ''}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _HttpDetailScreen(call: call)),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.line});

  final DevLogLine line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.terminal_rounded, color: AppColors.textSecondary),
      title: Text(
        line.message,
        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
      ),
      subtitle: Text(
        _time(line.timestamp),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _HttpDetailScreen extends StatelessWidget {
  const _HttpDetailScreen({required this.call});

  final DevHttpCall call;

  @override
  Widget build(BuildContext context) {
    final text = _httpSummary(call);
    return Scaffold(
      appBar: AppBar(
        title: Text(call.method),
        actions: [
          IconButton(
            tooltip: 'Скопировать',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скопировано')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
        ),
      ),
    );
  }
}

String _httpSummary(DevHttpCall call) {
  final buffer = StringBuffer()
    ..writeln('${call.method} ${call.url}')
    ..writeln('Начало: ${_time(call.startedAt)}')
    ..writeln(
      'Статус: ${call.statusCode ?? (call.isPending ? "..." : "-")}'
      '${call.duration != null ? " (${call.duration!.inMilliseconds} мс)" : ""}',
    );
  if (call.error != null) buffer.writeln('Ошибка: ${call.error}');
  buffer.writeln('\n— Заголовки запроса —');
  call.requestHeaders?.forEach((k, v) => buffer.writeln('$k: $v'));
  if (call.requestBody != null) {
    buffer.writeln('\n— Тело запроса —');
    buffer.writeln(call.requestBody);
  }
  buffer.writeln('\n— Заголовки ответа —');
  call.responseHeaders?.forEach((k, v) => buffer.writeln('$k: $v'));
  if (call.responseBody != null) {
    buffer.writeln('\n— Тело ответа —');
    buffer.writeln(call.responseBody);
  }
  return buffer.toString();
}

String _time(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
