// Генератор мок данных
import 'package:flutter/material.dart';

import 'entities/connection.dart';
import 'entities/subscriber_node.dart';

class MockDataGenerator {
  static List<SubscriberNode> generateNodes() {
    return [
      // Level 1 - Высший уровень (источники вызовов)
      SubscriberNode(id: 'node_1_1', name: 'Главный сервер', level: 1),
      SubscriberNode(id: 'node_1_2', name: 'API Gateway', level: 1),
      SubscriberNode(id: 'node_1_3', name: 'Балансировщик', level: 1),

      // Level 2 - Промежуточный уровень
      SubscriberNode(id: 'node_2_1', name: 'Сервис А', level: 2),
      SubscriberNode(id: 'node_2_2', name: 'Сервис B', level: 2),
      SubscriberNode(id: 'node_2_3', name: 'Сервис C', level: 2),
      SubscriberNode(id: 'node_2_4', name: 'Кэш сервер', level: 2),

      // Level 3 - Сервисы данных
      SubscriberNode(id: 'node_3_1', name: 'База данных', level: 3),
      SubscriberNode(id: 'node_3_2', name: 'Redis', level: 3),
      SubscriberNode(id: 'node_3_3', name: 'Elasticsearch', level: 3),

      // Level 0 - Нижний уровень (внешние сервисы)
      SubscriberNode(id: 'node_0_1', name: 'Внешний API', level: 0),
      SubscriberNode(id: 'node_0_2', name: 'Почтовый сервер', level: 0),
      SubscriberNode(id: 'node_0_3', name: 'SMS шлюз', level: 0),

      // Дополнительные ноды для демонстрации иерархии
      SubscriberNode(id: 'node_4_1', name: 'Аналитика', level: 4),
      SubscriberNode(id: 'node_4_2', name: 'Логирование', level: 4),
    ];
  }

  static List<Connection> generateConnections() {
    return [
      // Связи внутри Level 1
      Connection(
          count: 2, fromSubscriberId: 'node_1_1', toSubscriberId: 'node_1_2'),
      Connection(
          count: 2, fromSubscriberId: 'node_1_1', toSubscriberId: 'node_1_3'),

      // Связи от Level 1 к Level 2
      Connection(
          count: 2, fromSubscriberId: 'node_1_2', toSubscriberId: 'node_2_1'),
      Connection(
          count: 2, fromSubscriberId: 'node_1_2', toSubscriberId: 'node_2_2'),
      Connection(
          count: 2, fromSubscriberId: 'node_1_3', toSubscriberId: 'node_2_3'),
      Connection(
          count: 2, fromSubscriberId: 'node_1_3', toSubscriberId: 'node_2_4'),

      // Связи внутри Level 2
      Connection(
          count: 2, fromSubscriberId: 'node_2_1', toSubscriberId: 'node_2_4'),
      Connection(
          count: 2, fromSubscriberId: 'node_2_2', toSubscriberId: 'node_2_4'),

      // Связи от Level 2 к Level 3
      Connection(
          count: 2, fromSubscriberId: 'node_2_1', toSubscriberId: 'node_3_1'),
      Connection(
          count: 2, fromSubscriberId: 'node_2_2', toSubscriberId: 'node_3_2'),
      Connection(
          count: 2, fromSubscriberId: 'node_2_3', toSubscriberId: 'node_3_3'),
      Connection(
          count: 2, fromSubscriberId: 'node_2_4', toSubscriberId: 'node_3_1'),

      // Связи от Level 3 к Level 0
      Connection(
          count: 2, fromSubscriberId: 'node_3_1', toSubscriberId: 'node_0_1'),
      Connection(
          count: 2, fromSubscriberId: 'node_3_2', toSubscriberId: 'node_0_2'),
      Connection(
          fromSubscriberId: 'node_3_3', toSubscriberId: 'node_0_3', count: 1),

      // Связи для Level 4
      Connection(
          count: 2, fromSubscriberId: 'node_2_1', toSubscriberId: 'node_4_1'),
      Connection(
          count: 2, fromSubscriberId: 'node_2_2', toSubscriberId: 'node_4_2'),
      Connection(
          count: 2, fromSubscriberId: 'node_4_1', toSubscriberId: 'node_4_2'),

      // Несколько циклических связей для теста
      Connection(
          count: 12, fromSubscriberId: 'node_2_3', toSubscriberId: 'node_2_1'),
      Connection(
          count: 12, fromSubscriberId: 'node_3_1', toSubscriberId: 'node_2_4'),
    ];
  }

  static Map<String, Offset> generateSavedPositions() {
    return {
      // Некоторые ноды с сохранёнными позициями
      'node_1_1': const Offset(100, 0),
      'node_1_2': const Offset(250, 0),
      'node_2_1': const Offset(150, 0),
      'node_3_1': const Offset(200, 0),
      'node_0_1': const Offset(180, 0),
    };
  }
}

// Альтернативные моки для разных сценариев

// Моки для тестирования крайних случаев
class EdgeCaseMocks {
  // Пустые данные
  static List<SubscriberNode> get emptyNodes => [];

  static List<Connection> get emptyConnections => [];

  static Map<String, Offset> get emptySavedPositions => {};

  // Один уровень с изолированными нодами
  static List<SubscriberNode> get isolatedNodes => [
        SubscriberNode(id: 'X', name: 'Изолированная 1', level: 1),
        SubscriberNode(id: 'Y', name: 'Изолированная 2', level: 1),
        SubscriberNode(id: 'Z', name: 'Изолированная 3', level: 1),
      ];

  static List<Connection> get noConnections => [];

  // Циклические зависимости
  static List<SubscriberNode> get cyclicNodes => [
        SubscriberNode(id: 'P', name: 'Node P', level: 1),
        SubscriberNode(id: 'Q', name: 'Node Q', level: 1),
        SubscriberNode(id: 'R', name: 'Node R', level: 1),
      ];

  static List<Connection> get cyclicConnections => [
        Connection(
          count: 2,
          fromSubscriberId: 'P',
          toSubscriberId: 'Q',
        ),
        Connection(
          count: 2,
          fromSubscriberId: 'Q',
          toSubscriberId: 'R',
        ),
        Connection(
          count: 2,
          fromSubscriberId: 'R',
          toSubscriberId: 'P',
        ),
        // Цикл
      ];
}
