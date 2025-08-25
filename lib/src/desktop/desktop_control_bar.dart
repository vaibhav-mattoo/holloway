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
    // expanded to take up remaining space between navigation and menu controls regardless of screen size
    return Expanded(
      // padding to ensure url bar is not too close to navigation/menu controls and top and bottom edges
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        // listen to TabProvider for changes to active tab's display URL
        child: Consumer<TabProvider>(
          builder: (context, tabProvider, child) {
            final displayUrl = tabProvider.activeTabDisplayUrl;

            // is a material 3 search bar with suggestions
            return SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                // Initialize controller text when it doesn't match the current display URL
                // needed to ensure search bar updates when active tab changes
                if (controller.text != displayUrl) {
                  controller.text = displayUrl;
                }

                // this is the visible part of search anchor
                return SearchBar(
                  controller: controller,
                  hintText: 'Enter URL or search',
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
                    // TODO: need to implement this based on bookmarks and history
                  },
                  // adds a search icon to the end of the search bar
                  trailing: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      iconSize: 20,
                      // removes the default padding around the icon button - needed to make it look natural
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: () {
                        // allows user to submit the current text in the search bar
                        final url = controller.text;
                        if (url.isNotEmpty) {
                          tabProvider.navigateToUrl(url);
                        }
                      },
                    ),
                  ],
                  // removes the default border and shadow to make it look flat
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0.0),
                );
              },
              // TODO: fill in suggestions based on bookmarks and history
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
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
