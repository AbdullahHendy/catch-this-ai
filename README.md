# catch_this_ai

Tired of hearing about 'AI' every two seconds? See how many times you've survived the AI overload!


# Progress 
* **DONE**
    * Logic for audio processing using `recorder`
    * KeywordSpotting using `sherpa onnx`
    * Simple UI
    * Runs in the background (as long as app is open in the background)
    * Detects keywords in this [`keywords.txt` file](./assets/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01/keywords.txt)
    * Detected keywords are stored with their timestamps in a Hive binary database
    * Spotted keywords are published in a {String keyword, DateTime timestamp} and saved in the database
    * Home page keeps track of counts of keyword daily
    * Apps runns in the background

* **TODO**
    * FIX BUG: When app is "swiped-up" foreground service still runs but app doesn't "register/use" its output (update DB, etc..) and app MUST be force shut from OS Settings->Apps
    * UI/UX needs improvement
    * Missing Stats and Settings page
    * Look into offloading, everythign is currently in main thread
    * Add option to stop, other settings (Settings Page)
    * See TODOs in files
    * Decide if wanna continue with `KeywordSpotter` or full `Online ASR` model
    * Cannot run in linux because of `recorder`, see `pubspec.yaml`
