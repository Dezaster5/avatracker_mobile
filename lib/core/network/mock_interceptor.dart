import 'package:dio/dio.dart';

import '../utils/formatters.dart';

/// Mock-режим API (`--dart-define=MOCK_API=true`): обслуживает все
/// эндпоинты из ТЗ локально, чтобы демонстрировать приложение без бэкенда.
///
/// Особенности:
/// - SMS-код всегда `1234` (любой другой -> «Неверный SMS-код»);
/// - предзаведен демо-аккаунт: +7 700 123 45 67, пароль `123456`;
/// - регистрация создает аккаунт в памяти (телефон + ИИН + пароль);
/// - FaceID всегда успешен (match 94.5%) и выдает одноразовый токен для QR;
/// - QR с подстрокой `far` имитирует отказ «вне радиуса» (ТЗ 28);
/// - QR с подстрокой `inactive` имитирует отключенную точку;
/// - отметки за сегодня хранятся в памяти: первая — приход, вторая — уход,
///   далее — проверка присутствия (ТЗ 8); табель учитывает отметки;
/// - у демо-сотрудника индивидуальный график 08:00–17:00 с обедом 13:00–14:00.
class MockInterceptor extends Interceptor {
  static const _park = 'AVATARIYA Karaganda';
  static const _code = '1234';
  static const _workStart = '08:00';
  static const _workEnd = '17:00';
  static const _lunchStart = '13:00';
  static const _lunchEnd = '14:00';
  static const _workDayMinutes = 480;

  /// Зарегистрированные аккаунты: телефон -> {iin, password}.
  static final Map<String, Map<String, String>> _accounts = {
    '+77001234567': {'iin': '990101300123', 'password': '123456'},
  };

  /// Телефон текущей сессии (для смены пароля).
  static String? _sessionPhone;

  static final List<Map<String, dynamic>> _todayMarks = [];

  /// Одноразовые FaceID-токены: token -> QR ID.
  static final Map<String, String> _faceTokens = {};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final path = options.path;
    final body = options.data is Map ? (options.data as Map) : const {};

    switch (path) {
      case '/mobile/auth/register/send-code':
        return _ok(
            handler, options, {'success': true, 'message': 'SMS code sent'});

      case '/mobile/auth/register/verify':
        final phone = '${body['phone']}';
        if ('${body['code']}' != _code) {
          return _fail(handler, options, 400,
              {'success': false, 'message': 'Неверный SMS-код'});
        }
        _accounts[phone] = {
          'iin': '${body['iin']}',
          'password': '${body['password']}',
        };
        _sessionPhone = phone;
        return _ok(handler, options, _session(phone));

      case '/mobile/auth/login':
        final phone = '${body['phone']}';
        final account = _accounts[phone];
        if (account == null) {
          return _fail(handler, options, 404, {
            'success': false,
            'message': 'Аккаунт не найден. Зарегистрируйтесь',
          });
        }
        if (account['password'] != '${body['password']}') {
          return _fail(handler, options, 400, {
            'success': false,
            'message': 'Неверный номер телефона или пароль',
          });
        }
        _sessionPhone = phone;
        return _ok(handler, options, _session(phone));

      case '/mobile/auth/password/forgot':
        if (!_accounts.containsKey('${body['phone']}')) {
          return _fail(handler, options, 404, {
            'success': false,
            'message': 'Аккаунт с этим номером не найден',
          });
        }
        return _ok(
            handler, options, {'success': true, 'message': 'SMS code sent'});

      case '/mobile/auth/password/verify-code':
        if ('${body['code']}' != _code) {
          return _fail(handler, options, 400,
              {'success': false, 'message': 'Неверный SMS-код'});
        }
        return _ok(handler, options, {'success': true});

      case '/mobile/auth/password/reset':
        final phone = '${body['phone']}';
        final account = _accounts[phone];
        if ('${body['code']}' != _code) {
          return _fail(handler, options, 400,
              {'success': false, 'message': 'Неверный SMS-код'});
        }
        if (account == null) {
          return _fail(handler, options, 404, {
            'success': false,
            'message': 'Аккаунт с этим номером не найден',
          });
        }
        account['password'] = '${body['new_password']}';
        return _ok(
            handler, options, {'success': true, 'message': 'Пароль изменен'});

      case '/mobile/auth/password/change':
        final account = _sessionPhone == null ? null : _accounts[_sessionPhone];
        if (account == null) {
          return _fail(handler, options, 401,
              {'success': false, 'message': 'Сессия истекла. Войдите заново'});
        }
        if (account['password'] != '${body['current_password']}') {
          return _fail(handler, options, 400,
              {'success': false, 'message': 'Текущий пароль неверен'});
        }
        account['password'] = '${body['new_password']}';
        return _ok(
            handler, options, {'success': true, 'message': 'Пароль изменен'});

      case '/mobile/auth/refresh':
        return _ok(handler, options, {
          'success': true,
          'access_token':
              'mock_access_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token': 'mock_refresh',
        });

      case '/mobile/auth/face-verify':
        final qrId = '${body['qr_id'] ?? ''}';
        final token = 'mock_face_${DateTime.now().microsecondsSinceEpoch}';
        _faceTokens[token] = qrId;
        return _ok(handler, options, {
          'success': true,
          'match_percent': 94.5,
          'access_granted': true,
          'verification_token': token,
        });

      case '/mobile/attendance/scan':
        return _scan(handler, options);

      case '/mobile/attendance/timesheet':
        final month =
            options.queryParameters['month']?.toString() ?? _currentMonth();
        return _ok(handler, options, _timesheet(month));

      case '/tardiness/':
        final iin =
            options.queryParameters['iin']?.toString() ?? '990101300123';
        final periodFrom = _parseDate(
          options.queryParameters['period_from']?.toString(),
        );
        final periodTo = _parseDate(
          options.queryParameters['period_to']?.toString(),
        );
        return _ok(handler, options, _tardiness(iin, periodFrom, periodTo));
    }

    if (path.startsWith('/employees/')) {
      final iin = path.split('/').where((s) => s.isNotEmpty).last;
      return _ok(handler, options, _employee(iin));
    }

    if (path.startsWith('/mobile/qr-points/')) {
      final qrId = path.split('/').where((s) => s.isNotEmpty).last;
      return _ok(handler, options, {
        'id': qrId,
        'name': 'Главный вход',
        'park': _park,
        'city': 'Karaganda',
        'address': 'пр. Республики 11, Караганда',
        'latitude': 49.8047,
        'longitude': 73.1094,
        'allowed_radius': 50,
        'is_active': true,
      });
    }

    // Незамоканный путь — отдаем 404, чтобы это было заметно при разработке.
    return _fail(handler, options, 404,
        {'message': 'Mock: эндпоинт $path не реализован'});
  }

  /// Ответ авторизации: токены + сотрудник.
  Map<String, dynamic> _session(String phone) {
    final iin = _accounts[phone]?['iin'] ?? '990101300123';
    return {
      'success': true,
      'access_token': 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token': 'mock_refresh',
      'employee': _employee(iin, phone: phone),
    };
  }

  void _scan(RequestInterceptorHandler handler, RequestOptions options) {
    final data = options.data;
    final qrId = data is Map ? '${data['qr_id'] ?? ''}' : '';
    final faceToken =
        data is Map ? '${data['face_verification_token'] ?? ''}' : '';

    if (_faceTokens.remove(faceToken) != qrId) {
      return _fail(handler, options, 400, {
        'success': false,
        'error_code': 'FACE_REQUIRED',
        'message': 'Подтвердите личность перед отметкой',
      });
    }

    if (qrId.contains('inactive')) {
      return _fail(handler, options, 400, {
        'success': false,
        'error_code': 'QR_INACTIVE',
        'message': 'Эта точка отметки отключена',
      });
    }
    if (qrId.contains('far')) {
      return _fail(handler, options, 400, {
        'success': false,
        'error_code': 'OUT_OF_RADIUS',
        'message': 'Вы находитесь далеко от точки отметки',
        'distance_meters': 184,
        'allowed_radius': 50,
      });
    }

    final now = DateTime.now();
    _todayMarks.removeWhere((m) {
      final t = DateTime.tryParse('${m['scanned_at']}');
      return t == null ||
          t.year != now.year ||
          t.month != now.month ||
          t.day != now.day;
    });

    final markType = switch (_todayMarks.length) {
      0 => 'check_in',
      1 => 'check_out',
      _ => 'presence',
    };
    _todayMarks.add({
      'scanned_at': isoWithOffset(now),
      'mark_type': markType,
      'park': _park,
    });

    return _ok(handler, options, {
      'success': true,
      'mark_type': markType,
      'message': 'Отметка успешно засчитана',
      'distance_meters': 12,
      'park': _park,
      'scanned_at': isoWithOffset(now),
    });
  }

  Map<String, dynamic> _employee(String iin, {String? phone}) => {
        'id': 1,
        'iin': iin,
        'full_name': 'Сериков Айдос Бекжанович',
        'photo': 'https://i.pravatar.cc/300?img=12',
        'active': true,
        'phone': phone ?? '+77001234567',
        'position': {'name': 'Оператор аттракционов'},
        'division': {'name': 'Отдел аттракционов'},
        'employee_organization': {'name': 'ТОО «AVATARIYA»'},
        'park_id': 5000011,
        'park_name': _park,
        'city': 'Караганда',
      };

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Минуты, отработанные с 08:00 до [now] этого дня, без обеда 13:00–14:00.
  static int _workedByNow(DateTime day, DateTime now) {
    final start = DateTime(day.year, day.month, day.day, 8);
    final lunchStart = DateTime(day.year, day.month, day.day, 13);
    final lunchEnd = DateTime(day.year, day.month, day.day, 14);
    var minutes = now.difference(start).inMinutes;
    if (now.isAfter(lunchStart)) {
      final lunchOverlap = (now.isBefore(lunchEnd) ? now : lunchEnd)
          .difference(lunchStart)
          .inMinutes;
      minutes -= lunchOverlap;
    }
    return minutes.clamp(0, _workDayMinutes);
  }

  /// День прихода/ухода для прошедших дат: детерминированный паттерн —
  /// каждый 9-й день пропуск, каждый 4-й опоздание, остальные вовремя.
  /// Норма демо-сотрудника — 480 минут (8 ч), обед не учитывается.
  Map<String, dynamic> _timesheet(String month) {
    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const norm = _workDayMinutes;

    final days = <Map<String, dynamic>>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, m, d);
      final dateStr =
          '$year-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final isWeekend = date.weekday >= DateTime.saturday;
      final isFuture = date.isAfter(today);
      final isToday = date == today;

      String status;
      var worked = 0;
      var remaining = isWeekend ? 0 : norm;
      var scans = <Map<String, dynamic>>[];

      if (isWeekend) {
        status = 'weekend';
      } else if (isFuture) {
        status = 'no_scan';
      } else if (isToday) {
        if (_todayMarks.isEmpty) {
          status = 'no_scan';
        } else {
          status = 'on_time';
          scans = List.of(_todayMarks);
          worked = _workedByNow(date, now);
          remaining = norm - worked;
        }
      } else if (d % 9 == 0) {
        status = 'absent';
      } else if (d % 4 == 0) {
        // Пришел в 08:34 — опоздание на 34 минуты.
        status = 'late';
        worked = 446;
        remaining = 0;
        scans = _dayScans(year, m, d, inH: 8, inM: 34, outH: 17, outM: 0);
      } else {
        status = 'on_time';
        worked = norm;
        remaining = 0;
        scans = _dayScans(year, m, d, inH: 7, inM: 56, outH: 17, outM: 2);
      }

      days.add({
        'date': dateStr,
        'day_type': isWeekend ? 'weekend' : 'working_day',
        'work_start': isWeekend ? null : _workStart,
        'work_end': isWeekend ? null : _workEnd,
        'lunch_start': isWeekend ? null : _lunchStart,
        'lunch_end': isWeekend ? null : _lunchEnd,
        'worked_minutes': worked,
        'remaining_minutes': remaining,
        'status': status,
        'place': _park,
        'scans': scans,
      });
    }
    return {'month': month, 'days': days};
  }

  Map<String, dynamic> _tardiness(
    String iin,
    DateTime periodFrom,
    DateTime periodTo,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = periodTo.isAfter(today) ? today : periodTo;
    final results = <Map<String, dynamic>>[];

    for (var date = periodFrom;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday >= DateTime.saturday) continue;
      final day = date.day;
      if (day % 4 != 0) continue;
      const lateMinutes = 34;
      results.add({
        'date': _dateParam(date),
        'auth_time': isoWithOffset(
          DateTime(date.year, date.month, date.day, 8, lateMinutes),
        ),
        'schedule_start_time': '$_workStart:00',
        'tardiness_minutes': lateMinutes,
      });
    }

    final total = results.fold(
      0,
      (sum, item) => sum + (item['tardiness_minutes'] as int),
    );
    final max = results.fold(
      0,
      (maximum, item) {
        final value = item['tardiness_minutes'] as int;
        return value > maximum ? value : maximum;
      },
    );

    return {
      'iin': iin,
      'employee_name': 'Сериков Айдос Бекжанович',
      'schedule_name': '5/2',
      'schedule_start_time': '$_workStart:00',
      'period_from': _dateParam(periodFrom),
      'period_to': _dateParam(periodTo),
      'count': results.length,
      'max_tardiness': max,
      'avg_tardiness': results.isEmpty ? 0 : (total / results.length).round(),
      'results': results,
    };
  }

  List<Map<String, dynamic>> _dayScans(
    int year,
    int month,
    int day, {
    required int inH,
    required int inM,
    required int outH,
    required int outM,
  }) {
    return [
      {
        'scanned_at': isoWithOffset(DateTime(year, month, day, inH, inM)),
        'mark_type': 'check_in',
        'park': _park,
      },
      {
        'scanned_at': isoWithOffset(DateTime(year, month, day, outH, outM)),
        'mark_type': 'check_out',
        'park': _park,
      },
    ];
  }

  static DateTime _parseDate(String? value) {
    return DateTime.tryParse(value ?? '') ?? DateTime.now();
  }

  static String _dateParam(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _ok(
    RequestInterceptorHandler handler,
    RequestOptions options,
    Object data,
  ) {
    handler.resolve(
      Response<dynamic>(requestOptions: options, statusCode: 200, data: data),
    );
  }

  void _fail(
    RequestInterceptorHandler handler,
    RequestOptions options,
    int status,
    Map<String, dynamic> data,
  ) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      ),
      true,
    );
  }
}
