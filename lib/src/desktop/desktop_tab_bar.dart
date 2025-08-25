import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';

// this widget represents the tab bar at the top of the desktop layout
// implements PreferredSizeWidget contract of AppBar to specify its height
class DesktopTabBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    // fetch the TabProvider from the widget tree
    final tabProvider = Provider.of<TabProvider>(context);

    return Container(
      // height here matches the preferredSize
      height: 40,
      // need to change color based on system theme/choice in setting bar
      color: Colors.grey[300],
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabProvider.tabs.length,
              itemBuilder: (context, index) {
                final tab = tabProvider.tabs[index];
                final isActive = tabProvider.activeTabIndex == index;
                return _buildTab(
                  context,
                  tabProvider,
                  tab.title,
                  index,
                  isActive,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => tabProvider.addTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    TabProvider provider,
    String title,
    int index,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => provider.setActiveTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.transparent,
          border: Border(right: BorderSide(color: Colors.grey[400]!)),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => provider.closeTab(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
