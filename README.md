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
    * **KeywordSpotting** (KWS) using `sherpa onnx`, **OnlineRecognizer** (ASR) option using `sherpa onnx`
    * Simple UI
    * Runs in the background (as long as app is open in the background)
    * Detects keywords in this `keywords.txt` file of [both models](./assets/)
    * Spotted "texts" are published as the [`TrackedText`](./lib/core/domain/tracked_text.dart) in the form {String text, List<String> keywords, DateTime timestamp} and saved in the [`Hive`](./lib/core/storage/db/db_manager.dart) database
    * In the case of [**KWS**](./lib/core/services/speech/asr/sherpa_asr_service.dart), `keywords` of **TrackedText** is a list with single element, the same as, `text`
    * Home page keeps track of counts of keyword daily
    * Apps runns in the background
    * Included Stats Page

* **TODO**
    * Verify if the [current behavior](#current-behavior) is the desired one
    * UI/UX needs improvement
    * Missing Settings page
    * Add option to select **ASR** or **KWS**, clear database, along with other settings (Settings Page)
    * See TODOs in files
    * Cannot run in linux because of `recorder`, see `pubspec.yaml`
