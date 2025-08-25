import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/tab_provider.dart';
import 'src/desktop/desktop_layout.dart';
import 'src/mobile/mobile_layout.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const HollowayApp());
}

class HollowayApp extends StatelessWidget {
  const HollowayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TabProvider(),
      child: MaterialApp(
        title: 'Holloway Browser',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ResponsiveLayout(),
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple responsive breakpoint - you can make this more sophisticated
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 768) {
      return const DesktopLayout();
    } else {
      return const MobileLayout();
    }
  }
}
