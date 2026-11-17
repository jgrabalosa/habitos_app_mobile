import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app_mobile/orientacion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fijarOrientacionVertical manda solo portraitUp a la plataforma', () async {
    final llamadas = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          llamadas.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await fijarOrientacionVertical();

    expect(llamadas, hasLength(1));
    expect(llamadas.single.method, 'SystemChrome.setPreferredOrientations');
    expect(llamadas.single.arguments, ['DeviceOrientation.portraitUp']);
  });
}
