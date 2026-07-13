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
/// - у демо-сотрудника индивидуальный график 08:00–17:00.
class MockInterceptor extends Interceptor {
  static const _park = 'AVATARIYA Karaganda';
  static const _code = '1234';
  static const _workStart = '08:00';
  static const _workEnd = '17:00';

  /// Зарегистрированные аккаунты: национальный номер -> {iin, password}.
  static final Map<String, Map<String, String>> _accounts = {
    '7001234567': {'iin': '990101300123', 'password': '123456'},
  };

  /// Национальный номер и ИИН текущей сессии.
  static String? _sessionPhone;
  static String? _sessionIin;

  /// Выданные токены сброса пароля: reset_token -> национальный номер.
  static final Map<String, String> _resetTokens = {};

  static final List<Map<String, dynamic>> _todayMarks = [];

  /// Последние 10 цифр номера (национальная часть, как шлёт клиент).
  static String _nat(Object? phone) {
    final digits = '$phone'.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Auth-вызовы идут на абсолютные URL `…/api/mobile/…` — сопоставляем
    // по суффиксу пути; data-эндпоинты остаются относительными.
    final p = Uri.parse(options.path).path;
    final body = options.data is Map ? (options.data as Map) : const {};

    // ─── Мобильный auth-API (/api/mobile) ───
    // Порядок важен: verify/resend проверяем до общего register/.
    if (p.endsWith('/auth/register/verify/')) {
      final phone = _nat(body['phone']);
      if ('${body['code']}' != _code) {
        return _fail(handler, options, 400, {'detail': 'Неверный SMS-код'});
      }
      final account = _accounts[phone];
      if (account == null) {
        return _fail(
            handler, options, 400, {'detail': 'Сначала зарегистрируйтесь'});
      }
      _sessionPhone = phone;
      _sessionIin = account['iin'];
      return _ok(handler, options, _session());
    }

    if (p.endsWith('/auth/register/resend/')) {
      return _ok(handler, options, {'detail': 'SMS code sent'});
    }

    if (p.endsWith('/auth/register/')) {
      final phone = _nat(body['phone']);
      _accounts[phone] = {
        'iin': '${body['iin']}',
        'password': '${body['password']}',
      };
      return _ok(handler, options, {'detail': 'SMS code sent'});
    }

    if (p.endsWith('/auth/login/')) {
      final phone = _nat(body['phone']);
      final account = _accounts[phone];
      if (account == null) {
        return _fail(handler, options, 404,
            {'detail': 'Аккаунт не найден. Зарегистрируйтесь'});
      }
      if (account['password'] != '${body['password']}') {
        return _fail(handler, options, 401,
            {'detail': 'Неверный номер телефона или пароль'});
      }
      _sessionPhone = phone;
      _sessionIin = account['iin'];
      return _ok(handler, options, _session());
    }

    if (p.endsWith('/auth/token/refresh/')) {
      return _ok(handler, options, {
        'access': 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
        'refresh': 'mock_refresh',
      });
    }

    if (p.endsWith('/password-reset/request/')) {
      if (!_accounts.containsKey(_nat(body['phone']))) {
        return _fail(handler, options, 404,
            {'detail': 'Аккаунт с этим номером не найден'});
      }
      return _ok(handler, options, {'detail': 'SMS code sent'});
    }

    if (p.endsWith('/password-reset/verify/')) {
      if ('${body['code']}' != _code) {
        return _fail(handler, options, 400, {'detail': 'Неверный SMS-код'});
      }
      final token = 'mock_reset_${DateTime.now().microsecondsSinceEpoch}';
      _resetTokens[token] = _nat(body['phone']);
      return _ok(handler, options, {'reset_token': token});
    }

    if (p.endsWith('/password-reset/confirm/')) {
      final phone = _resetTokens.remove('${body['reset_token']}');
      final account = phone == null ? null : _accounts[phone];
      if (account == null) {
        return _fail(
            handler, options, 400, {'detail': 'Токен сброса недействителен'});
      }
      account['password'] = '${body['password']}';
      return _ok(handler, options, {'detail': 'Пароль изменен'});
    }

    if (p.endsWith('/auth/change-password/')) {
      final account = _sessionPhone == null ? null : _accounts[_sessionPhone];
      if (account == null) {
        return _fail(handler, options, 401,
            {'detail': 'Сессия истекла. Войдите заново'});
      }
      if (account['password'] != '${body['current_password']}') {
        return _fail(
            handler, options, 400, {'detail': 'Текущий пароль неверен'});
      }
      account['password'] = '${body['new_password']}';
      return _ok(handler, options, {'detail': 'Пароль изменен'});
    }

    if (p.endsWith('/profile/me/')) {
      final iin = _sessionIin ?? '990101300123';
      final phone = _sessionPhone == null ? null : '+7$_sessionPhone';
      return _ok(handler, options, _employee(iin, phone: phone));
    }

    if (p.endsWith('/profile/delete/')) {
      // Полное удаление аккаунта: убираем демо-аккаунт, нужна регистрация.
      _accounts.remove(_sessionPhone);
      _sessionPhone = null;
      _sessionIin = null;
      return _ok(handler, options, {'success': true});
    }

    // QR-скан с фото лица: сервер сверяет лицо с базой при отметке.
    if (p.endsWith('/qr/scan/')) {
      return _scan(handler, options);
    }

    // Данные точки `GET /api/qr/{qr_id}/` (id со строкой `inactive` — отключена).
    final qrMatch = RegExp(r'/qr/([^/]+)/?$').firstMatch(p);
    if (qrMatch != null && qrMatch.group(1) != 'scan') {
      final qrId = qrMatch.group(1)!;
      return _ok(handler, options, {
        'id': 1,
        'qr_id': qrId,
        'park_id': 5000011,
        'park_name': _park,
        'latitude': 49.8047,
        'longitude': 73.1094,
        'radius_meters': 50,
        'is_active': !qrId.contains('inactive'),
      });
    }

    // ─── data-API (/api/v1) ───
    switch (p) {
      case '/employee-identification-list/':
        final periodFrom = _parseDate(
          options.queryParameters['period_from']?.toString(),
        );
        final periodTo = _parseDate(
          options.queryParameters['period_to']?.toString(),
        );
        return _ok(
          handler,
          options,
          _identificationList(periodFrom, periodTo),
        );

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

    if (p == '/employees/') {
      final iin = options.queryParameters['search']?.toString() ??
          _sessionIin ??
          '990101300123';
      return _ok(handler, options, {
        'count': 1,
        'next': null,
        'previous': null,
        'results': [_employee(iin)],
      });
    }

    if (p.startsWith('/employees/')) {
      final iin = p.split('/').where((s) => s.isNotEmpty).last;
      return _ok(handler, options, _employee(iin));
    }

    if (p.startsWith('/mobile/qr-points/')) {
      final qrId = p.split('/').where((s) => s.isNotEmpty).last;
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
    return _fail(
        handler, options, 404, {'message': 'Mock: эндпоинт $p не реализован'});
  }

  /// Ответ авторизации в стиле SimpleJWT: только токены
  /// (профиль клиент берёт следом из `/profile/me/`).
  Map<String, dynamic> _session() {
    return {
      'access': 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
      'refresh': 'mock_refresh',
    };
  }

  void _scan(RequestInterceptorHandler handler, RequestOptions options) {
    final data = options.data;
    final qrId = data is Map ? '${data['qr_id'] ?? ''}' : '';
    final photo = data is Map ? '${data['photo'] ?? ''}' : '';

    if (photo.isEmpty) {
      return _fail(handler, options, 400, {
        'success': false,
        'error_code': 'FACE_REQUIRED',
        'message': 'Не приложено фото для сверки лица',
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
        'schedule_name': '5/2',
        'schedule_start_time': '$_workStart:00',
        'schedule_end_time': '$_workEnd:00',
      };

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

  Map<String, dynamic> _identificationList(
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
      if (date.weekday >= DateTime.saturday || date.day % 9 == 0) continue;
      if (date == today && _todayMarks.isNotEmpty) {
        results.addAll(
          _todayMarks.map((mark) => {
                'id': results.length + 1,
                'auth_time': mark['scanned_at'],
                'park_name': _park,
              }),
        );
        continue;
      }
      final late = date.day % 4 == 0;
      final scans = _dayScans(
        date.year,
        date.month,
        date.day,
        inH: late ? 8 : 7,
        inM: late ? 34 : 56,
        outH: 17,
        outM: late ? 0 : 2,
      );
      results.addAll(
        scans.map((scan) => {
              'id': results.length + 1,
              'auth_time': scan['scanned_at'],
              'park_name': _park,
            }),
      );
    }
    return {'count': results.length, 'next': null, 'results': results};
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
