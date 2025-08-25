import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tab_provider.dart';

class MobileTabView extends StatelessWidget {
  const MobileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tabs')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: tabProvider.tabs.length,
        itemBuilder: (context, index) {
          final tab = tabProvider.tabs[index];
          return GestureDetector(
            onTap: () {
              tabProvider.setActiveTab(index);
              Navigator.pop(context);
            },
            child: Card(
              child: Stack(
                children: [
                  Center(child: Text(tab.title)), // Placeholder for tab preview
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => tabProvider.closeTab(index),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
