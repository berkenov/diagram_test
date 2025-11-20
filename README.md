# Interactive Architecture Diagram (Flutter)

A high-performance, interactive diagramming tool built with Flutter, designed to visualize complex system architectures with an "infinite canvas" experience.

![Project Demo](https://via.placeholder.com/800x400?text=Interactive+Diagram+Demo)
*(Replace this placeholder with a GIF or screenshot of your application)*

## 🚀 Overview

This project demonstrates a custom-built diagramming engine capable of handling dynamic node placement, automatic layout adjustments, and real-time connection rendering. It mimics the feel of professional tools like Miro or Figma but is tailored for structured architectural diagrams.

## ✨ Key Features

-   **Infinite Canvas**:
    -   Seamless horizontal and vertical scrolling with virtually infinite bounds.
    -   "Sticky" level labels that remain visible on the screen edge while panning.
-   **Smart Auto-Layout**:
    -   **Dynamic Levels**: Nodes are organized into hierarchical levels (0-9+).
    -   **Auto-Centering**: Content within levels is automatically centered based on the diagram width.
    -   **Vertical Spacing**: Intelligent gap management ensures consistent spacing between nodes and level boundaries.
-   **Interactive Nodes**:
    -   **Drag & Drop**: Smooth physics-based dragging with real-time position updates.
    -   **Visual Feedback**: Nodes become semi-transparent while dragging.
-   **Advanced Connections**:
    -   **Bezier Curves**: Smooth, cubic Bezier curves connect nodes, dynamically adjusting curvature based on relative positions.
    -   **Smart Anchors**: Connections automatically snap to the most logical side of a node (Top, Bottom, Left, Right) to minimize visual clutter.
    -   **Precision Rendering**: Arrows point exactly to the node boundaries using ray-rectangle intersection algorithms.
    -   **Intensity Labels**: Connection weights are displayed clearly on the path.
-   **Zoom & Pan**:
    -   Full support for pinch-to-zoom and pan gestures using `InteractiveViewer`.
    -   "Fit to Screen" and dynamic initial scaling logic.

## 🛠 Technical Highlights

### Custom Layout Engine
Instead of relying on standard Flutter layout widgets (Column/Row), this project implements a custom layout logic in `DiagramManager`. It calculates exact `Offset` coordinates for every node based on:
-   Hierarchical level grouping.
-   Topological sorting for minimizing crossing lines (in `LevelBuilderImpl`).
-   Dynamic content width calculation.

### High-Performance Rendering
-   **Custom Painters**: `LevelsPainter` and `ConnectionsPainter` are used for rendering the background grid and connection lines. This ensures 60fps performance even with complex paths, as it avoids the overhead of heavy widget trees for static visual elements.
-   **Ray-Casting Algorithms**: Used to calculate the exact intersection points of connection arrows with node bounding boxes, ensuring pixel-perfect rendering regardless of node size or position.

### State Management & Architecture
-   **Clean Architecture**: Separation of concerns between the UI (`InteractiveDiagramWidget`), logic (`DiagramManager`), and data entities (`SubscriberNode`, `Connection`).
-   **Optimized Rebuilds**: Strategic use of `RepaintBoundary` and `shouldRepaint` in custom painters to minimize unnecessary rendering cycles.

## 💻 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/diagram-project.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run -d macos
    # or
    flutter run -d chrome
    ```

## 🔧 Tech Stack

-   **Framework**: Flutter 3.x
-   **Language**: Dart 3.x
-   **Platforms**: macOS, Windows, Web, iOS, Android

---

*This project was built to demonstrate advanced Flutter capabilities in creating custom interactive tools and visualization engines.*
