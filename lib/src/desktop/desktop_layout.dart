import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';
import 'desktop_tab_bar.dart';
import 'desktop_control_bar.dart';

// defines the desktop layout of the application
// stateless because it relies on TabProvider for state management

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // this line looks up the widget tree for the nearest instance of TabProvider
    final tabProvider = Provider.of<TabProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 0,
        // at some point I need to change this to a custom color based on system theme/choice in setting bar
        backgroundColor: Colors.grey[300],
        // on desktop we show browser tabs over browser control bar (search refresh etc)
        title: const Column(children: [DesktopTabBar(), DesktopControlBar()]),
      ),
      // primary content area of the app
      // indexed stack shows only the active tab's content while keeping other tabs in memory
      body: IndexedStack(
        // when activeTabIndex changes, the displayed child changes
        index: tabProvider.activeTabIndex,
        // take the tab data from TabProvider and map it to a list of widgets to display
        children: tabProvider.tabs.map((tab) => tab.content).toList(),
      ),
    );
  }
}
