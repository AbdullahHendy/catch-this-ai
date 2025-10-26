# catch_this_ai

Tired of hearing about 'AI' every two seconds? See how many times you've survived the AI overload!

# Current behavior
* On start, app will listen for [keywords](./assets/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01/keywords.txt) and show a `persistent/sticky` notification indicating so.
* Main page shows daily stats only.
* `persistent/sticky` notification has buttons for control including `start`, `stop`, and `exit`. 
* When app is removed from recent apps stack `"swiped up"`, the whole app shut and no more recording is happening.
* App doesn't start on device start up, but if open, will survive app `update/reinstalls`.

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
    * Included Stats Page

* **TODO**
    * Verify if the [current behavior](#current-behavior) is the desired one
    * UI/UX needs improvement
    * Missing Settings page
    * Look into offloading, everythign is currently in main thread
    * Add option to stop, other settings (Settings Page)
    * See TODOs in files
    * Decide if wanna continue with `KeywordSpotter` or full `Online ASR` model
    * Cannot run in linux because of `recorder`, see `pubspec.yaml`
