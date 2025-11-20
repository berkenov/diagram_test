import 'package:flutter/material.dart';

import '../connection.dart';
import '../subscriber_node.dart';
import 'i_level_builder.dart';

class DiagramManager {
  DiagramManager({
    required List<SubscriberNode> nodes,
    required this.connections,
    required this.initialSavePosition,
    required this.width,
  })  : _nodes = nodes,
        initialNodes = nodes;

  final Map<int, LevelBuilderImpl> _levelBuilders = {};
  final List<Connection> connections;
  final List<SubscriberNode> initialNodes;
  final Map<String, double> initialSavePosition;
  double width;

  DiagramData? _lastResult;

  List<SubscriberNode> get nodes => _nodes;
  final List<SubscriberNode> _nodes;

  void initialize() {
    // Группируем ноды по уровням
    final nodesByLevel = <int, List<SubscriberNode>>{};
    for (final node in initialNodes) {
      nodesByLevel.putIfAbsent(node.level, () => []).add(node);
    }

    // Создаём билдеры для каждого уровня
    // Ensure levels 1-9 and 0 exist, plus any other levels present in nodes
    final Set<int> allLevels = {
      ...nodesByLevel.keys,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9
    };

    for (final level in allLevels) {
      final builder = LevelBuilderImpl();
      builder.initialize(
        level: level,
        nodes: nodesByLevel[level] ?? [],
        connections: connections,
        savedPositions: initialSavePosition, // или из кэша
      );
      _levelBuilders[level] = builder;
    }
  }

  double calculateContentWidth() {
    double maxWidth = 0;
    for (final builder in _levelBuilders.values) {
      final levelWidth = builder.getContentWidth();
      if (levelWidth > maxWidth) {
        maxWidth = levelWidth;
      }
    }
    // Add some extra padding (e.g. 2 nodes width as requested)
    return maxWidth + (kNodeWidth * 2);
  }

  void updateWidth(double newWidth) {
    width = newWidth;
  }

  DiagramData buildDiagram() {
    final allPositions = <String, Offset>{};
    final levelsHeight = <int, double>{};
    double currentY = kVGap;

    // Сортируем уровни: 1-9, затем 0
    final sortedLevels = _levelBuilders.keys.toList()
      ..sort((a, b) {
        if (a == 0) return 1;
        if (b == 0) return -1;
        return a.compareTo(b);
      });

    for (final level in sortedLevels) {
      final builder = _levelBuilders[level]!;
      final result = builder.build(currentY, width);

      allPositions.addAll(result.nodePositions);
      levelsHeight[level] = result.levelHeight;
      currentY += result.levelHeight;
    }

    final result = DiagramData(
      nodePositions: allPositions,
      levelsHeight: levelsHeight,
    );
    _lastResult = result;
    return result;
  }

  int getLevelByPosition(Offset position, Map<int, double> levelsHeight) {
    double currentY = kVGap; // Начальная позиция первого уровня

    // Сортируем уровни по порядку: 1, 2, 3, ..., 0
    final sortedLevels = levelsHeight.keys.toList()
      ..sort((a, b) {
        if (a == 0) return 1; // 0 в конец
        if (b == 0) return -1; // 0 в конец
        return a.compareTo(b); // остальные по возрастанию
      });

    for (final level in sortedLevels) {
      final levelHeight = levelsHeight[level] ?? 0;
      final levelBottom = currentY + levelHeight;

      // Проверяем, попадает ли позиция в текущий уровень
      if (position.dy >= currentY && position.dy <= levelBottom) {
        return level;
      }

      currentY = levelBottom; // Переходим к следующему уровню
    }

    // Если позиция ниже всех уровней - возвращаем последний уровень
    // Если выше - возвращаем первый уровень
    if (sortedLevels.isNotEmpty) {
      return position.dy < kVGap ? sortedLevels.first : sortedLevels.last;
    }

    return 0; // fallback
  }

  DiagramData move(String nodeId, Offset position) {
    final lastResult = _lastResult;
    if (lastResult == null) {
      return buildDiagram();
    }

    final Offset? oldPosition = lastResult.nodePositions[nodeId];
    if (oldPosition == null) {
      return lastResult;
    }

    final oldLevel = getLevelByPosition(oldPosition, lastResult.levelsHeight);
    final newLevel = getLevelByPosition(position, lastResult.levelsHeight);

    // Если уровень не изменился - только обновляем позицию
    if (oldLevel == newLevel) {
      final builder = _levelBuilders[oldLevel];
      if (builder != null) {
        builder.updateNodePosition(nodeId, position.dx);
        // We need to update the overall result with the new level result
        // Since only one level changed, we can just update that part or rebuild everything.
        // Rebuilding everything is safer to ensure consistency, but we can optimize if needed.
        // For now, let's rebuild to be safe and simple, as buildDiagram uses the updated builders.
        return buildDiagram();
      }
      return _updateNodePosition(nodeId, position, lastResult);
    }

    // Перемещаем между уровнями
    return _moveNodeBetweenLevels(nodeId, oldLevel, newLevel, position);
  }

  DiagramData _moveNodeBetweenLevels(
      String nodeId, int fromLevel, int toLevel, Offset position) {
    // 1. Находим ноду в общем списке
    final nodeIndex = _nodes.indexWhere((item) => item.id == nodeId);
    if (nodeIndex == -1) return _lastResult!;

    final node = _nodes[nodeIndex];

    // 2. Удаляем из старого уровня
    _levelBuilders[fromLevel]?.removeNode(nodeId);

    // 3. Обновляем уровень ноды в основном списке
    _nodes[nodeIndex] = node.copyWith(level: toLevel);

    // 4. Добавляем в новый уровень (создаем если нужно)
    if (!_levelBuilders.containsKey(toLevel)) {
      _levelBuilders[toLevel] = LevelBuilderImpl()
        ..initialize(
          level: toLevel,
          nodes: [],
          connections: connections,
          savedPositions: initialSavePosition,
        );
    }
    _levelBuilders[toLevel]!.addNode(_nodes[nodeIndex], position.dx);

    // 5. Перестраиваем всю диаграмму (можно оптимизировать)
    return buildDiagram();
  }

  DiagramData _updateNodePosition(
      String nodeId, Offset position, DiagramData lastResult) {
    final updatedPositions = Map<String, Offset>.from(lastResult.nodePositions);
    updatedPositions[nodeId] =
        Offset(position.dx, updatedPositions[nodeId]!.dy);

    return lastResult.copyWith(nodePositions: updatedPositions);
  }
}

class DiagramData {
  const DiagramData({
    required this.nodePositions,
    required this.levelsHeight,
  });

  final Map<String, Offset> nodePositions;
  final Map<int, double> levelsHeight;

  DiagramData copyWith({
    Map<String, Offset>? nodePositions,
    Map<int, double>? levelsHeight,
  }) {
    return DiagramData(
      nodePositions: nodePositions ?? this.nodePositions,
      levelsHeight: levelsHeight ?? this.levelsHeight,
    );
  }
}
