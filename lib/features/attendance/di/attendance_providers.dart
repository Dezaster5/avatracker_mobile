import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../data/datasources/attendance_remote_data_source.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../data/services/geolocator_location_service.dart';
import '../domain/repositories/attendance_repository.dart';
import '../domain/services/location_service.dart';
import '../domain/usecases/check_qr_point.dart';
import '../domain/usecases/get_attendance_overview.dart';
import '../domain/usecases/get_verified_position.dart';
import '../domain/usecases/submit_attendance_mark.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(
    AttendanceRemoteDataSource(ref.watch(apiClientProvider).dio),
  ),
);

final locationServiceProvider =
    Provider<LocationService>((ref) => const GeolocatorLocationService());

final getAttendanceOverviewProvider = Provider(
  (ref) => GetAttendanceOverview(ref.watch(attendanceRepositoryProvider)),
);

final checkQrPointProvider = Provider(
  (ref) => CheckQrPoint(ref.watch(attendanceRepositoryProvider)),
);

final getVerifiedPositionProvider = Provider(
  (ref) => GetVerifiedPosition(ref.watch(locationServiceProvider)),
);

final submitAttendanceMarkProvider = Provider(
  (ref) => SubmitAttendanceMark(ref.watch(attendanceRepositoryProvider)),
);
