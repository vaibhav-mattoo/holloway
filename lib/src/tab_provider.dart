import 'package:flutter/material.dart';
import 'dart:math';
import 'models/tab_info.dart';
import 'rust/api/exposed_functions.dart';
import 'content/content_renderer.dart';

// manages the state of all browser tabs
// with ChangeNotifier to notify listeners of state changes
class TabProvider with ChangeNotifier {
  // private list of tabs and active tab index
  final List<TabInfo> _tabs = [];
  // index of the currently active tab, -1 if none
  int _activeTabIndex = -1;
  // counter to assign unique IDs to tabs
  int _nextTabId = 0;

  // public getter for list of tabs
  List<TabInfo> get tabs => _tabs;
  // public getter for active tab index
  int get activeTabIndex => _activeTabIndex;
  // public getter for the currently active tab, or null if none
  TabInfo? get activeTab =>
      _activeTabIndex != -1 ? _tabs[_activeTabIndex] : null;

  // Safe getter for active tab's display URL
  String get activeTabDisplayUrl {
    final tab = activeTab;
    if (tab == null) return '';
    
    // Ensure the tab has required fields initialized
    if (tab.url.isEmpty && tab.displayUrl.isEmpty) {
      tab.url = '';
      tab.displayUrl = '';
    }
    
    return tab.displayUrl;
  }

  // Ensure all tabs have required fields initialized
  void _ensureTabsInitialized() {
    for (final tab in _tabs) {
      if (tab.url.isEmpty && tab.displayUrl.isEmpty) {
        tab.url = '';
        tab.displayUrl = '';
      }
    }
  }

  // ensures browser starts with one tab
  TabProvider() {
    addTab();
    _ensureTabsInitialized();
  }

  void addTab() {
    final newTab = TabInfo(
      id: _nextTabId++,
      title: 'New Tab',
      content: FutureBuilder<String>(
        future: navigate(url: getStartPage()),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Schedule title update for next frame to avoid build phase issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateTabTitle(_tabs.length - 1, snapshot.data!);
            });
            // Use the new ContentRenderer
            return ContentRenderer(
              content: snapshot.data!,
              baseUrl: getStartPage(),
              protocol: _getProtocolFromUrl(getStartPage()),
              onNavigate: navigateToUrl,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      url: '',
      displayUrl: '',
    );
    _tabs.add(newTab);
    _activeTabIndex = _tabs.length - 1;
    _ensureTabsInitialized();
    notifyListeners();
  }

  void closeTab(int tabIndex) {
    // TODO: Connect to backend to close a tab session
    if (_tabs.length > 1) {
      _tabs.removeAt(tabIndex);
      if (_activeTabIndex >= tabIndex) {
        _activeTabIndex = max(0, _activeTabIndex - 1);
      }
    } else {
      _tabs.removeAt(tabIndex);
      addTab(); // Always have at least one tab
    }
    notifyListeners();
  }

  void setActiveTab(int tabIndex) {
    if (_activeTabIndex != tabIndex) {
      _activeTabIndex = tabIndex;
      notifyListeners();
    }
  }

  void navigateToUrl(String url) {
    if (_activeTabIndex >= 0 && _activeTabIndex < _tabs.length) {
      final tab = _tabs[_activeTabIndex];
      
      // Ensure the tab has required fields initialized
      if (tab.url.isEmpty && tab.displayUrl.isEmpty) {
        tab.url = '';
        tab.displayUrl = '';
      }
      
      // Validate and fix the URL before processing
      String processedUrl = url.trim();
      if (processedUrl.isEmpty) return;
      
      // Fix malformed URLs that start with ://
      if (processedUrl.startsWith('://')) {
        processedUrl = 'gemini$processedUrl';
      }
      
      // Ensure URLs without scheme get gemini:// prefix (for relative URLs)
      if (!processedUrl.contains('://') && !processedUrl.startsWith('/')) {
        processedUrl = 'gemini://$processedUrl';
      }
      
      tab.updateUrl(processedUrl);
      
      // Set a temporary title based on the URL while loading
      try {
        final uri = Uri.parse(processedUrl);
        final host = uri.host;
        if (host.isNotEmpty) {
          tab.updateTitle(host);
          notifyListeners();
        }
      } catch (e) {
        // If URL parsing fails, use the original URL as title
        tab.updateTitle(processedUrl);
        notifyListeners();
      }
      
      tab.content = FutureBuilder<String>(
        future: navigate(url: processedUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Schedule title update for next frame to avoid build phase issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateTabTitle(_activeTabIndex, snapshot.data!);
            });
            // Use the new ContentRenderer
            return ContentRenderer(
              content: snapshot.data!,
              baseUrl: processedUrl,
              protocol: _getProtocolFromUrl(processedUrl),
              onNavigate: navigateToUrl,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
      notifyListeners();
    }
  }

  // Update the display URL for the active tab (for user input)
  void updateActiveTabDisplayUrl(String displayUrl) {
    if (_activeTabIndex >= 0 && _activeTabIndex < _tabs.length) {
      _tabs[_activeTabIndex].updateDisplayUrl(displayUrl);
      notifyListeners();
    }
  }

  // Update tab title based on content
  void _updateTabTitle(int tabIndex, String content) {
    if (tabIndex >= 0 && tabIndex < _tabs.length) {
      final tab = _tabs[tabIndex];
      
      // Try to extract title from content (first line or first heading)
      String title = tab.title; // Keep current title as fallback
      
      // Look for first heading (#, ##, ###)
      final lines = content.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#') && trimmed.length > 1) {
          // Remove # symbols and get the text
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          break;
        } else if (trimmed.isNotEmpty && 
                   !trimmed.startsWith('Status:') && 
                   !trimmed.startsWith('gemini://') &&
                   trimmed.length > 3) {
          // Use first non-empty line that's not a status line or URL
          title = trimmed;
          break;
        }
      }
      
      // Limit title length
      if (title.length > 30) {
        title = '${title.substring(0, 27)}...';
      }
      
      // Only update if we have a meaningful title
      if (title != tab.title && title.isNotEmpty && title != 'New Tab') {
        tab.updateTitle(title);
        notifyListeners();
      }
    }
  }

  // Helper method to determine protocol from URL
  String _getProtocolFromUrl(String url) {
    if (url.startsWith('gemini://')) return 'gemini';
    if (url.startsWith('gopher://')) return 'gopher';
    if (url.startsWith('finger://')) return 'finger';
    if (url.startsWith('http://')) return 'http';
    if (url.startsWith('https://')) return 'https';
    // Default to gemini for URLs without scheme
    return 'gemini';
  }
}
