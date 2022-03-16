import 'package:flutter/material.dart';
import 'package:flutterimage/stores/imageStore.dart';
import 'package:flutterimage/stores/libraryStore.dart';
import 'package:flutterimage/widgets/imageviewer.dart';
import 'package:flutterimage/widgets/libraryviewer.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryStore()),
        ChangeNotifierProvider(create: (_) => ImageStore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: "/libraryviewer",
        routes: {
          "/libraryviewer": (context) =>
              (context.watch<LibraryStore>().isInitialized)
                  ? LibraryViewer()
                  : const Center(child: CircularProgressIndicator()),
          "/imageviewer": (context) =>
              (context.watch<ImageStore>().isInitialized)
                  ? ImageViewer()
                  : const Center(child: CircularProgressIndicator())
        });
  }
}
