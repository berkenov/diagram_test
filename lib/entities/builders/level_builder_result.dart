import 'package:flutter/material.dart';

class LevelBuildResult {
  LevelBuildResult({
    required this.level,
    required this.nodePositions,
    required this.levelHeight,
  });

  final int level;
  final Map<String, Offset> nodePositions;
  final double levelHeight;

  LevelBuildResult copyWith({
    int? level,
    Map<String, Offset>? nodePositions,
    double? levelHeight,
  }) {
    return LevelBuildResult(
      level: level ?? this.level,
      nodePositions: nodePositions ?? this.nodePositions,
      levelHeight: levelHeight ?? this.levelHeight,
    );
  }
}
