import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutterimage/stores/models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageStore with ChangeNotifier {
  //DATA
  List<Comic> comics = [];

  //STATE
  int currentComicIndex = 0;
  int currentImageIndex = 0;

  //VIEWSTATE
  bool isInitialized = false;
  bool autoRun = false;

  //COMPUTED
  Comic get currentComic => comics[currentComicIndex];
  String get currentImage => currentComic.value!.pageList![currentImageIndex];
  String get imageURL => ComicServer.imageURL(currentComic.id!, currentImage);
  int get pageCount => currentComic.value?.pageList?.length ?? 0;
  int get currentPage => currentImageIndex + 1;

  void initStore(List<Comic> newComics, {int startingIndex = 0}) {
    isInitialized = false;

    comics = newComics;
    selectComicByIndex(startingIndex, shouldNotify: false);
    cancelAutorun(shouldNotify: false);

    isInitialized = true;

    notifyListeners();
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
    }

    if (shouldNotify) notifyListeners();
  }

  void prevImage({bool shouldNotify = true}) {
    if (--currentImageIndex < 0) {
      prevComic(shouldNotify: false);
      lastImage(shouldNotify: false);
    }

    if (shouldNotify) notifyListeners();
  }

  void firstImage({bool shouldNotify = true}) {
    currentImageIndex = 0;

    if (shouldNotify) notifyListeners();
  }

  void lastImage({bool shouldNotify = true}) {
    currentImageIndex = currentComic.value!.pages! - 1;

    if (shouldNotify) notifyListeners();
  }

  void nextComic({bool shouldNotify = true}) {
    if (++currentComicIndex > comics.length - 1) currentComicIndex--;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void prevComic({bool shouldNotify = true}) {
    if (--currentComicIndex < 0) currentComicIndex = 0;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void firstComic({bool shouldNotify = true}) {
    currentComicIndex = 0;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void lastComic({bool shouldNotify = true}) {
    currentComicIndex = comics.length - 1;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void selectComicByIndex(int index, {bool shouldNotify = true}) {
    currentComicIndex = index;

    firstImage(shouldNotify: false);

    if (shouldNotify) notifyListeners();
  }

  void toggleFavoriteComic(Comic comic, {bool shouldNotify = true}) async {
    try {
      var resp = await http.get(Uri.parse(ComicServer.comicURL(comic.id!)));
      var doc = json.decode(resp.body);

      bool fav = doc["favorite"] ?? false;

      doc["favorite"] = !fav;

      resp = await http.put(Uri.parse(ComicServer.comicURL(comic.id!)),
          body: json.encode(doc));

      comics.firstWhere((c) => c.id == doc["_id"]).value!.favorite = !fav;
    } catch (e) {
      print(e);
    }

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
