import 'dart:typed_data';

import 'package:fast_image_editor/fast_image_editor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast Image Editor Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const EditorDemo(),
    );
  }
}

class EditorDemo extends StatefulWidget {
  const EditorDemo({super.key});

  @override
  State<EditorDemo> createState() => _EditorDemoState();
}

class _EditorDemoState extends State<EditorDemo> {
  Uint8List? _originalBytes;
  Uint8List? _editedBytes;
  String _currentFilter = 'Original';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadSampleImage();
  }

  Future<void> _loadSampleImage() async {
    // Load a sample image from assets or create a placeholder
    // In a real app, use image_picker or load from assets
    setState(() {
      _currentFilter = 'No image loaded';
    });
  }

  Future<void> _applyFilter(String name, Uint8List Function() apply) async {
    if (_originalBytes == null) return;
    setState(() => _processing = true);
    try {
      final result = apply();
      setState(() {
        _editedBytes = result;
        _currentFilter = name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _editedBytes ?? _originalBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Image Editor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Text(
            _currentFilter,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.contain)
                  : const Text('Load an image to get started'),
            ),
          ),
          if (_processing) const LinearProgressIndicator(),
          SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _FilterButton(
                    label: 'Blur',
                    onTap: () => _applyFilter(
                      'Blur (radius: 15)',
                      () => FastImageEditor.blur(
                        bytes: _originalBytes!,
                        radius: 15,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Blur Top',
                    onTap: () => _applyFilter(
                      'Blur Top 30%',
                      () => FastImageEditor.blur(
                        bytes: _originalBytes!,
                        radius: 20,
                        region: const EditRegion(top: 0.3),
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Sepia',
                    onTap: () => _applyFilter(
                      'Sepia',
                      () => FastImageEditor.sepia(
                        bytes: _originalBytes!,
                        intensity: 0.8,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Grayscale',
                    onTap: () => _applyFilter(
                      'Grayscale',
                      () => FastImageEditor.grayscale(
                        bytes: _originalBytes!,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Bright+',
                    onTap: () => _applyFilter(
                      'Brightness +0.3',
                      () => FastImageEditor.brightness(
                        bytes: _originalBytes!,
                        factor: 0.3,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Contrast',
                    onTap: () => _applyFilter(
                      'Contrast 1.5x',
                      () => FastImageEditor.contrast(
                        bytes: _originalBytes!,
                        factor: 1.5,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Sharpen',
                    onTap: () => _applyFilter(
                      'Sharpen',
                      () => FastImageEditor.sharpen(
                        bytes: _originalBytes!,
                        amount: 2.0,
                        radius: 2,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Saturation',
                    onTap: () => _applyFilter(
                      'Saturation 2x',
                      () => FastImageEditor.saturation(
                        bytes: _originalBytes!,
                        factor: 2.0,
                      ),
                    ),
                  ),
                  _FilterButton(
                    label: 'Reset',
                    onTap: () => setState(() {
                      _editedBytes = null;
                      _currentFilter = 'Original';
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
