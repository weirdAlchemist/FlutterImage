import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterimage/imageviewer.dart';
import 'package:flutterimage/libraryviewer.dart';
import 'package:flutterimage/store.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComicProvider()),
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
        initialRoute: "/",
        routes: {
          "/": (context) => (context.watch<ComicProvider>().isInitialized)
              ? LibraryViewer()
              : Center(child: CircularProgressIndicator()),
          "/imageviewer": (context) =>
              (context.watch<ComicProvider>().isInitialized)
                  ? ImageViewer()
                  : Center(child: CircularProgressIndicator())
        });
  }
}
