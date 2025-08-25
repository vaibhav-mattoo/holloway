import 'package:flutter/material.dart';

// represents a single browser tab
class TabInfo {
  final int id;
  String title;
  Widget content;
  String url;
  String displayUrl;

  TabInfo({
    required this.id,
    required this.title,
    required this.content,
    required this.url,
    required this.displayUrl,
  });

  // Update the URL and display URL
  void updateUrl(String newUrl) {
    url = newUrl;
    displayUrl = newUrl;
  }

  // Update only the display URL (for user input)
  void updateDisplayUrl(String newDisplayUrl) {
    displayUrl = newDisplayUrl;
  }

  // Update the title
  void updateTitle(String newTitle) {
    title = newTitle;
  }

  // Update the content
  void updateContent(Widget newContent) {
    content = newContent;
  }
}
