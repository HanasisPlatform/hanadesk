import 'flavors.dart';

import 'main.dart' as runner;

Future<void> main(List<String> args) async {
  F.appFlavor = Flavor.member;
  await runner.main(args);
}
