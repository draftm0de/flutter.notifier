
import 'package:draftmode_notifier_example/screen/home.dart';
import 'package:flutter/cupertino.dart';

class App extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const App({
    super.key,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}
