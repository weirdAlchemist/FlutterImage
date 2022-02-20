import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterimage/store.dart';
import 'package:provider/provider.dart';

class ImageViewer extends StatelessWidget {
  //double delta = 0;

  //distance after which the gesture turns from a small flick to a full drag
  static const int flickThreshold = 400;

  const ImageViewer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${context.watch<ComicProvider>().currentComic.key}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ComicProvider>().toggleAutorun(),
        child: Icon((context.watch<ComicProvider>().autoRun)
            ? Icons.pause
            : Icons.android),
      ),
      endDrawer: const InfoDrawer(),
      body: GestureDetector(
        onHorizontalDragStart: (details) => onDragStart(details, context),
        onHorizontalDragUpdate: (details) => onDragUpdate(details, context),
        onHorizontalDragEnd: (details) => onDragEnd(details, context),
        child: Center(
          child: CachedNetworkImage(
              imageUrl: context.watch<ComicProvider>().imageURL,
              imageBuilder: (context2, img) => Container(
                  padding: const EdgeInsets.all(5),
                  height: MediaQuery.of(context2).size.height,
                  child: Image(image: img)),
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) {
                return Text("$error");
              }),
        ),
      ),
    );
  }

  void onDragStart(DragStartDetails details, BuildContext context) =>
      Provider.of<ComicProvider>(context).resetGestureDelta();

  void onDragUpdate(DragUpdateDetails details, BuildContext context) =>
      Provider.of<ComicProvider>(context).updateGestureDelta(details.delta.dx);

  void onDragEnd(DragEndDetails details, BuildContext context) {
    var delta = Provider.of<ComicProvider>(context).getGestureDelta();
    int isNextB = ((delta > 0) ? 1 : 0) << 1;
    int isFlickB = delta.abs() < flickThreshold ? 1 : 0;

    ComicDirection direction = ComicDirection.values[isNextB + isFlickB];

    context.read<ComicProvider>().changeImage(direction);
  }
}

class InfoDrawer extends StatelessWidget {
  const InfoDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text("Tags"),
          const SizedBox.square(dimension: 50),
          ListView.builder(
            shrinkWrap: true,
            itemCount:
                context.watch<ComicProvider>().currentComic.value!.tags!.length,
            itemBuilder: (itemContext, index) {
              var tag = context
                  .watch<ComicProvider>()
                  .currentComic
                  .value!
                  .tags![index];
              return ListTile(
                title: Text(tag),
              );
            },
          ),
        ],
      ),
    );
  }
}
