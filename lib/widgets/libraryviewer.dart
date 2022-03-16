import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterimage/stores/imageStore.dart';
import 'package:flutterimage/stores/libraryStore.dart';
import 'package:flutterimage/stores/models.dart';
import 'package:flutterimage/widgets/imageviewer.dart';
import 'package:provider/provider.dart';

class LibraryViewer extends StatelessWidget {
  LibraryViewer({Key? key}) : super(key: key);
  final ScrollController ctrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    LibraryStore provider = Provider.of<LibraryStore>(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text("Library"),
          actions: [
            if (context.watch<LibraryStore>().showSelection)
              IconButton(
                onPressed: () => provider.deleteSelectedComics(),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            IconButton(
              onPressed: () => provider.initStore(),
              icon: const Icon(Icons.replay_rounded),
            ),
            IconButton(
              onPressed: () => provider.toggleFavoriteOnly(),
              icon: (context.watch<LibraryStore>().favoritesOnly)
                  ? const Icon(Icons.star_border)
                  : const Icon(Icons.star),
            ),
          ],
        ),
        drawer: TagDrawer(provider: provider, ctrl: ctrl),
        body: LibraryViewerGrid(
          ctrl: ctrl,
        ));
  }
}

class TagDrawer extends StatelessWidget {
  const TagDrawer({
    Key? key,
    required this.provider,
    required this.ctrl,
  }) : super(key: key);

  final LibraryStore provider;
  final ScrollController ctrl;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50),
            child: Row(
              children: [
                Expanded(
                    child: Text("Tags",
                        style: Theme.of(context).textTheme.headline4)),
                IconButton(
                  onPressed: () => provider.clearTags(),
                  icon: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: context.watch<LibraryStore>().selectedTags.length,
              itemBuilder: ((context, index) {
                String tag = context.watch<LibraryStore>().selectedTags[index];

                return ListTile(
                  title: Text(tag),
                  leading: const Icon(Icons.check),
                  onTap: () async {
                    await ctrl.animateTo(0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linear);
                    provider.toggleTagSelected(tag);
                  },
                );
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: context.watch<LibraryStore>().tags.length,
              itemBuilder: ((context, index) {
                String tag = context.watch<LibraryStore>().tags[index];

                return ListTile(
                  title: Text(tag),
                  leading:
                      (context.watch<LibraryStore>().selectedTags.contains(tag))
                          ? const Icon(Icons.check)
                          : null,
                  onTap: () async {
                    await ctrl.animateTo(0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linear);
                    provider.toggleTagSelected(tag);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryViewerGrid extends StatelessWidget {
  static const double maxCrossAxisExtent = 250;

  const LibraryViewerGrid({Key? key, required this.ctrl}) : super(key: key);

  final ScrollController ctrl;

  @override
  Widget build(BuildContext context) {
    LibraryStore provider = Provider.of<LibraryStore>(context);
    ImageStore imgStore = Provider.of<ImageStore>(context);

    return GridView.builder(
      controller: ctrl,
      reverse: true,
      scrollDirection: Axis.horizontal,
      itemCount: context.watch<LibraryStore>().filteredComics.length,
      itemBuilder: (itemContext, index) {
        var comic = context.watch<LibraryStore>().filteredComics[index];

        return GestureDetector(
          key: Key(comic.id!),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                      border: (context
                              .watch<LibraryStore>()
                              .selectedComics
                              .contains(comic))
                          ? Border.all(color: Colors.blue, width: 4)
                          : null),
                  child: Hero(
                    tag: ImageViewer.heroTag,
                    child: CachedNetworkImage(
                        imageUrl: ComicServer.imageURL(
                            comic.id!, comic.value!.pageList!.first),
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
              ),
              Container(
                padding: const EdgeInsets.all(6),
                child: Text(
                  comic.key!,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        backgroundColor: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          onTap: () async {
            if (provider.showSelection) {
              provider.toggleComicSelected(comic);
            } else {
              imgStore.initStore(provider.filteredComics, startingIndex: index);
              await Navigator.of(context).pushNamed("/imageviewer");
            }
          },
          onLongPress: () {
            provider.toggleComicSelected(comic);
            provider.toggleSelectionView();
          },
        );
      },
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent),
    );
  }
}
