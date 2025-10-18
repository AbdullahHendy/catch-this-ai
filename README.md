# catch_this_ai

Tired of hearing about 'AI' every two seconds? See how many times you've survived the AI overload!


# Progress 
* **DONE**
    * Logic for audio processing using `recorder`
    * KeywordSpotting using `sherpa onnx`
    * Simple UI
    * Runs in the background (as long as app is open in the background)
    * Detects keywords in this [`keywords.txt` file](./assets/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01/keywords.txt)
    * Spotted keywords are just published in a {String keyword, DateTime timestamp}

* **TODO**
    * No database (should save at least timestamps) for persistency in a small data base (maybe Hive?) for stats analysis
    * UI/UX needs improvement
    * Look into offloading, everythign is currently in main thread
    * Add option to stop, other settings (Settings Page)
    * See TODOs in files
    * Decide if wanna continue with `KeywordSpotter` or full `Online ASR` model
    * Cannot run in linux because of `recorder`, see `pubspec.yaml`
    