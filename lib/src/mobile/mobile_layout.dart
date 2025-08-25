import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';
import 'mobile_bottom_nav.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context);
    
    // Sync the text controller with the active tab's display URL
    final displayUrl = tabProvider.activeTabDisplayUrl;
    if (_textController.text != displayUrl) {
      _textController.text = displayUrl;
    }
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: tabProvider.activeTabIndex,
        children: tabProvider.tabs.map((tab) => tab.content).toList(),
      ),
      bottomNavigationBar: const MobileBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _buildSearchField(),
      actions: _isFocused
          ? [
              TextButton(
                onPressed: () => _focusNode.unfocus(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              )
            ]
          : null,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search or type URL',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _isFocused && _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _textController.clear(),
              )
            : null,
      ),
      onChanged: (value) {
        // Update the display URL as user types
        Provider.of<TabProvider>(context, listen: false).updateActiveTabDisplayUrl(value);
      },
      onSubmitted: (url) => Provider.of<TabProvider>(context, listen: false).navigateToUrl(url),
    );
  }
}
