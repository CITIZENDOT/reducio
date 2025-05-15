import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; // For getDownloadsDirectory and getTemporaryDirectory
import 'dart:io';
import 'package:reducio/ffmpeg_helper.dart'; // Ensure this path is correct
import 'package:path/path.dart' as p;
// import 'dart:developer'; // Not used in this version, can be removed

// New imports for UI changes
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';

class CompressTab extends StatefulWidget {
  const CompressTab({super.key});

  @override
  State<CompressTab> createState() => _CompressTabState();
}

class _CompressTabState extends State<CompressTab> {
  String? _inputFilePath;
  String? _outputFilePath;
  // String _videoQuality = 'Medium Quality (Smaller File)'; // Replaced by slider
  // String _audioQuality = '128 kbps'; // Replaced by slider
  String _statusMessage = 'Ready to compress your media!';
  double _progressValue = 0.0;
  bool _isProcessing = false;

  // For output TextField
  late TextEditingController _outputFileController;

  // Slider values
  double _videoQualitySliderValue = 1.0; // Default to Medium (index 1 for CRF 23)
  double _audioQualitySliderValue = 2.0; // Default to 128 kbps (index 2)

  // "Keep Original" states
  bool _keepOriginalVideo = false;
  bool _keepOriginalAudio = false;

  // For drag and drop highlighting
  bool _isDragOverInput = false;

  // Mappings for sliders
  final List<String> _videoQualitySliderLabels = ['Low (CRF 28)', 'Medium (CRF 23)', 'Good (CRF 20)', 'High (CRF 18)'];
  final List<String> _audioQualitySliderLabels = ['64 kbps', '96 kbps', '128 kbps', '192 kbps', '256 kbps', '320 kbps'];

  @override
  void initState() {
    super.initState();
    _outputFileController = TextEditingController(text: _outputFilePath);
    // If you had default string values you wanted to map to initial slider positions,
    // you would do that here. For now, we use the default double values.
  }

  @override
  void dispose() {
    _outputFileController.dispose();
    super.dispose();
  }
  
  Future<String> _generateUniqueOutputFilePath(String directory, String baseName, String extension) async {
    String potentialName = '$baseName.$extension';
    File potentialFile = File(p.join(directory, potentialName));
    int counter = 1;

    while (await potentialFile.exists()) {
      potentialName = '${baseName}_$counter.$extension';
      potentialFile = File(p.join(directory, potentialName));
      counter++;
    }
    return potentialFile.path;
  }

  Future<void> _updateOutputFilePathSuggestion() async {
    if (_inputFilePath != null) {
      final String inputDirectory = p.dirname(_inputFilePath!);
      final String inputFileName = p.basenameWithoutExtension(_inputFilePath!);
      final String inputFileExtension = p.extension(_inputFilePath!).isNotEmpty
          ? p.extension(_inputFilePath!).substring(1) // Remove leading '.'
          : 'mp4';

      String baseName = '${inputFileName}_compressed';
      // Use the themed name if you prefer:
      // String baseName = '${inputFileName}_reducio';
      _outputFilePath = await _generateUniqueOutputFilePath(inputDirectory, baseName, inputFileExtension);
      _outputFileController.text = _outputFilePath ?? '';
    } else {
      _outputFilePath = null;
      _outputFileController.text = '';
    }
  }

  Future<void> _pickInputFile({String? droppedFilePath}) async {
    final supportDir = await getApplicationSupportDirectory();
    log('SupportDir = $supportDir');

    String? selectedPath;
    if (droppedFilePath != null) {
      selectedPath = droppedFilePath;
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        selectedPath = result.files.single.path;
      }
    }

    if (selectedPath != null) {
      setState(() {
        _inputFilePath = selectedPath;
        _updateOutputFilePathSuggestion();
        _statusMessage = 'Input file selected. Ready to compress.';
      });
    }
  }

  Future<void> _pickOutputFile() async {
    String? initialDirectory;
    String? initialFileName;

    if (_outputFileController.text.isNotEmpty) { // Prioritize text field content
        try {
            initialDirectory = p.dirname(_outputFileController.text);
            initialFileName = p.basename(_outputFileController.text);
        } catch (e) { // Handle invalid paths in text field
            // Fallback if path in text field is invalid
            if (_inputFilePath != null) {
                initialDirectory = p.dirname(_inputFilePath!);
            } else {
                initialDirectory = (await getDownloadsDirectory())?.path;
            }
            initialFileName = null; // Let user pick name
        }
    } else if (_inputFilePath != null) {
      initialDirectory = p.dirname(_inputFilePath!);
    } else {
      initialDirectory = (await getDownloadsDirectory())?.path;
    }
    
    String? result = await FilePicker.platform.saveFile(
      dialogTitle: 'Set Output File Path...',
      initialDirectory: initialDirectory,
      fileName: initialFileName, // This will pre-fill if valid
    );

    if (result != null) {
      setState(() {
        _outputFilePath = result;
        _outputFileController.text = result;
        _statusMessage = 'Output file path set. Ready to compress.';
      });
    }
  }

  void _startCompression() async {
    if (_inputFilePath == null) {
      setState(() { _statusMessage = 'Error: Please select an input file.'; });
      return;
    }

    // Use the path from the text controller for output
    if (_outputFileController.text.isEmpty) {
      // If output controller is empty, try to auto-generate based on input
      await _updateOutputFilePathSuggestion(); 
      if (_outputFilePath == null || _outputFilePath!.isEmpty) { // Check _outputFilePath after suggestion
        setState(() { _statusMessage = 'Error: Please specify an output file path.'; });
        return;
      }
    } else {
      _outputFilePath = _outputFileController.text; // Ensure _outputFilePath is current
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Preparing FFmpeg...';
      _progressValue = 0.0;
    });

    final String? ffmpegPath = await FfmpegHelper.getFfmpegPath();
    if (ffmpegPath == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: Could not find or prepare FFmpeg executable.';
      });
      return;
    }

    List<String> ffmpegArgs = ['-i', _inputFilePath!];

    // Video Settings
    if (_keepOriginalVideo) {
      ffmpegArgs.addAll(['-c:v', 'copy']);
    } else {
      ffmpegArgs.addAll(['-c:v', 'libx264']);
      ffmpegArgs.addAll(['-preset', 'medium']);
      int videoSliderIdx = _videoQualitySliderValue.round();
      if (videoSliderIdx == 0) ffmpegArgs.addAll(['-crf', '28']); // Low
      else if (videoSliderIdx == 1) ffmpegArgs.addAll(['-crf', '23']); // Medium
      else if (videoSliderIdx == 2) ffmpegArgs.addAll(['-crf', '20']); // Good
      else if (videoSliderIdx == 3) ffmpegArgs.addAll(['-crf', '18']); // High
    }

    // Audio Settings
    if (_keepOriginalAudio) {
      ffmpegArgs.addAll(['-c:a', 'copy']);
    } else {
      ffmpegArgs.addAll(['-c:a', 'aac']);
      int audioSliderIdx = _audioQualitySliderValue.round();
      final bitrates = ['64k', '96k', '128k', '192k', '256k', '320k'];
      if (audioSliderIdx >= 0 && audioSliderIdx < bitrates.length) {
          ffmpegArgs.addAll(['-b:a', bitrates[audioSliderIdx]]);
      } else {
          ffmpegArgs.addAll(['-b:a', '128k']); // Fallback, should not happen with slider
      }
    }

    ffmpegArgs.addAll(['-y', _outputFilePath!]);

    if (!mounted) return;
    setState(() {
      _statusMessage = 'Starting compression... (This may take a while)';
    });

    print('Running FFmpeg: $ffmpegPath ${ffmpegArgs.join(' ')}');

    try {
      final ProcessResult result = await Process.run(ffmpegPath, ffmpegArgs);
      if (!mounted) return;
      if (result.exitCode == 0) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Successfully compressed! Output: $_outputFilePath';
          _progressValue = 1.0;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error during compression. FFmpeg exit code: ${result.exitCode}\nError: ${result.stderr}';
          _progressValue = 0.0;
        });
        print('FFmpeg stdout: ${result.stdout}');
        print('FFmpeg stderr: ${result.stderr}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error running FFmpeg: $e';
      });
      print('Exception running FFmpeg: $e');
    }
  }


  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // This label is now part of the slider helper or direct Text widgets
  // Widget _buildLabel(String text) { ... }

  // This file row is replaced by the new layout
  // Widget _buildFileRow({ ... }) { ... }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double contentMaxWidth = 1200.0; // Max width for the content area

    Widget dropZone = DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          _pickInputFile(droppedFilePath: detail.files.first.path);
        }
        setState(() { _isDragOverInput = false; });
      },
      onDragEntered: (detail) { setState(() { _isDragOverInput = true; }); },
      onDragExited: (detail) { setState(() { _isDragOverInput = false; }); },
      child: InkWell(
        onTap: () => _pickInputFile(),
        borderRadius: BorderRadius.circular(12),
        child: DottedBorder(
          color: _isDragOverInput ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.7),
          strokeWidth: 2,
          dashPattern: const [8, 6],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          padding: EdgeInsets.zero, // Important for DottedBorder to wrap Container tightly
          child: Container(
            height: 150,
            width: double.infinity, // Takes width of its parent (Expanded)
            decoration: BoxDecoration(
              color: _isDragOverInput 
                  ? theme.colorScheme.primary.withOpacity(0.1) 
                  : theme.colorScheme.surface.withOpacity(0.1), // Use surface for a more subtle bg
              borderRadius: BorderRadius.circular(11), // Slightly less than DottedBorder radius
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _inputFilePath != null ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
                    size: 48,
                    color: _inputFilePath != null 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _inputFilePath != null 
                          ? p.basename(_inputFilePath!) 
                          : 'Drop file here or Click to Browse',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(_inputFilePath != null ? 0.9 : 0.7)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Widget inputFileSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Input File", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        dropZone,
      ],
    );

    Widget outputFileSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Output File", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: _outputFileController,
          decoration: InputDecoration( // Create a new InputDecoration object
            hintText: 'Output path...',
            // You can copy relevant properties from theme.inputDecorationTheme if needed:
            filled: theme.inputDecorationTheme.filled,
            fillColor: theme.inputDecorationTheme.fillColor,
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Provide a default if null
            hintStyle: theme.inputDecorationTheme.hintStyle,
          ),
          onChanged: (value) {
            _outputFilePath = value; // Keep _outputFilePath in sync with controller
          },
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18), // Changed icon
            label: const Text('Browse...'),
            onPressed: _pickOutputFile,
          ),
        )
      ],
    );

    Widget _buildQualitySlider({
      required String title,
      required bool isKeepOriginal,
      required ValueChanged<bool?> onKeepOriginalChanged,
      required double sliderValue,
      required ValueChanged<double> onSliderChanged,
      required List<String> labels,
      required bool isEnabled,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Keep Original', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                  const SizedBox(width: 4),
                  Switch(
                    value: isKeepOriginal,
                    onChanged: onKeepOriginalChanged,
                    activeColor: theme.colorScheme.primary,
                    inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.4),
                    inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ],
              )
            ],
          ),
          SliderTheme( // Wrap Slider in SliderTheme for more control if needed
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isEnabled ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.5),
              inactiveTrackColor: isEnabled ? theme.colorScheme.primary.withOpacity(0.3) : theme.disabledColor.withOpacity(0.2),
              thumbColor: isEnabled ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.7),
              overlayColor: isEnabled ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
              valueIndicatorColor: theme.colorScheme.primary.withOpacity(0.8),
              valueIndicatorTextStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            child: Slider(
              value: sliderValue,
              min: 0,
              max: (labels.length - 1).toDouble(),
              divisions: labels.length - 1,
              label: isEnabled ? labels[sliderValue.round()] : "Original",
              onChanged: isEnabled ? onSliderChanged : null,
            ),
          ),
          if (isEnabled)
            Align(
              alignment: Alignment.center,
              child: Text(labels[sliderValue.round()], style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)))
            ),
        ],
      );
    }

    Widget settingsSection = _buildSectionCard(
      title: "Compression Settings",
      children: [
        _buildQualitySlider(
          title: 'Video Quality',
          isKeepOriginal: _keepOriginalVideo,
          onKeepOriginalChanged: (value) { setState(() { _keepOriginalVideo = value ?? false; }); },
          sliderValue: _videoQualitySliderValue,
          onSliderChanged: (value) { setState(() { _videoQualitySliderValue = value; }); },
          labels: _videoQualitySliderLabels,
          isEnabled: !_keepOriginalVideo,
        ),
        const SizedBox(height: 16),
        _buildQualitySlider(
          title: 'Audio Quality',
          isKeepOriginal: _keepOriginalAudio,
          onKeepOriginalChanged: (value) { setState(() { _keepOriginalAudio = value ?? false; }); },
          sliderValue: _audioQualitySliderValue,
          onSliderChanged: (value) { setState(() { _audioQualitySliderValue = value; }); },
          labels: _audioQualitySliderLabels,
          isEnabled: !_keepOriginalAudio,
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSectionCard(
                title: "Files", // Changed title to be more generic for the card
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top of the row
                    children: [
                      Expanded(flex: 2, child: inputFileSection), // Give input more space if desired
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(top: 75), // Adjust top padding
                        child: Icon(Icons.east_outlined, size: 30, color: theme.colorScheme.primary.withOpacity(0.8)), // Made arrow bigger
                      ),
                      Expanded(flex: 3, child: outputFileSection), // Output might need more space for text field + button
                    ],
                  ),
                ]
              ),
              
              settingsSection,
              
              const SizedBox(height: 24),
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progressValue == 0.0 && _statusMessage.startsWith("Preparing") // Updated check
                            ? null
                            : _progressValue,
                        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        color: theme.colorScheme.secondary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 10),
                      Text(_statusMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: _statusMessage.toLowerCase().contains('error')
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 30), // Changed icon
                label: const Text('Compress Media'), // Using standard text
                onPressed: _isProcessing ? null : _startCompression,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                )
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}