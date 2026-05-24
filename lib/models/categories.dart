// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String? name;
  final String? name_ar;
  final String? name_ur;

  String? nameLocalized({required String languageCode}) {
    if (languageCode == 'ar') {
      return name_ar;
    }
    if (languageCode == 'ur') {
      return name_ur ?? name_ar;
    }
    return name;
  }

  /// this is the non svg icon
  final String? icon;
  final String? svg;

  final bool? isActive;

  final String? id;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  CategoryModel({
    this.name,
    this.name_ar,
    this.name_ur,
    this.icon,
    this.svg,
    this.isActive,
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  CategoryModel copyWith({
    String? name,
    String? name_ar,
    String? name_ur,
    String? icon,
    String? svg,
    bool? isActive,
    String? id,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CategoryModel(
      name: name ?? this.name,
      name_ar: name_ar ?? this.name_ar,
      name_ur: name_ur ?? this.name_ur,
      icon: icon ?? this.icon,
      svg: svg ?? this.svg,
      isActive: isActive ?? this.isActive,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CategoryModel.fromQuerySnapshot(QueryDocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return CategoryModel(
      name: data['name'],
      name_ar: data['name_ar'],
      name_ur: data['name_ur'] ?? data['name_ar'] ?? data['name'],
      icon: data['icon'],
      svg: data['svg'],
      isActive: data['isActive'] ?? true,
      id: snapshot.id,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'],
      name_ar: json['name_ar'] ?? json['name'],
      name_ur: json['name_ur'] ?? json['name_ar'] ?? json['name'],
      icon: json['icon'],
      svg: json['svg'],
      isActive: json['isActive'] ?? true,
      id: json['id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'name_ar': name_ar,
      'name_ur': name_ur,
      'icon': icon,
      'svg': svg,
      'isActive': isActive ?? true,
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }

  @override
  String toString() {
    return 'CategoryModel{name: $name, name_ar: $name_ar, icon: $icon, svg: $svg, isActive: $isActive, id: $id, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  Map<String, dynamic> toEditJson({required CategoryModel previous}) {
    Map<String, dynamic> json = {};
    if (name != previous.name && name != null) {
      json['name'] = name;
    }
    if (name_ar != previous.name_ar && name_ar != null) {
      json['name_ar'] = name_ar;
    }
    if (name_ur != previous.name_ur && name_ur != null) {
      json['name_ur'] = name_ur;
    }
    if (icon != previous.icon && icon != null) {
      json['icon'] = icon;
    }
    if (svg != previous.svg && svg != null) {
      json['svg'] = svg;
    }
    if (isActive != previous.isActive) {
      json['isActive'] = isActive;
    }
    if (id != previous.id && id != null) {
      json['id'] = id;
    }
    if (createdAt != previous.createdAt && createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (updatedAt != previous.updatedAt && updatedAt != null) {
      json['updatedAt'] = updatedAt;
    }
    return json;
  }
}
