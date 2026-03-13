import 'dart:typed_data';

import 'package:fast_image_editor/fast_image_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

enum FilterType {
  blur,
  sepia,
  grayscale,
  brightness,
  contrast,
  sharpen,
  saturation,
}

enum RegionMode { full, rect, radial }

class _EditorDemoState extends State<EditorDemo> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _originalBytes;
  Uint8List? _editedBytes;
  bool _processing = false;

  // Filter state
  FilterType _selectedFilter = FilterType.blur;
  RegionMode _regionMode = RegionMode.full;

  // Filter params
  double _blurRadius = 15;
  double _sepiaIntensity = 0.8;
  double _brightnessFactor = 0.3;
  double _contrastFactor = 1.5;
  double _sharpenAmount = 2.0;
  int _sharpenRadius = 2;
  double _saturationFactor = 2.0;

  // Rect region params
  double _regionTop = 0.0;
  double _regionBottom = 0.0;
  double _regionLeft = 0.0;
  double _regionRight = 0.0;

  // Radial region params
  double _radialCx = 0.0;
  double _radialCy = 0.0;
  double _radialRadius = 0.3;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _originalBytes = bytes;
      _editedBytes = null;
    });
  }

  void _applyFilter() {
    if (_originalBytes == null) return;
    setState(() => _processing = true);

    try {
      EditRegion? region;
      RadialRegion? radialRegion;

      if (_regionMode == RegionMode.rect) {
        region = EditRegion(
          top: _regionTop,
          bottom: _regionBottom,
          left: _regionLeft,
          right: _regionRight,
        );
      } else if (_regionMode == RegionMode.radial) {
        radialRegion = RadialRegion(
          centerX: _radialCx,
          centerY: _radialCy,
          radius: _radialRadius,
        );
      }

      final Uint8List result;
      switch (_selectedFilter) {
        case FilterType.blur:
          result = FastImageEditor.blur(
            bytes: _originalBytes!,
            radius: _blurRadius.round(),
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.sepia:
          result = FastImageEditor.sepia(
            bytes: _originalBytes!,
            intensity: _sepiaIntensity,
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.grayscale:
          result = FastImageEditor.grayscale(
            bytes: _originalBytes!,
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.brightness:
          result = FastImageEditor.brightness(
            bytes: _originalBytes!,
            factor: _brightnessFactor,
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.contrast:
          result = FastImageEditor.contrast(
            bytes: _originalBytes!,
            factor: _contrastFactor,
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.sharpen:
          result = FastImageEditor.sharpen(
            bytes: _originalBytes!,
            amount: _sharpenAmount,
            radius: _sharpenRadius,
            region: region,
            radialRegion: radialRegion,
          );
        case FilterType.saturation:
          result = FastImageEditor.saturation(
            bytes: _originalBytes!,
            factor: _saturationFactor,
            region: region,
            radialRegion: radialRegion,
          );
      }

      setState(() {
        _editedBytes = result;
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback fn) {
            fn();
            setSheetState(() {});
            setState(() {});
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Filter Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Filter type
                Text(
                  'Filter',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FilterType.values.map((f) {
                    return ChoiceChip(
                      label: Text(f.name),
                      selected: _selectedFilter == f,
                      onSelected: (_) => update(() => _selectedFilter = f),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Filter-specific params
                ..._buildFilterParams(update),

                const Divider(height: 32),

                // Region mode
                Text(
                  'Region',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<RegionMode>(
                  segments: const [
                    ButtonSegment(value: RegionMode.full, label: Text('Full')),
                    ButtonSegment(value: RegionMode.rect, label: Text('Rect')),
                    ButtonSegment(
                        value: RegionMode.radial, label: Text('Radial')),
                  ],
                  selected: {_regionMode},
                  onSelectionChanged: (v) =>
                      update(() => _regionMode = v.first),
                ),
                const SizedBox(height: 16),

                // Region params
                if (_regionMode == RegionMode.rect) ...[
                  _SliderRow(
                    label: 'Top',
                    value: _regionTop,
                    min: 0,
                    max: 1,
                    onChanged: (v) => update(() => _regionTop = v),
                  ),
                  _SliderRow(
                    label: 'Bottom',
                    value: _regionBottom,
                    min: 0,
                    max: 1,
                    onChanged: (v) => update(() => _regionBottom = v),
                  ),
                  _SliderRow(
                    label: 'Left',
                    value: _regionLeft,
                    min: 0,
                    max: 1,
                    onChanged: (v) => update(() => _regionLeft = v),
                  ),
                  _SliderRow(
                    label: 'Right',
                    value: _regionRight,
                    min: 0,
                    max: 1,
                    onChanged: (v) => update(() => _regionRight = v),
                  ),
                ],
                if (_regionMode == RegionMode.radial) ...[
                  _SliderRow(
                    label: 'Center X',
                    value: _radialCx,
                    min: -1,
                    max: 1,
                    onChanged: (v) => update(() => _radialCx = v),
                  ),
                  _SliderRow(
                    label: 'Center Y',
                    value: _radialCy,
                    min: -1,
                    max: 1,
                    onChanged: (v) => update(() => _radialCy = v),
                  ),
                  _SliderRow(
                    label: 'Radius',
                    value: _radialRadius,
                    min: 0.01,
                    max: 1,
                    onChanged: (v) => update(() => _radialRadius = v),
                  ),
                ],

                const SizedBox(height: 16),

                // Apply button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilter();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFilterParams(void Function(VoidCallback) update) {
    switch (_selectedFilter) {
      case FilterType.blur:
        return [
          _SliderRow(
            label: 'Radius',
            value: _blurRadius,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (v) => update(() => _blurRadius = v),
          ),
        ];
      case FilterType.sepia:
        return [
          _SliderRow(
            label: 'Intensity',
            value: _sepiaIntensity,
            min: 0,
            max: 1,
            onChanged: (v) => update(() => _sepiaIntensity = v),
          ),
        ];
      case FilterType.grayscale:
        return [];
      case FilterType.brightness:
        return [
          _SliderRow(
            label: 'Factor',
            value: _brightnessFactor,
            min: -1,
            max: 1,
            onChanged: (v) => update(() => _brightnessFactor = v),
          ),
        ];
      case FilterType.contrast:
        return [
          _SliderRow(
            label: 'Factor',
            value: _contrastFactor,
            min: 0,
            max: 2,
            onChanged: (v) => update(() => _contrastFactor = v),
          ),
        ];
      case FilterType.sharpen:
        return [
          _SliderRow(
            label: 'Amount',
            value: _sharpenAmount,
            min: 0,
            max: 5,
            onChanged: (v) => update(() => _sharpenAmount = v),
          ),
          _SliderRow(
            label: 'Radius',
            value: _sharpenRadius.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => update(() => _sharpenRadius = v.round()),
          ),
        ];
      case FilterType.saturation:
        return [
          _SliderRow(
            label: 'Factor',
            value: _saturationFactor,
            min: 0,
            max: 3,
            onChanged: (v) => update(() => _saturationFactor = v),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _editedBytes ?? _originalBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Image Editor'),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_originalBytes != null)
            FloatingActionButton(
              heroTag: 'filter',
              onPressed: _showFilterSheet,
              child: const Icon(Icons.tune),
            ),
          if (_originalBytes != null) const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'pick',
            onPressed: _pickImage,
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.contain)
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Tap the gallery button to pick an image'),
                      ],
                    ),
            ),
          ),
          if (_processing) const LinearProgressIndicator(),
          if (_originalBytes != null && _editedBytes != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _editedBytes = null;
                  }),
                  icon: const Icon(Icons.undo),
                  label: const Text('Reset to original'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
