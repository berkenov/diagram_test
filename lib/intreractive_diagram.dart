import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'draggable_node.dart';
import 'entities/builders/diagram_manager.dart';
import 'entities/connection.dart';
import 'entities/subscriber_node.dart';
import 'levels_painter.dart';
import 'connections_painter.dart';

class InteractiveDiagramWidget extends StatefulWidget {
  final List<SubscriberNode> nodes;
  final List<Connection> connections;
  final Map<String, double> savedPositions;
  final double width;
  final double height;

  const InteractiveDiagramWidget({
    super.key,
    required this.nodes,
    required this.connections,
    required this.savedPositions,
    required this.width,
    required this.height,
  });

  @override
  State<InteractiveDiagramWidget> createState() =>
      _InteractiveDiagramWidgetState();
}

class _InteractiveDiagramWidgetState extends State<InteractiveDiagramWidget> {
  late DiagramManager _diagramManager;
  DiagramData? _diagramData;

  // Переменные для зума и скролла
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  double _diagramWidth = 0;

  static const double _minScale = 0.3;
  static const double _maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    _initializeDiagramManager();
  }

  bool ready = false;

  Future<void> _initializeDiagramManager() async {
    _diagramManager = DiagramManager(
      connections: widget.connections,
      nodes: widget.nodes,
      initialSavePosition: widget.savedPositions,
      width: widget.width,
    );
    _diagramManager.initialize();

    // Calculate dynamic width
    final contentWidth = _diagramManager.calculateContentWidth();
    _diagramWidth = math.max(widget.width, contentWidth);
    _diagramManager.updateWidth(_diagramWidth);

    // Calculate initial scale to fit width
    if (_diagramWidth > widget.width) {
      _scale = (widget.width / _diagramWidth).clamp(_minScale, _maxScale);
      _updateTransformation();
    }

    await Future.delayed(Duration(seconds: 2));
    _diagramData = _diagramManager.buildDiagram();
    await Future.delayed(Duration(seconds: 2));
    ready = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return Center(child: CircularProgressIndicator());
    }

    debugPrint('wow ${_diagramData?.levelsHeight}');
    debugPrint('wow ${widget.nodes.length}');

    return Column(
      children: [
        _buildZoomControls(),
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              onInteractionUpdate: _onInteractionUpdate,
              child: Container(
                // Явно указываем размеры диаграммы
                width: _diagramWidth,
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(
                        _diagramWidth,
                        widget.height,
                      ),
                      painter: LevelsPainter(
                        levelsHeight: _diagramData?.levelsHeight ?? {},
                        viewportTransform: _transformationController.value,
                      ),
                    ),
                    CustomPaint(
                      size: Size(
                        _diagramWidth,
                        widget.height,
                      ),
                      painter: ConnectionsPainter(
                        connections: widget.connections,
                        nodePositions: _diagramData?.nodePositions ?? {},
                      ),
                    ),
                    ...widget.nodes.map((item) {
                      final position = _diagramData?.nodePositions[item.id];

                      return DraggableNode(
                        node: item,
                        initialOffset: position ?? Offset.zero,
                        onChangedPosition:
                            (SubscriberNode node, Offset position) async {
                          final a = _diagramManager.move(node.id, position);
                          setState(() {
                            _diagramData = a;
                          });
                          final newPosition =
                              _diagramData!.nodePositions[item.id];

                          return newPosition ?? position;
                        },
                      );

                      return Positioned(
                        top: position?.dy ?? 20,
                        left: position?.dx ?? 50,
                        child: Container(
                          child: Text(item.name),
                          color: Colors.red,
                        ),
                      );
                    }),
                    // Здесь позже добавятся ноды
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: 'Уменьшить',
          ),
          Text('${(_scale * 100).round()}%'),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: 'Увеличить',
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _resetView,
            tooltip: 'Сбросить вид',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitToScreen,
            tooltip: 'Вместить в экран',
          ),
        ],
      ),
    );
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    _scale = _transformationController.value.getMaxScaleOnAxis();
    setState(() {});
  }

  void _zoomIn() {
    _scale = (_scale + 0.1).clamp(_minScale, _maxScale);
    _updateTransformation();
  }

  void _zoomOut() {
    _scale = (_scale - 0.1).clamp(_minScale, _maxScale);
    _updateTransformation();
  }

  void _resetView() {
    _scale = 1.0;
    _transformationController.value = Matrix4.identity();
    setState(() {});
  }

  void _fitToScreen() {
    // Используем LayoutBuilder для получения актуальных размеров
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      final viewportWidth = MediaQuery.of(context).size.width - 40;
      final diagramWidth = viewportWidth;
      final diagramHeight = 600;

      final scaleX = viewportWidth / diagramWidth;
      final scaleY = (MediaQuery.of(context).size.height - 200) / diagramHeight;

      _scale = math.min(scaleX, scaleY).clamp(_minScale, _maxScale);
      _updateTransformation();
    });
  }

  void _updateTransformation() {
    // Сохраняем текущий центр трансформации
    final currentTranslation = _transformationController.value.getTranslation();

    _transformationController.value = Matrix4.identity()
      ..translate(currentTranslation.x, currentTranslation.y)
      ..scale(_scale);

    setState(() {});
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
