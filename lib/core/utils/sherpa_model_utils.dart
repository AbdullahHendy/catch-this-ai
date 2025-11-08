import 'dart:io';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:catch_this_ai/core/utils/file_utils.dart';

// Models should be added to assets folder
// Model should be added in `assets` in ../pubspec.yaml

// Available models constant array
const sherpaModelNames = [
  // https://k2-fsa.github.io/sherpa/onnx/kws/pretrained_models/index.html#sherpa-onnx-kws-zipformer-gigaspeech-3-3m-2024-01-01-english
  'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01',
  // https://k2-fsa.github.io/sherpa/onnx/pretrained_models/online-transducer/zipformer-transducer-models.html#csukuangfj-sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20-bilingual-chinese-english
  'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
];

// Load Sherpa ONNX online model configuration based on model name
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig({
  required String modelName,
}) async {
  switch (modelName) {
    case 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01':
      final modelDir =
          'assets/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';
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

    case 'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20':
      final modelDir =
          'assets/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';
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

    default:
      throw ArgumentError('Unsupported model: $modelName');
  }
}

// Get device path for keywords file for a given model (keywords.txt in KWS models and keywords_raw.txt in ASR models)
Future<String> getKeywordsFilePath(String modelName) async {
  // If model name not in supported list, throw error
  if (!sherpaModelNames.contains(modelName)) {
    throw ArgumentError('Unsupported model: $modelName');
  }
  final modelDir = 'assets/$modelName';
  return await copyAssetFile('$modelDir/keywords.txt');
}

// Get a list of raw keywords for a given model
Future<List<String>> getRawKeywords(String modelName) async {
  // If model name not in supported list, throw error
  if (!sherpaModelNames.contains(modelName)) {
    throw ArgumentError('Unsupported model: $modelName');
  }
  final modelDir = 'assets/$modelName';
  final rawKeywordsFilePath = await copyAssetFile('$modelDir/keywords_raw.txt');
  final keywordsFile = File(rawKeywordsFilePath);
  final content = await keywordsFile.readAsLines();
  // if the line ends with :<number>, remove that part
  return content.where((line) => line.trim().isNotEmpty).map((line) {
    final parts = line.split(':');
    return parts[0].trim();
  }).toList();
}
