import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutterimage/stores/models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LibraryStore with ChangeNotifier {
//DATA
  List<Comic> comics = [];
  List<String> tags = [];

  //STATE
  List<String> selectedTags = [];
  List<Comic> selectedComics = [];

  bool favoritesOnly = false;

  //VIEWSTATE
  bool isInitialized = false;
  bool showGrid = true;
  bool showSelection = false;

  List<Comic> get filteredComics {
    Iterable<Comic> result = comics;

    if (selectedTags.isNotEmpty) {
      result = result
          .where((c) => c.value!.tags!.any((t) => selectedTags.contains(t)));
    }

    if (favoritesOnly) {
      result = result.where((c) => c.value!.favorite ?? false);
    }

    return result.toList();
  }

  LibraryStore() {
    initStore();
  }

  void initStore() {
    loadComics().then((_) => isInitialized = true);
    loadTags();
  }

  Future loadComics() {
    Future result = Future(() async {
      http.Response? resp;
      do {
        try {
          resp = await http.get(Uri.parse(ComicServer.viewURL("comics")));
        } catch (e) {}
      } while (resp == null || resp.statusCode != 200);

      final rows = json.decode(resp.body)["rows"];

      comics.clear();
      for (var n in rows) {
        comics.add(Comic.fromJson(n));
      }
    });

    return result;
  }

  void deleteComic(Comic comic, {bool shouldNotify = true}) async {
    try {
      var resp = await http.head(Uri.parse(ComicServer.comicURL(comic.id!)));
      var rev = json.decode(resp.body)["_rev"];

      resp = await http
          .delete(Uri.parse("${ComicServer.comicURL(comic.id!)}?rev=$rev"));

      comics.remove(comic);
    } catch (e) {
      print(e);
    }

    if (shouldNotify) notifyListeners();
  }

  void deleteComics(List<Comic> comics, {bool shouldNotify = true}) async {
    await Future.forEach(
        comics, (Comic comic) => deleteComic(comic, shouldNotify: false));

    if (shouldNotify) notifyListeners();
  }

  void toggleLibraryView() {
    showGrid = !showGrid;

    notifyListeners();
  }

  void toggleSelectionView() {
    showSelection = !showSelection;

    if (!showSelection) selectedComics.clear();

    notifyListeners();
  }

  void toggleComicSelected(Comic comic, {bool shouldNotify = true}) {
    if (selectedComics.contains(comic)) {
      selectedComics.remove(comic);
    } else {
      selectedComics.add(comic);
    }

    if (shouldNotify) notifyListeners();
  }

  void deleteSelectedComics({bool shouldNotify = true}) {
    deleteComics(selectedComics, shouldNotify: false);
    if (shouldNotify) notifyListeners();
  }

  void loadTags({bool shouldNotify = true}) async {
    http.Response? resp;
    resp = await http.get(Uri.parse(ComicServer.viewURL("allTags")));

    final allTags = json.decode(resp.body)["rows"][0]["value"];

    tags.clear();
    for (var tag in allTags) {
      tags.add(tag);
    }

    tags.sort((a, b) => a.compareTo(b));

    if (shouldNotify) notifyListeners();
  }

  void toggleFavoriteOnly() {
    favoritesOnly = !favoritesOnly;

    notifyListeners();
  }

  void toggleTagSelected(String tag, {bool shouldNotify = true}) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }

    if (shouldNotify) notifyListeners();
  }

  void clearTags({bool shouldNotify = true}) {
    selectedTags.clear();
    if (shouldNotify) notifyListeners();
  }
}
