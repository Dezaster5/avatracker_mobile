import 'dart:typed_data';

import 'package:avatracker_mobile/core/utils/camera_frame_encoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('BGRA frame is encoded to JPEG without taking a picture', () {
    final frame = CameraFrameSnapshot(
      width: 2,
      height: 1,
      isBgra: true,
      planes: [
        CameraPlaneSnapshot(
          bytes: Uint8List.fromList([
            0,
            0,
            255,
            255,
            0,
            255,
            0,
            255,
          ]),
          bytesPerRow: 8,
          bytesPerPixel: 4,
        ),
      ],
    );

    final jpeg = frame.encodeJpeg(rotationDegrees: 0);
    final decoded = img.decodeJpg(jpeg);

    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 1);
  });

  test('portrait rotation swaps frame dimensions', () {
    final frame = CameraFrameSnapshot(
      width: 2,
      height: 1,
      isBgra: true,
      planes: [
        CameraPlaneSnapshot(
          bytes: Uint8List.fromList(List.filled(8, 128)),
          bytesPerRow: 8,
          bytesPerPixel: 4,
        ),
      ],
    );

    final decoded = img.decodeJpg(frame.encodeJpeg(rotationDegrees: 90));

    expect(decoded, isNotNull);
    expect(decoded!.width, 1);
    expect(decoded.height, 2);
  });

  test('Android YUV420 frame is encoded to JPEG', () {
    final frame = CameraFrameSnapshot(
      width: 2,
      height: 2,
      isBgra: false,
      planes: [
        CameraPlaneSnapshot(
          bytes: Uint8List.fromList([90, 120, 150, 180]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
        CameraPlaneSnapshot(
          bytes: Uint8List.fromList([128]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
        CameraPlaneSnapshot(
          bytes: Uint8List.fromList([128]),
          bytesPerRow: 1,
          bytesPerPixel: 1,
        ),
      ],
    );

    final decoded = img.decodeJpg(frame.encodeJpeg(rotationDegrees: 0));

    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 2);
  });
}
