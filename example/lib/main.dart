import 'package:flutter/material.dart';
import 'package:adaptive_network_image/adaptive_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Network Image Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Network Image Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AdaptiveNetworkImage(
              imageUrl: 'https://picsum.photos/300/200',
              width: 300,
              height: 200,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
              onStrategyResolved: (strategy) {
                debugPrint('Image loaded via: ${strategy.name}');
              },
            ),
            AdaptiveNetworkImage(
              imageUrl: 'https://picsum.photos/300/200?random=2',
              width: 300,
              height: 200,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(12),
              placeholder: (context) => Container(
                color: Colors.grey[200],
                child: const Center(child: Text('Loading...')),
              ),
            ),
            AdaptiveNetworkImage(
              imageUrl: 'https://invalid-url-for-testing.example.com/img.png',
              width: 300,
              height: 200,
              strategies: const [ImageLoadStrategy.directImg],
              errorWidget: (context, error) => Container(
                color: Colors.red[50],
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 32),
                      SizedBox(height: 8),
                      Text('Failed to load', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
