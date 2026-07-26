import 'package:adaptive_network_image/adaptive_network_image.dart';
import 'package:flutter/material.dart';

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

  /// Deliberately different shapes, so the list shows each image taking the
  /// height its own aspect ratio implies rather than a hardcoded one.
  static const _listImages = <({String label, String url})>[
    (label: 'Wide 2:1', url: 'https://picsum.photos/800/400?random=10'),
    (label: 'Square 1:1', url: 'https://picsum.photos/400/400?random=11'),
    (label: 'Portrait 2:3', url: 'https://picsum.photos/400/600?random=12'),
  ];

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
                const Text(
                  'BoxFit: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

            // Unsized images inside a scrolling list. A vertical ListView gives
            // its children an unbounded height, which used to crash on web
            // because the platform view expanded to fill infinity. Each image
            // now sizes itself from its natural aspect ratio instead.
            const Text('In a scrolling list (no width or height):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              // Narrow and short on purpose: each row is then clearly taller or
              // shorter than the next, which is the behaviour being shown.
              width: 320,
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _listImages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final (:label, :url) = _listImages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      AdaptiveNetworkImage(
                        imageUrl: url,
                        fit: _selectedFit,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                },
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
