import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/state/tips_controller.dart';

import '../helpers.dart';

void main() {
  test('kapatılan ipucu kalıcıdır ve hesaba özeldir', () async {
    final store = await emptyStore();
    final tips = TipsController(store, 'u1');
    var notified = 0;
    tips.addListener(() => notified++);
    expect(tips.isSeen(TipsController.addProduct), isFalse);

    tips.dismiss(TipsController.addProduct);
    tips.dismiss(TipsController.addProduct);
    expect(notified, 1);
    expect(
      TipsController(store, 'u1').isSeen(TipsController.addProduct),
      isTrue,
    );
    expect(
      TipsController(store, 'u2').isSeen(TipsController.addProduct),
      isFalse,
    );
  });

  test('oturum yokken hiçbir şey yazılmaz', () async {
    final store = await emptyStore();
    TipsController(store, null).dismiss(TipsController.addProduct);
    expect(
      TipsController(store, 'u1').isSeen(TipsController.addProduct),
      isFalse,
    );
  });
}
