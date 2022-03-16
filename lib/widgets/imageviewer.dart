import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterimage/stores/imageStore.dart';
import 'package:flutterimage/stores/models.dart';
import 'package:provider/provider.dart';

class ImageViewer extends StatelessWidget {
  //distance after which the gesture turns from a small flick to a full drag
  // TODO: onResize!
  static const int flickThreshold = 400;

  static const String heroTag = "ImageViewer-hero-tag";

  late Map arguments;

  ImageViewer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageStore imgStore = Provider.of<ImageStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("${context.watch<ImageStore>().currentComic.key}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                imgStore.toggleFavoriteComic(imgStore.currentComic),
            icon: (imgStore.currentComic.isFavorite())
                ? const Icon(Icons.star_border)
                : const Icon(Icons.star),
          ),
          Builder(
              builder: (drawerContext) => IconButton(
                  onPressed: () => Scaffold.of(drawerContext).openEndDrawer(),
                  icon: const Icon(Icons.menu))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => imgStore.toggleAutorun(),
        child: Icon((context.watch<ImageStore>().autoRun)
            ? Icons.pause
            : Icons.android),
      ),
      endDrawer: const InfoDrawer(),
      body: GestureDetector(
        onHorizontalDragStart: (details) => onDragStart(details, context),
        onHorizontalDragUpdate: (details) => onDragUpdate(details, context),
        onHorizontalDragEnd: (details) => onDragEnd(details, context),
        child: Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text("${imgStore.currentPage} / ${imgStore.pageCount}"),
            ),
            Center(
              child: Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                    imageUrl: context.watch<ImageStore>().imageURL,
                    imageBuilder: (context2, img) => Container(
                        padding: const EdgeInsets.all(5),
                        height: MediaQuery.of(context2).size.height,
                        child: Image(image: img)),
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) {
                      return Text("$error");
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onDragStart(DragStartDetails details, BuildContext context) =>
      Provider.of<ImageStore>(context, listen: false).resetGestureDelta();

  void onDragUpdate(DragUpdateDetails details, BuildContext context) =>
      Provider.of<ImageStore>(context, listen: false)
          .updateGestureDelta(details.delta.dx);

  void onDragEnd(DragEndDetails details, BuildContext context) {
    var delta =
        Provider.of<ImageStore>(context, listen: false).getGestureDelta();
    int isNextB = ((delta > 0) ? 1 : 0) << 1;
    int isFlickB = delta.abs() < flickThreshold ? 1 : 0;

    ComicDirection direction = ComicDirection.values[isNextB + isFlickB];

    context.read<ImageStore>().changeImage(direction);
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
                context.watch<ImageStore>().currentComic.value!.tags!.length,
            itemBuilder: (itemContext, index) {
              var tag =
                  context.watch<ImageStore>().currentComic.value!.tags![index];
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
