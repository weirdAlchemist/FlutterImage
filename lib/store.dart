import 'dart:async';

import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ComicProvider with ChangeNotifier {
  //DATA
  List<Comic> comics = [];
  List<String> tags = [];

  //STATE
  int currentComicIndex = 0;
  late Comic currentComic;
  int currentImageIndex = 0;
  late String currentImage;
  List<String> selectedTags = [];
  List<Comic> selectedComics = [];

  //VIEWSTATE
  bool isInitialized = false;
  bool showGrid = true;
  bool showSelection = false;
  bool autoRun = false;

  //COMPUTED
  String get imageURL =>
      "http://server.fritz.box:5984/comics/${currentComic.id}/$currentImage";

  List<Comic> get filteredComics => (selectedTags.isNotEmpty)
      ? comics
          .where((c) => c.value!.tags!.any((t) => selectedTags.contains(t)))
          .toList()
      : comics.toList();

  ComicProvider() {
    loadComics().then((_) => initState());
    loadTags();
  }

  Future loadComics() {
    Future result = Future(() async {
      http.Response? resp;
      do {
        try {
          resp = await http.get(Uri.parse(
              'http://server.fritz.box:5984/comics/_design/overview/_view/comics'));
        } catch (e) {}
      } while (resp == null || resp.statusCode != 200);

      final rows = json.decode(resp.body)["rows"];

      for (var n in rows) {
        comics.add(Comic.fromJson(n));
      }
    });

    return result;
  }

  void deleteComic(Comic comic, {bool shouldNotify = true}) async {
    try {
      var resp = await http
          .get(Uri.parse("http://server.fritz.box:5984/comics/${comic.id}"));
      var rev = json.decode(resp.body)["_rev"];

      resp = await http.delete(Uri.parse(
          "http://server.fritz.box:5984/comics/${comic.id}?rev=$rev"));

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

  void initState() {
    firstComic(shouldNotify: false);

    isInitialized = true;

    notifyListeners();
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
    resp = await http.get(Uri.parse(
        'http://server.fritz.box:5984/comics/_design/overview/_view/allTags'));

    final allTags = json.decode(resp.body)["rows"][0]["value"];

    tags = [];
    for (var tag in allTags) {
      tags.add(tag);
    }

    tags.sort((a, b) => a.compareTo(b));

    if (shouldNotify) notifyListeners();
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

  void changeImage(ComicDirection direction) {
    switch (direction) {
      case ComicDirection.previousComic:
        prevComic();
        break;
      case ComicDirection.previousImage:
        prevImage();
        break;
      case ComicDirection.nextImage:
        nextImage();
        break;
      case ComicDirection.nextComic:
        nextComic();
        break;
    }
  }

  void nextImage({bool shouldNotify = true}) {
    if (++currentImageIndex > currentComic.value!.pages! - 1) {
      nextComic(shouldNotify: false);
      firstImage(shouldNotify: false);
    } else {
      currentImage = currentComic.value!.pageList![currentImageIndex];
    }

    if (shouldNotify) notifyListeners();
  }

  void prevImage({bool shouldNotify = true}) {
    if (--currentImageIndex < 0) {
      prevComic(shouldNotify: false);
      lastImage(shouldNotify: false);
    } else {
      currentImage = currentComic.value!.pageList![currentImageIndex];
    }

    if (shouldNotify) notifyListeners();
  }

  void firstImage({bool shouldNotify = true}) {
    currentImageIndex = 0;
    currentImage = currentComic.value!.pageList!.first;

    if (shouldNotify) notifyListeners();
  }

  void lastImage({bool shouldNotify = true}) {
    currentImageIndex = currentComic.value!.pages! - 1;
    currentImage = currentComic.value!.pageList!.last;

    if (shouldNotify) notifyListeners();
  }

  void nextComic({bool shouldNotify = true}) {
    if (++currentComicIndex > filteredComics.length - 1) currentComicIndex--;

    currentComic = filteredComics[currentComicIndex];

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void prevComic({bool shouldNotify = true}) {
    if (--currentComicIndex < 0) currentComicIndex = 0;
    currentComic = filteredComics[currentComicIndex];

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void firstComic({bool shouldNotify = true}) {
    currentComicIndex = 0;
    currentComic = filteredComics.first;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void lastComic({bool shouldNotify = true}) {
    currentComicIndex = filteredComics.length - 1;
    currentComic = filteredComics.last;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void selectComicByIndex(int index, {bool shouldNotify = true}) {
    currentComicIndex = index;
    currentComic = filteredComics[index];

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  Timer? _timer;
  void toggleAutorun() {
    autoRun = !autoRun;

    if (autoRun) {
      startAutorun(shouldNotify: false);
    } else {
      cancelAutorun(shouldNotify: false);
    }

    notifyListeners();
  }

  void startAutorun({bool shouldNotify = true}) {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      nextImage();
    });

    if (shouldNotify) notifyListeners();
  }

  void cancelAutorun({bool shouldNotify = true}) {
    _timer?.cancel();

    if (shouldNotify) notifyListeners();
  }

  double _gestureDelta = 0;
  void resetGestureDelta() => _gestureDelta = 0;
  void updateGestureDelta(double dx) => _gestureDelta += dx;
  double getGestureDelta() => _gestureDelta;
}

class Comic {
  String? id;
  String? key;
  ComicDetails? value;

  Comic(this.id, this.key, this.value);

  factory Comic.fromJson(dynamic json) {
    return Comic(json["id"], json["key"], ComicDetails.fromJson(json["value"]));
  }
}

class ComicDetails {
  bool? favorite;
  int? pages;
  List<dynamic>? pageList;
  List<dynamic>? tags;
  int? timestamp;

  ComicDetails(
      this.favorite, this.pages, this.pageList, this.tags, this.timestamp);

  factory ComicDetails.fromJson(dynamic json) {
    return ComicDetails(json["favorite"], json["pages"], json["pageList"],
        json["tags"], json["timestamp"]);
  }
}

// [isNext] [isFlick] => Index
// 00 => 0
// 01 => 1
// 10 => 2
// 11 => 3
enum ComicDirection { previousComic, previousImage, nextComic, nextImage }
