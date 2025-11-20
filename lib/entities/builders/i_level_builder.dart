import 'package:flutter/material.dart';

import '../connection.dart';
import '../subscriber_node.dart';
import 'level_builder_result.dart';

abstract interface class ILevelBuilder {
  void initialize({
    required int level,
    required List<SubscriberNode> nodes,
    required List<Connection> connections,
    required Map<String, double> savedPositions,
  });

  /// Построение уровня
  LevelBuildResult build(double top);

  /// Добавление ноды
  LevelBuildResult addNode(SubscriberNode node, double dX);

  /// Обновление позиции ноды
  LevelBuildResult updateNodePosition(String nodeId, double dx);

  /// Удаление ноды
  LevelBuildResult removeNode(String nodeId);

  /// Получение высоты уровня
  double getHeight();

  /// При изменени верхних левелов, пересчитывать позиции по вертикали
  LevelBuildResult changePositionByY(double delta);

  LevelBuildResult getLastResult();
}

/// --- Layout constants controlling node geometry ---
const double kNodeWidth = 70;
const double kNodeHeight = 50;
const double kHGap = 10;
const double kVGap = 20;
const int kDefaultLevelsCount = 9;
const Offset kPositionCef = Offset(kNodeWidth / 2, kNodeHeight / 2);

class LevelBuilderImpl implements ILevelBuilder {
  int get level => _level;
  late int _level = 0;

  List<SubscriberNode> get nodes => _nodes;
  List<SubscriberNode> _nodes = [];

  List<Connection> _connections = [];

  Map<String, double> _savedPositions = {};
  double _lastOffsetX = 0;
  double? _lastBuildWidth;

  LevelBuildResult? _lastResult;

  @override
  void initialize({
    required int level,
    required List<SubscriberNode> nodes,
    required List<Connection> connections,
    required Map<String, double> savedPositions,
  }) {
    _level = level;
    _nodes = List.from(nodes);
    _nodes.removeWhere((item) => item.level != level);
    _connections = connections;
    _savedPositions = Map.from(savedPositions);
  }

  @override
  LevelBuildResult getLastResult() {
    final lastResult = _lastResult;
    return lastResult ?? build(0);
  }

  List<List<String>> getHierarchy() {
    final idsInLevel = _nodes.map((e) => e.id).toList();
    // Связи внутри уровня
    final List<Connection> edgesInsideLevel = _connections
        .where(
          (e) =>
              idsInLevel.contains(e.fromSubscriberId) &&
              idsInLevel.contains(e.toSubscriberId),
        )
        .toList();

    // Слои из узлов
    final List<List<String>> tiers =
        tierNodesInsideLevel(levelEdges: edgesInsideLevel);

    // Добавим изолированные узлы (не участвующие в Connection) в отдельный верхний подслой
    final Set<String> usedInTiers = <String>{
      for (final List<String> layer in tiers) ...layer,
    };
    final List<String> isolated =
        idsInLevel.where((String id) => !usedInTiers.contains(id)).toList();

    // иерархические слои
    final List<List<String>> hierarchy = <List<String>>[];
    if (isolated.isNotEmpty) {
      hierarchy.add(isolated);
    }
    hierarchy.addAll(tiers);
    return hierarchy;
  }

  @override
  double getHeight() {
    final lastResult = _lastResult;
    if (lastResult != null) {
      return lastResult.levelHeight;
    }

    final hierarchy = getHierarchy();
    final int sublayerCount = hierarchy.isEmpty ? 1 : hierarchy.length;

    final double levelHeight =
        kNodeHeight * sublayerCount + kVGap * (sublayerCount + 1);
    return levelHeight;
  }

  @override
  LevelBuildResult build(double top, [double? width]) {
    final hierarchy = getHierarchy();

    /// Посчитали подуровни
    final int sublayerCount = hierarchy.isEmpty ? 1 : hierarchy.length;
    final double levelHeight =
        kNodeHeight * sublayerCount + kVGap * (sublayerCount + 1);

    final Map<String, Offset> positions = <String, Offset>{};

    /// Определили началую точку отрисовки (начало левела + вертикальный утступ)
    final double levelTopY = top + kVGap;

    // Сначала строим позиции без центрирования
    for (int sublayerIndex = 0;
        sublayerIndex < hierarchy.length;
        sublayerIndex++) {
      final List<String> layerIds = hierarchy[sublayerIndex];
      final double positionY =
          levelTopY + sublayerIndex * (kNodeHeight + kVGap);

      for (int nodeIndex = 0; nodeIndex < layerIds.length; nodeIndex++) {
        final String nodeId = layerIds[nodeIndex];
        final double? savedPosition = _savedPositions[nodeId];
        final double positionX =
            savedPosition ?? kHGap + nodeIndex * (kNodeWidth + kHGap);
        _savedPositions[nodeId] = positionX;
        positions[nodeId] = Offset(positionX, positionY);
      }
    }

    // Если передан width - центрируем позиции
    final Map<String, Offset> finalPositions =
        width != null ? _centralizePositions(positions, width) : positions;

    final result = LevelBuildResult(
      level: level,
      levelHeight: levelHeight,
      nodePositions: finalPositions,
    );
    _lastResult = result;
    return result;
  }

  /// Центрирует позиции нод по горизонтали
  Map<String, Offset> _centralizePositions(
      Map<String, Offset> positions, double width) {
    if (positions.isEmpty) return positions;

    // Находим минимальный и максимальный X
    double minX = double.infinity;
    double maxX = double.negativeInfinity;

    for (final pos in positions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dx > maxX) maxX = pos.dx;
    }

    // Вычисляем ширину уровня и смещение для центрирования
    // Если ширина не изменилась, используем предыдущее смещение, чтобы избежать скачков
    if (width == _lastBuildWidth) {
      final double offsetX = _lastOffsetX;
      return {
        for (final entry in positions.entries)
          entry.key: Offset(entry.value.dx + offsetX, entry.value.dy),
      };
    }

    final double levelWidth = maxX - minX + kNodeWidth + kHGap;
    final double offsetX = (width - levelWidth) / 2 - minX;
    _lastOffsetX = offsetX;
    _lastBuildWidth = width;

    // Применяем смещение ко всем позициям
    return {
      for (final entry in positions.entries)
        entry.key: Offset(entry.value.dx + offsetX, entry.value.dy),
    };
  }

  @override
  LevelBuildResult addNode(SubscriberNode node, double dX) {
    if (!_nodes.any((n) => n.id == node.id)) {
      _nodes.add(node);
    }
    // Convert absolute X to relative X
    _savedPositions[node.id] = dX - _lastOffsetX;

    return build(0);
  }

  @override
  LevelBuildResult updateNodePosition(String nodeId, double dx) {
    // Convert absolute X to relative X
    _savedPositions[nodeId] = dx - _lastOffsetX;
    return build(0);
  }

  @override
  LevelBuildResult removeNode(String nodeId) {
    _nodes.removeWhere((node) => node.id == nodeId);
    _savedPositions.remove(nodeId);
    return build(0);
  }

  @override
  LevelBuildResult changePositionByY(double delta) {
    final lastResult = _lastResult;
    if (lastResult == null) {
      return build(0);
    }
    final Map<String, Offset> positions = lastResult.nodePositions;
    final Map<String, Offset> correctPositions = {};
    for (final entry in positions.entries) {
      correctPositions[entry.key] =
          Offset(entry.value.dx, entry.value.dy + delta);
    }
    final result = lastResult.copyWith(nodePositions: correctPositions);
    _lastResult = result;
    return result;
  }

  List<List<String>> tierNodesInsideLevel({
    required List<Connection> levelEdges,
  }) {
    // Collect all unique node IDs from edges (both sources and targets).
    final Set<String> ids = <String>{
      for (final Connection e in levelEdges) ...<String>[
        e.fromSubscriberId,
        e.toSubscriberId
      ],
    };

    // Build adjacency list and incoming degree (in-degree) map.
    // adj[a] = list of nodes that 'a' points to.
    // indeg[b] = number of edges coming into 'b'.
    final Map<String, List<String>> adj = <String, List<String>>{
      for (final String id in ids) id: <String>[],
    };
    final Map<String, int> indeg = <String, int>{
      for (final String id in ids) id: 0,
    };

    // Fill adjacency and in-degree maps using all edges.
    for (final Connection e in levelEdges) {
      adj
          .putIfAbsent(e.fromSubscriberId, () => <String>[])
          .add(e.toSubscriberId);
      indeg[e.toSubscriberId] = (indeg[e.toSubscriberId] ?? 0) + 1;
    }

    /// Calculates the total outgoing "activity" of a node,
    /// i.e., sum of all connection weights for its outgoing edges.
    int outWeight(String id) => levelEdges
        .where((e) => e.fromSubscriberId == id)
        .fold(0, (int sum, e) => sum + e.count);

    /// Comparison function for sorting nodes within a layer.
    ///
    /// - Nodes with higher outgoing weights come first.
    /// - If weights are equal, they are sorted lexicographically by ID (for consistency).
    int cmp(String a, String b) {
      final int wa = outWeight(a), wb = outWeight(b);
      if (wa != wb) {
        return wb.compareTo(wa); // descending by weight
      }
      return a.compareTo(b); // fallback stable sort
    }

    // The final result: list of tiers (each tier is a list of node IDs).
    final List<List<String>> tiers = <List<String>>[];

    // Set of nodes that are not yet assigned to any layer.
    final Set<String> remaining = <String>{...ids};

    // Main loop — builds layers iteratively.
    while (remaining.isNotEmpty) {
      // Current layer: all nodes with no incoming edges (indeg == 0)
      final List<String> layer = remaining
          .where((String id) => (indeg[id] ?? 0) == 0)
          .toList()
        ..sort(cmp); // sort by weight (descending)

      if (layer.isEmpty) {
        // If no nodes have indeg == 0, a cycle exists.
        // We must "break" the cycle to proceed.
        // Strategy: pick one of the most active nodes and move it into a separate pseudo-layer.
        final List<String> cycleBreak = remaining.toList()..sort(cmp);
        final String pick = cycleBreak.first;
        layer.add(pick);
      }

      // Add the current layer to the result.
      tiers.add(layer);

      // "Remove" processed nodes from the graph:
      // - Decrease indegrees of their neighbors.
      // - Remove nodes themselves from the remaining set.
      for (final String u in layer) {
        remaining.remove(u);
        for (final String v in adj[u] ?? const <String>[]) {
          indeg[v] = (indeg[v] ?? 0) - 1;
        }
        indeg.remove(u);
      }
    }

    return tiers;
  }
}
