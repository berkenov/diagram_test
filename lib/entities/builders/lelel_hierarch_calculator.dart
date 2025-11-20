import '../connection.dart';
import '../subscriber_node.dart';

class LevelHierarchyCalculator {
  static List<List<String>> calculateHierarchy({
    required List<SubscriberNode> nodes,
    required List<Connection> connections,
  }) {
    if (nodes.isEmpty) return [];

    // 1. Фильтруем связи внутри уровня
    final levelNodeIds = nodes.map((n) => n.id).toSet();
    final internalConnections = connections
        .where((c) =>
            levelNodeIds.contains(c.fromSubscriberId) &&
            levelNodeIds.contains(c.toSubscriberId))
        .toList();

    // 2. Строим граф вызовов
    final graph = _buildCallGraph(levelNodeIds, internalConnections);

    // 3. Находим изолированные ноды (без связей)
    final isolatedNodes = _findIsolatedNodes(levelNodeIds, graph);

    // 4. Группируем в подслои с топологической сортировкой
    final List<List<String>> tiers = _calculateTiers(graph, levelNodeIds);

    // 5. Комбинируем изолированные ноды и иерархические слои
    return _combineHierarchy(isolatedNodes, tiers);
  }

  /// Строит ориентированный граф вызовов
  static Map<String, Set<String>> _buildCallGraph(
      Set<String> nodeIds, List<Connection> connections) {
    final graph = <String, Set<String>>{};

    // Инициализируем все ноды
    for (final nodeId in nodeIds) {
      graph[nodeId] = <String>{};
    }

    // Добавляем рёбра: subscriberA -> subscriberB (A вызывает B)
    for (final connection in connections) {
      graph[connection.fromSubscriberId]!.add(connection.toSubscriberId);
    }

    return graph;
  }

  /// Находит ноды без входящих и исходящих связей
  static List<String> _findIsolatedNodes(
      Set<String> nodeIds, Map<String, Set<String>> graph) {
    final isolatedNodes = <String>[];
    final hasIncomingConnections = <String, bool>{};

    // Помечаем ноды, у которых есть входящие связи
    for (final nodeId in nodeIds) {
      hasIncomingConnections[nodeId] = false;
    }

    for (final entry in graph.entries) {
      for (final target in entry.value) {
        hasIncomingConnections[target] = true;
      }
    }

    // Изолированные ноды - те, у которых нет входящих и исходящих связей
    for (final nodeId in nodeIds) {
      final hasOutgoing = graph[nodeId]!.isNotEmpty;
      final hasIncoming = hasIncomingConnections[nodeId]!;

      if (!hasOutgoing && !hasIncoming) {
        isolatedNodes.add(nodeId);
      }
    }

    return isolatedNodes;
  }

  /// Вычисляет иерархические слои с помощью топологической сортировки
  static List<List<String>> _calculateTiers(
      Map<String, Set<String>> graph, Set<String> nodeIds) {
    if (nodeIds.isEmpty) return [];

    // Копируем граф для модификации
    final workingGraph = <String, Set<String>>{};
    for (final entry in graph.entries) {
      workingGraph[entry.key] = Set<String>.from(entry.value);
    }

    final tiers = <List<String>>[];
    final processedNodes = <String>{};

    while (processedNodes.length < nodeIds.length) {
      // Находим ноды без входящих рёбер на текущей итерации
      final currentTier = <String>[];
      final hasIncoming = <String, bool>{};

      // Инициализируем все ноды как не имеющие входящих связей
      for (final nodeId in nodeIds) {
        if (!processedNodes.contains(nodeId)) {
          hasIncoming[nodeId] = false;
        }
      }

      // Помечаем ноды, у которых есть входящие связи от непроцессированных нод
      for (final entry in workingGraph.entries) {
        if (processedNodes.contains(entry.key)) continue;

        for (final target in entry.value) {
          if (!processedNodes.contains(target)) {
            hasIncoming[target] = true;
          }
        }
      }

      // Добавляем в текущий слой ноды без входящих связей
      for (final nodeId in nodeIds) {
        if (!processedNodes.contains(nodeId) &&
            !(hasIncoming[nodeId] ?? false)) {
          currentTier.add(nodeId);
          processedNodes.add(nodeId);
        }
      }

      if (currentTier.isEmpty) {
        // Обнаружен цикл - добавляем оставшиеся ноды в один слой
        final remainingNodes = nodeIds.difference(processedNodes).toList();
        if (remainingNodes.isNotEmpty) {
          tiers.add(remainingNodes);
          processedNodes.addAll(remainingNodes);
        }
        break;
      }

      tiers.add(currentTier);

      // Удаляем обработанные ноды из графа
      for (final nodeId in currentTier) {
        workingGraph.remove(nodeId);
      }

      // Удаляем рёбра, ведущие к обработанным нодам
      for (final entry in workingGraph.entries) {
        entry.value.removeAll(processedNodes);
      }
    }

    return tiers;
  }

  /// Комбинирует изолированные ноды и иерархические слои
  static List<List<String>> _combineHierarchy(
      List<String> isolatedNodes, List<List<String>> tiers) {
    final hierarchy = <List<String>>[];

    // Изолированные ноды идут в первый подслой
    if (isolatedNodes.isNotEmpty) {
      hierarchy.add(isolatedNodes);
    }

    // Затем добавляем иерархические слои
    hierarchy.addAll(tiers);

    return hierarchy;
  }

  /// Вспомогательный метод для отладки
  static void printHierarchy(List<List<String>> hierarchy) {
    print('=== LEVEL HIERARCHY ===');
    for (int i = 0; i < hierarchy.length; i++) {
      print('Sublayer $i: ${hierarchy[i]}');
    }
    print('=======================');
  }
}
