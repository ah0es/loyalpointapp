import 'dart:typed_data';
import 'package:archive/archive.dart';

class ZipBundler {
  /// Creates .pkpass ZIP file from all components
  static Uint8List createPkpass({
    required Uint8List passJsonBytes,
    required Uint8List manifestBytes,
    required Uint8List signatureBytes,
    required Uint8List iconBytes,
    required Uint8List icon2xBytes,
    required Uint8List logoBytes,
    required Uint8List logo2xBytes,
    Uint8List? icon3xBytes,
    Uint8List? logo3xBytes,
  }) {
    final archive = Archive();

    // Add all files to archive (ORDER DOESN'T MATTER)
    archive.addFile(_createFile('pass.json', passJsonBytes));
    archive.addFile(_createFile('manifest.json', manifestBytes));
    archive.addFile(_createFile('signature', signatureBytes)); // No extension!
    archive.addFile(_createFile('icon.png', iconBytes));
    archive.addFile(_createFile('icon@2x.png', icon2xBytes));
    archive.addFile(_createFile('logo.png', logoBytes));
    archive.addFile(_createFile('logo@2x.png', logo2xBytes));
    if (icon3xBytes != null && icon3xBytes.isNotEmpty) {
      archive.addFile(_createFile('icon@3x.png', icon3xBytes));
    }
    if (logo3xBytes != null && logo3xBytes.isNotEmpty) {
      archive.addFile(_createFile('logo@3x.png', logo3xBytes));
    }

    // Encode to ZIP
    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes!);
  }

  /// Helper to create ArchiveFile
  static ArchiveFile _createFile(String name, Uint8List bytes) {
    return ArchiveFile(name, bytes.length, bytes);
  }
}
