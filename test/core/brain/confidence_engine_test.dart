import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/confidence_engine.dart';

void main() {
  group('ConfidenceEngine', () {
    const engine = ConfidenceEngine();

    test('create returns initial confidence', () {
      expect(engine.create(), 0.30);
    });

    test('strengthen increases confidence', () {
      expect(engine.strengthen(0.30), 0.35);
    });

    test('weaken decreases confidence', () {
      expect(engine.weaken(0.30), 0.25);
    });

    test('strengthen never exceeds maximum confidence', () {
      expect(engine.strengthen(0.99), 0.99);
    });

    test('weaken never goes below minimum confidence', () {
      expect(engine.weaken(0.0), 0.0);
    });
  });
}
