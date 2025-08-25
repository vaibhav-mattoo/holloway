import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/tab_provider.dart';
import 'src/desktop/desktop_layout.dart';
import 'src/mobile/mobile_layout.dart';
import 'src/rust/frb_generated.dart';

// program entry point
// async main function to initialize Rust library
Future<void> main() async {
  // awawit keyword pauses execution until the rust library is initialized
  await RustLib.init();
  // makes HollowayApp the root widget of the application
  runApp(const HollowayApp());
}

// root widget of the application
class HollowayApp extends StatelessWidget {
  const HollowayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // this returns ChangeNotifierProvider which provides TabProvider to the widget tree
    // this makes it aavailable to all descendant widgets
    return ChangeNotifierProvider(
      create: (context) => TabProvider(),
      child: MaterialApp(
        title: 'Holloway Browser',
        // need to make decisions here configurable through settings
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // opts into material 3 design for modern ui components
          useMaterial3: true,
        ),
        // removes the debug banner in the top right corner
        debugShowCheckedModeBanner: false,
        // home specifies the widget for the default route of the app
        // we use responsive layout to switch between desktop and mobile layouts
        home: const ResponsiveLayout(),
      ),
    );
  }
}

// this widget is responsible for choosing between desktop and mobile layouts
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // for wider screens we use desktop widget tree else mobile widget tree
    if (screenWidth > 768) {
      return const DesktopLayout();
    } else {
      return const MobileLayout();
    }
  }
}
