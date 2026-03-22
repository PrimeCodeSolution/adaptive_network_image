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

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  BoxFit _selectedFit = BoxFit.cover;

  static const _fitOptions = [
    BoxFit.cover,
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
    BoxFit.scaleDown,
    BoxFit.none,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Network Image Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BoxFit selector
            Row(
              children: [
                const Text('BoxFit: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<BoxFit>(
                  value: _selectedFit,
                  onChanged: (fit) => setState(() => _selectedFit = fit!),
                  items: _fitOptions
                      .map((fit) => DropdownMenuItem(
                            value: fit,
                            child: Text(fit.name),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Landscape image in a square container (tests aspect ratio handling)
            const Text('Landscape image in 300x300 square:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AdaptiveNetworkImage(
                imageUrl: 'https://picsum.photos/600/300',
                width: 300,
                height: 300,
                fit: _selectedFit,
                borderRadius: BorderRadius.circular(12),
                onStrategyResolved: (strategy) {
                  debugPrint('Landscape image loaded via: ${strategy.name}');
                },
              ),
            ),
            const SizedBox(height: 24),

            // Portrait image in a wide container (tests aspect ratio handling)
            const Text('Portrait image in 400x200 wide container:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AdaptiveNetworkImage(
                imageUrl: 'https://picsum.photos/300/600?random=2',
                width: 400,
                height: 200,
                fit: _selectedFit,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Standard image
            const Text('Standard 300x200:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AdaptiveNetworkImage(
                imageUrl: 'https://picsum.photos/300/200?random=3',
                width: 300,
                height: 200,
                fit: _selectedFit,
                borderRadius: BorderRadius.circular(12),
                placeholder: (context) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Loading...')),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error state
            const Text('Error state:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AdaptiveNetworkImage(
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
                        Text('Failed to load',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
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
