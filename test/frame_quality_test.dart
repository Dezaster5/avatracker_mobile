import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:avatracker_mobile/core/utils/frame_quality.dart';

void main() {
  test('резкий и нормально освещённый кадр лучше тёмного', () {
    const width = 64;
    const height = 64;
    final textured = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        textured[y * width + x] = (x + y).isEven ? 80 : 180;
      }
    }
    final dark = Uint8List(width * height)..fillRange(0, width * height, 8);

    final texturedScore = FrameQuality.scoreLuminancePlane(
      textured,
      width: width,
      height: height,
      bytesPerRow: width,
    );
    final darkScore = FrameQuality.scoreLuminancePlane(
      dark,
      width: width,
      height: height,
      bytesPerRow: width,
    );

    expect(texturedScore, greaterThan(0.48));
    expect(darkScore, lessThan(texturedScore));
  });

  test('оценка BGRA всегда остаётся в диапазоне от 0 до 1', () {
    const width = 16;
    const height = 16;
    final bytes = Uint8List(width * height * 4);
    for (var i = 0; i < bytes.length; i += 4) {
      bytes[i] = 70;
      bytes[i + 1] = 130;
      bytes[i + 2] = 190;
      bytes[i + 3] = 255;
    }

    final score = FrameQuality.scoreBgraPlane(
      bytes,
      width: width,
      height: height,
      bytesPerRow: width * 4,
    );

    expect(score, inInclusiveRange(0, 1));
  });
}
