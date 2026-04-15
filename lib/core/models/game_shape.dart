import 'package:flutter/material.dart';
import 'package:shape_merge/core/constants/shape_types.dart';

class GameShape {
  final String id;
  final double x;
  final double y;
  final ShapeType type;
  final Color color;
  final int level;
  final bool isWildcard;

  GameShape({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.color,
    required this.level,
    this.isWildcard = false,
  });

  int get value => 1 << level;

  bool canMergeWith(GameShape other) {
    if (level != other.level) return false;
    if (isWildcard || other.isWildcard) return true;
    return type == other.type && color == other.color;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'type': type.index,
        'color': color.toARGB32(),
        'level': level,
        'isWildcard': isWildcard,
      };

  factory GameShape.fromJson(Map<String, Object?> json) => GameShape(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        type: ShapeType.values[json['type'] as int],
        color: Color(json['color'] as int),
        level: json['level'] as int,
        isWildcard: json['isWildcard'] as bool? ?? false,
      );

  GameShape copyWith({
    String? id,
    double? x,
    double? y,
    ShapeType? type,
    Color? color,
    int? level,
    bool? isWildcard,
  }) {
    return GameShape(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      color: color ?? this.color,
      level: level ?? this.level,
      isWildcard: isWildcard ?? this.isWildcard,
    );
  }
}
