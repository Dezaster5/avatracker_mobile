import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// iOS camera_avfoundation already applies device orientation to BGRA stream
/// buffers. Android YUV buffers still need the sensor/device correction.
int cameraFrameRotationDegrees({
  required bool isBgra,
  required DeviceOrientation deviceOrientation,
  required int sensorOrientation,
  required CameraLensDirection lensDirection,
}) {
  if (isBgra) return 0;
  const deviceRotation = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  final rotation = deviceRotation[deviceOrientation] ?? 0;
  return lensDirection == CameraLensDirection.front
      ? (sensorOrientation + rotation) % 360
      : (sensorOrientation - rotation + 360) % 360;
}

final class CameraPlaneSnapshot {
  CameraPlaneSnapshot({
    required Uint8List bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  }) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

/// Независимая копия кадра camera image stream, пригодная после callback.
final class CameraFrameSnapshot {
  CameraFrameSnapshot({
    required this.width,
    required this.height,
    required this.isBgra,
    required this.planes,
  });

  factory CameraFrameSnapshot.fromCameraImage(CameraImage image) {
    final isBgra = image.format.group == ImageFormatGroup.bgra8888;
    return CameraFrameSnapshot(
      width: image.width,
      height: image.height,
      isBgra: isBgra,
      planes: image.planes
          .map(
            (plane) => CameraPlaneSnapshot(
              bytes: plane.bytes,
              bytesPerRow: plane.bytesPerRow,
              // camera_avfoundation intentionally reports null on iOS.
              // A packed BGRA pixel always occupies four bytes.
              bytesPerPixel: plane.bytesPerPixel ?? (isBgra ? 4 : 1),
            ),
          )
          .toList(growable: false),
    );
  }

  final int width;
  final int height;
  final bool isBgra;
  final List<CameraPlaneSnapshot> planes;

  Uint8List encodeJpeg({required int rotationDegrees}) {
    if (planes.isEmpty) {
      throw const FormatException('Camera frame has no planes');
    }

    final image = isBgra ? _decodeBgra() : _decodeYuv420();
    final normalizedRotation = rotationDegrees % 360;
    final rotated = normalizedRotation == 0
        ? image
        : img.copyRotate(image, angle: normalizedRotation);
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 88));
  }

  img.Image _decodeBgra() {
    final plane = planes.first;
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * plane.bytesPerRow + x * plane.bytesPerPixel;
        if (index + 2 >= plane.bytes.length) continue;
        image.setPixelRgba(
          x,
          y,
          plane.bytes[index + 2],
          plane.bytes[index + 1],
          plane.bytes[index],
          255,
        );
      }
    }
    return image;
  }

  img.Image _decodeYuv420() {
    if (planes.length < 3) {
      throw const FormatException('YUV420 frame must contain three planes');
    }
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];
    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yValue = _sample(yPlane, x, y);
        final uValue = _sample(uPlane, x ~/ 2, y ~/ 2) - 128;
        final vValue = _sample(vPlane, x ~/ 2, y ~/ 2) - 128;
        final r = (yValue + 1.402 * vValue).round().clamp(0, 255);
        final g = (yValue - 0.344136 * uValue - 0.714136 * vValue)
            .round()
            .clamp(0, 255);
        final b = (yValue + 1.772 * uValue).round().clamp(0, 255);
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return image;
  }

  int _sample(CameraPlaneSnapshot plane, int x, int y) {
    final index = y * plane.bytesPerRow + x * plane.bytesPerPixel;
    if (index < 0 || index >= plane.bytes.length) return 0;
    return plane.bytes[index];
  }
}
