import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:catch_this_ai/core/utils/file_utils.dart';

/// Enhanced Enum to manage Model Types and their paths
// TODO: This assumes only one model per type (ASR/KWS). Will need to adjust if multiple models are supported.
enum SherpaModel {
  // Define the Enum cases with their directory names
  kws(
    folderName: 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01',
    type: 'kws',
  ),
  asr(
    folderName: 'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
    type: 'asr',
  );

  final String folderName;
  final String type; // 'asr' or 'kws' - helps map from settings

  const SherpaModel({required this.folderName, required this.type});

  // Helper getter for the full asset path
  String get assetPath => 'assets/$folderName';

  // Static helper to get a model from the simple string saved in Settings ('asr' or 'kws')
  static SherpaModel getSherpaModel(String serviceType) {
    // Get the first matching model, or default to ASR
    return SherpaModel.values.firstWhere(
      (m) => m.type == serviceType.toLowerCase(),
      orElse: () => SherpaModel.asr,
    );
  }
}

// Load Sherpa ONNX online model configuration based on the Enum SherpaModel
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig({
  required SherpaModel model,
}) async {
  final modelDir = model.assetPath;

  switch (model) {
    // Assumes only one model per type
    case SherpaModel.kws:
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
            '$modelDir/encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx',
          ),
          decoder: await copyAssetFile(
            '$modelDir/decoder-epoch-12-avg-2-chunk-16-left-64.onnx',
          ),
          joiner: await copyAssetFile(
            '$modelDir/joiner-epoch-12-avg-2-chunk-16-left-64.onnx',
          ),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );

    case SherpaModel.asr:
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
            '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
          ),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer',
        modelingUnit: 'cjkchar+bpe',
        bpeVocab: await copyAssetFile('$modelDir/bpe.vocab'),
      );
  }
}

// Get device path for keywords file
Future<String> getKeywordsFilePath(SherpaModel model) async {
  return await copyAssetFile('${model.assetPath}/keywords.txt');
}

// Get a list of raw keywords
Future<List<String>> getRawKeywords(SherpaModel model) async {
  const fileName = 'keywords_raw.txt';
  final rawKeywordsFilePath = await copyAssetFile(
    '${model.assetPath}/$fileName',
  );
  final keywordsFile = File(rawKeywordsFilePath);

  // Return empty list if file doesn't exist
  if (!await keywordsFile.exists()) return [];

  final content = await keywordsFile.readAsLines();
  // if the line ends with :<number>, remove that part. :<number> indicates the sensitivity score and is likely used with ASR models.
  return content.where((line) => line.trim().isNotEmpty).map((line) {
    final parts = line.split(':');
    return parts[0].trim();
  }).toList();
}
