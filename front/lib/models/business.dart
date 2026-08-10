import 'package:flutter/material.dart';

enum BusinessType {
  manufacturing,
  resale;

  String get displayName {
    switch (this) {
      case BusinessType.manufacturing:
        return 'Manufacturing';
      case BusinessType.resale:
        return 'Resale';
    }
  }

  String get description {
    switch (this) {
      case BusinessType.manufacturing:
        return 'You prepare items from raw materials, like a restaurant';
      case BusinessType.resale:
        return 'You buy finished products and sell them as-is, like a shop';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessType.manufacturing:
        return Icons.restaurant;
      case BusinessType.resale:
        return Icons.shopping_bag;
    }
  }
}

class Business {
  final String id;
  final String name;
  final BusinessType businessType;
  final String type; // Legacy field (p&r, etc.)
  final String location;
  final String? description;
  final String? owner;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.businessType,
    required this.type,
    required this.location,
    this.description,
    this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['_id'] as String,
      name: json['name'] as String,
      businessType: _parseBusinessType(json['businessType'] as String?),
      type: json['type'] as String,
      location: json['location'] as String,
      description: json['description'] as String?,
      owner: json['owner'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static BusinessType _parseBusinessType(String? businessType) {
    switch (businessType) {
      case 'manufacturing':
        return BusinessType.manufacturing;
      case 'resale':
        return BusinessType.resale;
      default:
        // Fallback for legacy data
        return BusinessType.resale;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'businessType': businessType.name,
      'type': type,
      'location': location,
      if (description != null) 'description': description,
    };
  }

  Business copyWith({
    String? id,
    String? name,
    BusinessType? businessType,
    String? type,
    String? location,
    String? description,
    String? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
