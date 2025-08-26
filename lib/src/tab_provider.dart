import 'package:flutter/material.dart';
import 'dart:math';
import 'models/tab_info.dart';
import 'rust/api/exposed_functions.dart';
import 'parsers/gemini_parser.dart';
import 'parsers/gopher_parser.dart';

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
            // Pass the start page URL to resolve relative links
            if (getStartPage().startsWith('gopher://')) {
              return _buildGopherContent(snapshot.data!, baseUrl: getStartPage());
            } else if (getStartPage().startsWith('finger://')) {
              return _buildFingerContent(snapshot.data!, baseUrl: getStartPage());
            } else {
              return _buildGeminiContent(snapshot.data!, baseUrl: getStartPage());
            }
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
      
      tab.updateUrl(url);
      
      // Set a temporary title based on the URL while loading
      final host = Uri.parse(url).host;
      if (host.isNotEmpty) {
        tab.updateTitle(host);
        notifyListeners();
      }
      
      tab.content = FutureBuilder<String>(
        future: navigate(url: url),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Schedule title update for next frame to avoid build phase issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateTabTitle(_activeTabIndex, snapshot.data!);
            });
            if (url.startsWith('gopher://')) {
              return _buildGopherContent(snapshot.data!, baseUrl: url);
            } else if (url.startsWith('finger://')) {
              return _buildFingerContent(snapshot.data!, baseUrl: url);
            } else {
              return _buildGeminiContent(snapshot.data!, baseUrl: url);
            }
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

  // Build Gemini content using the parser and renderer
  Widget _buildGeminiContent(String content, {String? baseUrl}) {
    // Check if this is an error response
    if (content.startsWith('Failed to fetch')) {
      // This is an error response, show as plain text
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    // Check if this is a Gemini response with status
    if (content.startsWith('Status:')) {
      // Extract the actual content after the status line
      final lines = content.split('\n');
      String geminiContent = '';
      bool foundBody = false;
      
      for (final line in lines) {
        if (foundBody) {
          geminiContent = '$geminiContent$line\n';
        } else if (line.trim().isEmpty) {
          // Empty line after status indicates start of body
          foundBody = true;
        }
      }
      
      if (geminiContent.isNotEmpty) {
        // Parse and render as Gemini content using the compliant parser
        // Pass the current URL to resolve relative links
        final elements = parseGemtext(geminiContent, baseUrl: baseUrl);
        
        return GeminiRenderer(
          elements: elements,
          onLinkTap: (url) {
            // Navigate to the clicked link in the current tab
            navigateToUrl(url);
          },
        );
      }
    }
    
    // If no status header, treat as raw Gemini content
    // Note: We can't resolve relative URLs here since we don't have a base URL
    final elements = parseGemtext(content);
    
    return GeminiRenderer(
      elements: elements,
      onLinkTap: (url) {
        // Navigate to the clicked link in the current tab
        navigateToUrl(url);
      },
    );
  }

  Widget _buildGopherContent(String content, {String? baseUrl}) {
    final lines = parseGopherResponse(content);
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return ListTile(
          title: Text(line.description),
          onTap: () {
            if (line.type == '1' || line.type == '0') {
              var selector = line.selector;
              if (!selector.startsWith('/')) {
                selector = '/selector';
              }
              navigateToUrl('gopher://${line.host}:${line.port}$selector');
            }
          },
        );
      },
    );
  }

  // Build Finger content
  Widget _buildFingerContent(String content, {String? baseUrl}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with protocol info
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Finger Protocol',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            SelectableText(
              content,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
