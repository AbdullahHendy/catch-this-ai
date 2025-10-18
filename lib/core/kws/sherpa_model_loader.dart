import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:catch_this_ai/core/utils/file_utils.dart';

// Downloaded from: https://k2-fsa.github.io/sherpa/onnx/kws/pretrained_models/index.html#sherpa-onnx-kws-zipformer-gigaspeech-3-3m-2024-01-01-english
// Added to assets folder
// Name added in `assets` in ../pubspec.yaml

// Available models constant array
const sherpaModelNames = [
  'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01',
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
    default:
      throw ArgumentError('Unsupported model: $modelName');
  }
}

// Get devivce path for keywords.txt file for a given model
Future<String> getKeywordsFilePath(String modelName) async {
  switch (modelName) {
    case 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01':
      final modelDir =
          'assets/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';
      return await copyAssetFile('$modelDir/keywords.txt');
    default:
      throw ArgumentError('Unsupported model: $modelName');
  }
}
