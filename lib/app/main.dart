import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  // Ensure Flutter bindings are initialized since MyApp uses FutureBuilder and async operations
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
