import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; // For getDownloadsDirectory and getTemporaryDirectory
import 'dart:io';
import 'package:reducio/ffmpeg_helper.dart'; // Ensure this path is correct
import 'package:path/path.dart' as p;

// New imports for UI changes
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';

class RemoveAudioTab extends StatefulWidget {
  const RemoveAudioTab({super.key});

  @override
  State<RemoveAudioTab> createState() => _RemoveAudioTabState();
}

class _RemoveAudioTabState extends State<RemoveAudioTab> {
  String? _inputFilePath;
  String? _outputFilePath;
  String _statusMessage = 'Ready to remove audio!';
  double _progressValue = 0.0;
  bool _isProcessing = false;

  // For output TextField
  late TextEditingController _outputFileController;

  // For drag and drop highlighting
  bool _isDragOverInput = false;

  @override
  void initState() {
    super.initState();
    _outputFileController = TextEditingController(text: _outputFilePath);
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
          : 'mp4'; // Default extension if input has none

      String baseName = '${inputFileName}_noaudio';
      _outputFilePath = await _generateUniqueOutputFilePath(inputDirectory, baseName, inputFileExtension);
      _outputFileController.text = _outputFilePath ?? '';
    } else {
      _outputFilePath = null;
      _outputFileController.text = '';
    }
  }

  Future<void> _pickInputFile({String? droppedFilePath}) async {
    String? selectedPath;
    if (droppedFilePath != null) {
      selectedPath = droppedFilePath;
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video, // Suggest video files
      );
      if (result != null && result.files.single.path != null) {
        selectedPath = result.files.single.path;
      }
    }

    if (selectedPath != null) {
      setState(() {
        _inputFilePath = selectedPath;
        _updateOutputFilePathSuggestion();
        _statusMessage = 'Input video selected. Ready for audio removal.';
      });
    }
  }

  Future<void> _pickOutputFile() async {
    String? initialDirectory;
    String? initialFileName;

    if (_outputFileController.text.isNotEmpty) {
        try {
            initialDirectory = p.dirname(_outputFileController.text);
            initialFileName = p.basename(_outputFileController.text);
        } catch (e) {
            if (_inputFilePath != null) {
                initialDirectory = p.dirname(_inputFilePath!);
            } else {
                initialDirectory = (await getDownloadsDirectory())?.path;
            }
            initialFileName = null;
        }
    } else if (_inputFilePath != null) {
      initialDirectory = p.dirname(_inputFilePath!);
    } else {
      initialDirectory = (await getDownloadsDirectory())?.path;
    }
    
    String? result = await FilePicker.platform.saveFile(
      dialogTitle: 'Set Output Video Path (No Audio)...',
      initialDirectory: initialDirectory,
      fileName: initialFileName,
    );

    if (result != null) {
      setState(() {
        _outputFilePath = result;
        _outputFileController.text = result;
        _statusMessage = 'Output file path set. Ready for audio removal.';
      });
    }
  }

  void _startRemoveAudio() async {
    if (_inputFilePath == null) {
      setState(() { _statusMessage = 'Error: Please select an input video file.'; });
      return;
    }

    if (_outputFileController.text.isEmpty) {
      await _updateOutputFilePathSuggestion();
      if (_outputFilePath == null || _outputFilePath!.isEmpty) {
        setState(() { _statusMessage = 'Error: Please specify an output file path.'; });
        return;
      }
    } else {
      _outputFilePath = _outputFileController.text;
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

    // FFmpeg command: -i input.mp4 -c:v copy -an output_no_audio.mp4
    // -c:v copy : Copies the video stream without re-encoding (fast)
    // -an : No audio (removes all audio streams)
    List<String> ffmpegArgs = [
      '-i', _inputFilePath!,
      '-c:v', 'copy',
      '-an',
      '-y', _outputFilePath!
    ];

    if (!mounted) return;
    setState(() {
      _statusMessage = 'Starting audio removal... (Usually quick)';
    });

    print('Running FFmpeg: $ffmpegPath ${ffmpegArgs.join(' ')}');

    try {
      final ProcessResult result = await Process.run(ffmpegPath, ffmpegArgs);
      if (!mounted) return;
      if (result.exitCode == 0) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Audio successfully removed! Output: $_outputFilePath';
          _progressValue = 1.0;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error removing audio. FFmpeg exit code: ${result.exitCode}\nError: ${result.stderr}';
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

  // Helper for section cards, same as in CompressTab
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double contentMaxWidth = 1200.0;

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
          padding: EdgeInsets.zero,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isDragOverInput 
                  ? theme.colorScheme.primary.withOpacity(0.1) 
                  : theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _inputFilePath != null ? Icons.check_circle_outline_rounded : Icons.movie_filter_outlined, // Video specific icon
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
                          : 'Drop video file here or Click to Browse',
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
        Text("Input Video File", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        dropZone,
      ],
    );

    Widget outputFileSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Output Video (No Audio)", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: _outputFileController,
          decoration: InputDecoration(
            hintText: 'Output path...',
            filled: theme.inputDecorationTheme.filled,
            fillColor: theme.inputDecorationTheme.fillColor,
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintStyle: theme.inputDecorationTheme.hintStyle,
          ),
          onChanged: (value) {
            _outputFilePath = value;
          },
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: const Text('Browse...'),
            onPressed: _pickOutputFile,
          ),
        )
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
                title: "Video Files",
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: inputFileSection),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(top: 75),
                        child: Icon(Icons.east_outlined, size: 30, color: theme.colorScheme.primary.withOpacity(0.8)),
                      ),
                      Expanded(flex: 3, child: outputFileSection),
                    ],
                  ),
                ]
              ),
              // No settings section for "Remove Audio"
              const SizedBox(height: 24),
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progressValue == 0.0 && _statusMessage.startsWith("Preparing")
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
                icon: const Icon(Icons.volume_off_rounded, size: 30), // Icon for remove audio
                label: const Text('Remove Audio Track'),
                onPressed: _isProcessing ? null : _startRemoveAudio,
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