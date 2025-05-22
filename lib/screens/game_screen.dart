import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:permission_handler/permission_handler.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  late ARLocationManager arLocationManager;

  // Position initiale du serpent : 1 mètre devant la caméra
  Vector3 snakePosition = Vector3(0, 0, -1);
  List<ARNode> arNodes = [];

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Snake Game AR")),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) {
              _onARViewCreated(sessionManager, objectManager, anchorManager, locationManager);
            },
          ),
          _buildControls(),
        ],
      ),
    );
  }

  /// Initialise la session AR et ajoute le nœud du serpent directement sans ancrage.
  void _onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    // Activez éventuellement l'affichage des points caractéristiques pour faciliter le debug.
    arSessionManager.onInitialize(showFeaturePoints: true);
    arObjectManager.onInitialize();

    // Créez directement le nœud du serpent sans utiliser d'ancrage (pour éviter les problèmes d'instanciation)
    ARNode snakeNode = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/serpent/snake_model.glb",
      scale: Vector3.all(0.2),
      position: snakePosition,
      name: "snake_head",
    );

    // Ajoute le nœud directement à la scène.
    arObjectManager.addNode(snakeNode);
    arNodes.add(snakeNode);
    debugPrint("Snake node added at position: $snakePosition");
  }

  /// Fonction permettant de déplacer le serpent en supprimant l'ancien nœud et en en créant un nouveau.
  void moveSnake(Vector3 direction) {
    setState(() {
      snakePosition += direction;
      debugPrint("Moving snake to: $snakePosition");

      // Recherche et suppression de l'ancien nœud
      ARNode? snakeNode;
      try {
        snakeNode = arNodes.firstWhere((node) => node.name == "snake_head");
      } catch (e) {
        snakeNode = null;
      }
      if (snakeNode != null) {
        arObjectManager.removeNode(snakeNode);
        arNodes.remove(snakeNode);
        debugPrint("Removed old snake node");
      }

      // Création et ajout d'un nouveau nœud à la nouvelle position
      ARNode newSnakeNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/serpent/snake_model.glb",
        scale: Vector3.all(0.2),
        position: snakePosition,
        name: "snake_head",
      );
      arObjectManager.addNode(newSnakeNode);
      arNodes.add(newSnakeNode);
      debugPrint("Added new snake node at: $snakePosition");
    });
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => moveSnake(Vector3(0, 0, -0.1)),
              child: const Text("⬆️"),
            ),
            ElevatedButton(
              onPressed: () => moveSnake(Vector3(-0.1, 0, 0)),
              child: const Text("⬅️"),
            ),
            ElevatedButton(
              onPressed: () => moveSnake(Vector3(0.1, 0, 0)),
              child: const Text("➡️"),
            ),
            ElevatedButton(
              onPressed: () => moveSnake(Vector3(0, 0, 0.1)),
              child: const Text("⬇️"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      debugPrint("✅ Permission accordée !");
    } else {
      debugPrint("🚨 Permission refusée !");
      openAppSettings();
    }
  }
}
