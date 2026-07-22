import 'dart:math' as math;
import 'dart:typed_data';

/// Быстрая оценка пригодности кадра без распознавания или хранения лица.
///
/// Анализируется небольшая сетка в центре кадра: экспозиция, контраст и
/// перепады яркости. Значение всегда находится в диапазоне от 0 до 1.
class FrameQuality {
  const FrameQuality._();

  static double scoreLuminancePlane(
    Uint8List bytes, {
    required int width,
    required int height,
    required int bytesPerRow,
    int bytesPerPixel = 1,
  }) {
    if (bytes.isEmpty ||
        width <= 0 ||
        height <= 0 ||
        bytesPerRow <= 0 ||
        bytesPerPixel <= 0) {
      return 0;
    }

    return _score(
      width: width,
      height: height,
      luminanceAt: (x, y) {
        final offset = y * bytesPerRow + x * bytesPerPixel;
        return offset >= 0 && offset < bytes.length ? bytes[offset] : 0;
      },
    );
  }

  static double scoreBgraPlane(
    Uint8List bytes, {
    required int width,
    required int height,
    required int bytesPerRow,
    int bytesPerPixel = 4,
  }) {
    if (bytes.isEmpty ||
        width <= 0 ||
        height <= 0 ||
        bytesPerRow <= 0 ||
        bytesPerPixel < 3) {
      return 0;
    }

    return _score(
      width: width,
      height: height,
      luminanceAt: (x, y) {
        final offset = y * bytesPerRow + x * bytesPerPixel;
        if (offset < 0 || offset + 2 >= bytes.length) return 0;
        final blue = bytes[offset];
        final green = bytes[offset + 1];
        final red = bytes[offset + 2];
        return (29 * blue + 150 * green + 77 * red) >> 8;
      },
    );
  }

  static double _score({
    required int width,
    required int height,
    required int Function(int x, int y) luminanceAt,
  }) {
    final left = (width * 0.18).round();
    final right = math.max(left + 1, (width * 0.82).round());
    final top = (height * 0.15).round();
    final bottom = math.max(top + 1, (height * 0.85).round());
    final stepX = math.max(1, (right - left) ~/ 32);
    final stepY = math.max(1, (bottom - top) ~/ 32);

    var count = 0;
    var sum = 0.0;
    var sumSquares = 0.0;
    var edgeSum = 0.0;
    var edgeCount = 0;
    List<int>? previousRow;

    for (var y = top; y < bottom; y += stepY) {
      final row = <int>[];
      int? previous;
      var column = 0;
      for (var x = left; x < right; x += stepX) {
        final value = luminanceAt(x, y).clamp(0, 255);
        row.add(value);
        count++;
        sum += value;
        sumSquares += value * value;
        if (previous != null) {
          edgeSum += (value - previous).abs();
          edgeCount++;
        }
        if (previousRow != null && column < previousRow.length) {
          edgeSum += (value - previousRow[column]).abs();
          edgeCount++;
        }
        previous = value;
        column++;
      }
      previousRow = row;
    }

    if (count == 0) return 0;
    final mean = sum / count;
    final variance = math.max(0, sumSquares / count - mean * mean);
    final standardDeviation = math.sqrt(variance);
    final averageEdge = edgeCount == 0 ? 0.0 : edgeSum / edgeCount;

    final exposure = switch (mean) {
      < 20 => 0.0,
      < 65 => (mean - 20) / 45,
      <= 210 => 1.0,
      < 245 => (245 - mean) / 35,
      _ => 0.0,
    };
    final contrast = (standardDeviation / 42).clamp(0.0, 1.0);
    final sharpness = (averageEdge / 18).clamp(0.0, 1.0);

    return (exposure * 0.35 + contrast * 0.25 + sharpness * 0.40)
        .clamp(0.0, 1.0);
  }
}
