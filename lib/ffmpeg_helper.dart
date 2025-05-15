import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart'; // For ZipDecoder
// import 'package:archive/archive_io.dart'; // Not strictly needed for this basic extraction

// No need for 'dart:typed_data' import if ByteData is directly from services.dart

class FfmpegHelper {
  static String?
      _cachedFfmpegPath; // Cache the path after first successful extraction

  static Future<String?> getFfmpegPath() async {
    if (_cachedFfmpegPath != null && await File(_cachedFfmpegPath!).exists()) {
      // Optional: Add a version check here if you plan to update ffmpeg
      // If version matches, return cached path. Otherwise, proceed to re-extract.
      print('FFmpeg path cache hit: $_cachedFfmpegPath');
      return _cachedFfmpegPath;
    }

    String ffmpegZipAssetName;
    String ffmpegExecutableNameInZip; // Name of the executable INSIDE the zip
    String
        ffmpegExecutableNameOnDisk; // Name of the executable on disk (can be same)

    if (Platform.isWindows) {
      ffmpegZipAssetName = 'assets/ffmpeg/windows/ffmpeg.zip';
      ffmpegExecutableNameInZip = 'ffmpeg.exe';
      ffmpegExecutableNameOnDisk = 'ffmpeg.exe';
    } else if (Platform.isMacOS) {
      ffmpegZipAssetName = 'assets/ffmpeg/macos/ffmpeg.zip';
      ffmpegExecutableNameInZip = 'ffmpeg';
      ffmpegExecutableNameOnDisk = 'ffmpeg';
    } else if (Platform.isLinux) {
      ffmpegZipAssetName = 'assets/ffmpeg/linux/ffmpeg.zip';
      ffmpegExecutableNameInZip = 'ffmpeg';
      ffmpegExecutableNameOnDisk = 'ffmpeg';
    } else {
      print('Unsupported platform for FFmpeg.');
      return null;
    }

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      // You might want a dedicated subdirectory for your app's binaries
      final ffmpegDir = Directory(p.join(appSupportDir.path, 'reducio_bin'));
      if (!await ffmpegDir.exists()) {
        await ffmpegDir.create(recursive: true);
      }

      final ffmpegDestFile =
          File(p.join(ffmpegDir.path, ffmpegExecutableNameOnDisk));

      // --- Logic to check if extraction is needed ---
      // You could store a version number or checksum of the bundled zip
      // in SharedPreferences and compare it. If different, re-extract.
      // For simplicity now, we'll re-extract if the destination file doesn't exist.
      // A more robust check would involve versioning.

      if (!await ffmpegDestFile.exists()) {
        print('FFmpeg not found at ${ffmpegDestFile.path}, extracting...');
        // Load the ZIP asset
        final ByteData zipData = await rootBundle.load(ffmpegZipAssetName);
        final List<int> zipBytes = zipData.buffer
            .asUint8List(zipData.offsetInBytes, zipData.lengthInBytes);

        // Decode the ZIP
        final archive = ZipDecoder().decodeBytes(zipBytes);

        // Find the FFmpeg executable within the archive
        ArchiveFile? ffmpegArchiveFile;
        for (final fileInArchive in archive) {
          if (fileInArchive.name == ffmpegExecutableNameInZip &&
              fileInArchive.isFile) {
            ffmpegArchiveFile = fileInArchive;
            break;
          }
        }

        if (ffmpegArchiveFile == null) {
          print(
              'Error: Could not find "$ffmpegExecutableNameInZip" inside "$ffmpegZipAssetName".');
          return null;
        }

        // Write the extracted FFmpeg executable to the app support directory
        final List<int> ffmpegExecutableBytes =
            ffmpegArchiveFile.content as List<int>;
        await ffmpegDestFile.writeAsBytes(ffmpegExecutableBytes, flush: true);
        print('FFmpeg extracted to: ${ffmpegDestFile.path}');

        // Set executable permission for macOS and Linux
        if (Platform.isMacOS || Platform.isLinux) {
          final result =
              await Process.run('chmod', ['+x', ffmpegDestFile.path]);
          if (result.exitCode != 0) {
            print(
                'Error setting executable permission for FFmpeg: ${result.stderr}');
            // Optionally, you could try to delete the file if chmod fails, so it retries next time.
            // await ffmpegDestFile.delete();
            return null; // Indicate failure
          }
          print('Executable permission set for FFmpeg.');
        }
      } else {
        print('FFmpeg already exists at: ${ffmpegDestFile.path}');
        // If it exists, ensure it has execute permission (e.g., if app was updated and permissions were lost)
        if ((Platform.isMacOS || Platform.isLinux) &&
            !(await _isExecutable(ffmpegDestFile.path))) {
          print('FFmpeg exists but is not executable. Setting permissions...');
          final result =
              await Process.run('chmod', ['+x', ffmpegDestFile.path]);
          if (result.exitCode != 0) {
            print(
                'Error re-setting executable permission for FFmpeg: ${result.stderr}');
            return null;
          }
          print('Executable permission re-set for FFmpeg.');
        }
      }

      _cachedFfmpegPath = ffmpegDestFile.path;
      return _cachedFfmpegPath;
    } catch (e, s) {
      print('Error getting/extracting FFmpeg path: $e');
      print('Stack trace: $s');
      return null;
    }
  }

  // Helper to check if a file is executable on macOS/Linux
  static Future<bool> _isExecutable(String filePath) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return true; // Not applicable elsewhere
    }
    try {
      final result = await Process.run('test', ['-x', filePath]);
      return result.exitCode == 0;
    } catch (e) {
      print("Error checking executable status: $e");
      return false; // Assume not executable on error
    }
  }
}
