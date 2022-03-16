abstract class ComicServer {
  static String baseURL = "http://server.fritz.box:5984/comics";

  static String comicURL(String id) => "$baseURL/$id";

  static String imageURL(String id, String attachment) =>
      "${comicURL(id)}/$attachment";

  static String viewURL(String view) => "$baseURL/_design/overview/_view/$view";
}

class Comic {
  String? id;
  String? key;
  ComicDetails? value;

  Comic(this.id, this.key, this.value);

  factory Comic.fromJson(dynamic json) {
    return Comic(json["id"], json["key"], ComicDetails.fromJson(json["value"]));
  }

  bool isFavorite() => value?.favorite ?? false;
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
