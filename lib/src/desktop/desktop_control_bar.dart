import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';

// this widget represents the control bar below the tab bar in the desktop layout
// implements PreferredSizeWidget contract of AppBar to specify its height
class DesktopControlBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ensures window control buttons are not too close to the edge
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      // must match the preferredSize height
      height: 40,
      // items from left to right: navigation controls, url bar, menu controls
      child: Row(
        children: [
          _buildNavigationControls(),
          _buildUrlBar(),
          _buildMenuControls(),
        ],
      ),
    );
  }

  // navigation controls: back, forward, refresh
  Widget _buildNavigationControls() {
    return Row(
      children: [
        IconButton(
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back),
        ),
        IconButton(
          onPressed: _onForwardPressed,
          icon: const Icon(Icons.arrow_forward),
        ),
        IconButton(
          onPressed: _onRefreshPressed,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

    Widget _buildUrlBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Consumer<TabProvider>(
          builder: (context, tabProvider, child) {
            final displayUrl = tabProvider.activeTabDisplayUrl;
            
            return SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                // Initialize controller text when it doesn't match the current display URL
                if (controller.text != displayUrl) {
                  controller.text = displayUrl;
                }
                
                return SearchBar(
                  controller: controller,
                  hintText: 'Enter gemini://, gopher://, or finger:// URL',
                  onSubmitted: (url) {
                    if (url.isNotEmpty) {
                      tabProvider.navigateToUrl(url);
                    }
                  },
                  onChanged: (value) {
                    // Update the display URL as user types
                    tabProvider.updateActiveTabDisplayUrl(value);
                  },
                  onTap: () {
                    // This will open the search suggestions view
                  },
                  trailing: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: () {
                        final url = controller.text;
                        if (url.isNotEmpty) {
                          tabProvider.navigateToUrl(url);
                        }
                      },
                    ),
                  ],
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0.0),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [];
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuControls() {
    return Row(
      children: [
        IconButton(
          onPressed: _onMenuPressed,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  void _onBackPressed() {
    // TODO: Connect to backend to go back
  }

  void _onForwardPressed() {
    // TODO: Connect to backend to go forward
  }

  void _onRefreshPressed() {
    // TODO: Connect to backend to refresh
  }

  void _onMenuPressed() {
    // TODO: Implement menu options
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
