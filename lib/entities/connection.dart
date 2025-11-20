class Connection {
  const Connection({
    required this.count,
    required this.fromSubscriberId,
    required this.toSubscriberId,
  });

  final int count;
  final String fromSubscriberId;
  final String toSubscriberId;
}
