import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterimage/store.dart';
import 'package:provider/provider.dart';

class LibraryViewer extends StatelessWidget {
  const LibraryViewer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ComicProvider provider = Provider.of<ComicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Library"),
        actions: [
          if (context.watch<ComicProvider>().showSelection)
            IconButton(
              onPressed: () => provider.deleteSelectedComics(),
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          IconButton(
            onPressed: () => provider.toggleLibraryView(),
            icon: (context.watch<ComicProvider>().showGrid)
                ? const Icon(Icons.list)
                : const Icon(Icons.grid_3x3),
          ),
        ],
      ),
      drawer: TagDrawer(provider: provider),
      body: (context.watch<ComicProvider>().showGrid)
          ? const LibraryViewerGrid()
          : const LibraryViewerList(),
    );
  }
}

class TagDrawer extends StatelessWidget {
  const TagDrawer({
    Key? key,
    required this.provider,
  }) : super(key: key);

  final ComicProvider provider;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 50),
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
              itemCount: context.watch<ComicProvider>().tags.length,
              itemBuilder: ((context, index) {
                String tag = context.watch<ComicProvider>().tags[index];

                return ListTile(
                  title: Text(tag),
                  leading: (context
                          .watch<ComicProvider>()
                          .selectedTags
                          .contains(tag))
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => provider.toggleTagSelected(tag),
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

  const LibraryViewerGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ComicProvider provider = Provider.of<ComicProvider>(context);

    return GridView.builder(
      itemCount: context.watch<ComicProvider>().filteredComics.length,
      itemBuilder: (itemContext, index) {
        var comic = context.watch<ComicProvider>().filteredComics[index];

        return GestureDetector(
          key: Key(comic.id!),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                      border: (context
                              .watch<ComicProvider>()
                              .selectedComics
                              .contains(comic))
                          ? Border.all(color: Colors.blue, width: 4)
                          : null),
                  child: CachedNetworkImage(
                      imageUrl:
                          "http://server.fritz.box:5984/comics/${comic.id}/${comic.value!.pageList!.first}",
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
              provider.selectComicByIndex(index);
              await Navigator.of(context).pushNamed("/imageviewer");
              provider.cancelAutorun();
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

class LibraryViewerList extends StatelessWidget {
  const LibraryViewerList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ComicProvider provider = Provider.of<ComicProvider>(context);
    return ListView.builder(
        itemCount: context.watch<ComicProvider>().filteredComics.length,
        itemBuilder: (itemContext, index) {
          var comic = context.watch<ComicProvider>().filteredComics[index];

          return ListTile(
              title: Text(comic.key!),
              leading: CachedNetworkImage(
                  imageUrl:
                      "http://server.fritz.box:5984/comics/${comic.id}/${comic.value!.pageList!.first}",
                  imageBuilder: (context2, img) => Container(
                      padding: const EdgeInsets.all(5),
                      height: MediaQuery.of(context2).size.height,
                      child: Image(image: img)),
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) {
                    return Text("$error");
                  }),
              onTap: () async {
                provider.selectComicByIndex(index);
                await Navigator.of(context).pushNamed("/imageviewer");
                provider.cancelAutorun();
              });
        });
  }
}
