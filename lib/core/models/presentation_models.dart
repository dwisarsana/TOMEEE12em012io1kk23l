
import 'dart:convert';

class Slide {
  String id;
  String title;
  String? body;

  Slide({
    required this.id,
    required this.title,
    this.body,
  });

  factory Slide.newSlide([String title = "New Slide"]) {
    return Slide(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: "",
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
  };

  factory Slide.fromJson(Map<String, dynamic> json) => Slide(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String?,
  );
}

class Presentation {
  String id;
  String title;
  List<Slide> slides;
  DateTime updatedAt;

  Presentation({
    required this.id,
    required this.title,
    required this.slides,
    required this.updatedAt,
  });

  int get slideCount => slides.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slides': slides.map((e) => e.toJson()).toList(),
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Presentation.fromJson(Map<String, dynamic> json) => Presentation(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    slides: ((json['slides'] as List?) ?? [])
        .map((e) => Slide.fromJson(e as Map<String, dynamic>))
        .toList(),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
  );

  String toRawJson() => jsonEncode(toJson());
  factory Presentation.fromRawJson(String s) =>
      Presentation.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class RecentPresentation {
  final String id;
  final String title;
  final int slideCount;
  final DateTime updatedAt;

  RecentPresentation({
    required this.id,
    required this.title,
    required this.slideCount,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slideCount': slideCount,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory RecentPresentation.fromJson(Map<String, dynamic> json) =>
      RecentPresentation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled',
        slideCount: (json['slideCount'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (json['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      );
}
