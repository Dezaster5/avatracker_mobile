import 'package:avatracker_mobile/core/utils/camera_frame_encoder.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  test('iOS BGRA uses four bytes per pixel when plugin reports null', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    // camera_avfoundation does not include bytesPerPixel for iOS planes.
    // ignore: deprecated_member_use
    final cameraImage = CameraImage.fromPlatformData({
      'format': 1111970369,
      'width': 2,
      'height': 1,
      'lensAperture': null,
      'sensorExposureTime': null,
      'sensorSensitivity': null,
      'planes': [
        {
          'bytes': Uint8List.fromList([
            0,
            0,
            255,
            255,
            0,
            255,
            0,
            255,
          ]),
          'bytesPerRow': 8,
          'width': 2,
          'height': 1,
        },
      ],
    });

    final frame = CameraFrameSnapshot.fromCameraImage(cameraImage);
    final decoded = img.decodeJpg(frame.encodeJpeg(rotationDegrees: 0));

    expect(cameraImage.planes.single.bytesPerPixel, isNull);
    expect(frame.isBgra, isTrue);
    expect(frame.planes.single.bytesPerPixel, 4);
    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 1);
  });

  test('iOS BGRA frame is not rotated a second time', () {
    final rotation = cameraFrameRotationDegrees(
      isBgra: true,
      deviceOrientation: DeviceOrientation.portraitUp,
      sensorOrientation: 90,
      lensDirection: CameraLensDirection.front,
    );

    expect(rotation, 0);
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
