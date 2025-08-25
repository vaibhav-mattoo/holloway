import 'package:flutter/material.dart';
import 'mobile_tab_view.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _onBack),
          IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _onForward),
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: tabProvider.addTab),
          IconButton(
            icon: const Icon(Icons.filter_none_outlined),
            onPressed: () => _onShowTabs(context),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _onMoreOptions),
        ],
      ),
    );
  }

  void _onBack() {
    // TODO: Connect to backend for back navigation
  }

  void _onForward() {
    // TODO: Connect to backend for forward navigation
  }

  void _onShowTabs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MobileTabView()),
    );
  }

  void _onMoreOptions() {
    // TODO: Implement more options menu
  }
}
