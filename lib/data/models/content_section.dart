class ContentSection {
  final String type;
  final String? text;
  final List<String>? items;
  final String? imageSrc;
  final String? imageCaption;

  ContentSection({
    required this.type,
    this.text,
    this.items,
    this.imageSrc,
    this.imageCaption,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      type: json['type'] as String,
      text: json['text'] as String?,
      items: json['items'] != null
          ? List<String>.from(json['items'] as List)
          : null,
      imageSrc: json['imageSrc'] as String?,
      imageCaption: json['imageCaption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (text != null) 'text': text,
      if (items != null) 'items': items,
      if (imageSrc != null) 'imageSrc': imageSrc,
      if (imageCaption != null) 'imageCaption': imageCaption,
    };
  }
}
