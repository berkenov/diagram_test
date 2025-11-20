class SubscriberNode {
  final String id;
  final String name;
  final int level;

  const SubscriberNode({
    required this.id,
    required this.name,
    required this.level,
  });

  SubscriberNode copyWith({
    String? id,
    String? name,
    int? level,
  }) {
    return SubscriberNode(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }
}