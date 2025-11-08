#!/bin/bash
set -e

ASSETS_DIR="assets"

declare -A MODELS
MODELS["sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01"]="https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2"
MODELS["sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20"]="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20.tar.bz2"

echo "🔧 Setting up assets..."

for model in "${!MODELS[@]}"; do
  url="${MODELS[$model]}"
  dir="$ASSETS_DIR/$model"
  archive="$ASSETS_DIR/$model.tar.bz2"

  mkdir -p "$ASSETS_DIR"

  # If the model directory does not exist, download and extract it then remove the archive
  if [ ! -d "$dir" ]; then
    echo "⬇️  Downloading $model..."
    wget -q "$url" -O "$archive"

    echo "📂 Extracting $model..."
    tar -xjf "$archive" -C "$ASSETS_DIR"
    rm "$archive"
  else
    echo "✅ $model already exists."
  fi

  # Copy keywords.txt and keywords_raw.txt files and overwrite if they exist in the model directory
  if [ -f "$ASSETS_DIR/$model.keywords.txt" ]; then
    echo "📝 Updating keywords.txt for $model..."
    cp "$ASSETS_DIR/$model.keywords.txt" "$dir/keywords.txt"
  fi
  if [ -f "$ASSETS_DIR/$model.keywords_raw.txt" ]; then
    echo "📝 Updating keywords_raw.txt for $model..."
    cp "$ASSETS_DIR/$model.keywords_raw.txt" "$dir/keywords_raw.txt"
  fi
done

echo "✅ All assets ready."
