import 'package:flutter/material.dart';

import 'entities/builders/i_level_builder.dart';
import 'entities/subscriber_node.dart';

class DraggableNode extends StatefulWidget {
  const DraggableNode({
    required this.node,
    required this.initialOffset,
    required this.onChangedPosition,
    super.key,
  });

  final SubscriberNode node;
  final Offset initialOffset;
  final Future<Offset> Function(SubscriberNode, Offset) onChangedPosition;

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  SubscriberNode get node => widget.node;
  late Offset _position;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;
  }

  @override
  void didUpdateWidget(covariant DraggableNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOffset != oldWidget.initialOffset && !_isDragging) {
      _position = widget.initialOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Offset topLeft = _position;

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: kNodeWidth,
      height: kNodeHeight,
      child: GestureDetector(
        onPanStart: (_) {
          _isDragging = true;
          setState(() {});
        },
        onPanEnd: (DragEndDetails details) async {
          final Offset newPosition =
              await widget.onChangedPosition(node, _position);
          _position = newPosition;
          _isDragging = false;
          setState(() {});
        },
        onPanUpdate: (DragUpdateDetails details) {
          _position += details.delta;
          setState(() {});
        },
        child: Opacity(
          opacity: _isDragging ? 0.5 : 1,
          child: Container(
            color: Colors.grey,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 10,
                      ),
                      Text(
                        node.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
