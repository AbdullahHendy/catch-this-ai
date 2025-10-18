import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

// Copy the asset file from src to dst on the device
Future<String> copyAssetFile(String src, [String? dst]) async {
  final Directory directory = await getApplicationSupportDirectory();
  dst ??= basename(src);
  final target = join(directory.path, dst);
  bool exists = await File(target).exists();

  final data = await rootBundle.load(src);

  if (!exists || File(target).lengthSync() != data.lengthInBytes) {
    final List<int> bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(target).writeAsBytes(bytes);
  }

  return target;
}
