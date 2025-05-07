import 'package:flutter/material.dart';
import 'package:verse/screens/pause_screen.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:verse/utils/score_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:verse/utils/game_logic.dart';
import 'package:verse/widgets/score_display.dart';
import 'package:verse/utils/audio_manager.dart';
import 'package:verse/screens/game_over_screen.dart';
import 'package:verse/widgets/quick_settings_dialog.dart';
import 'package:verse/utils/constants.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ArGameScreen extends StatefulWidget {
  const ArGameScreen({super.key});

  @override
  State<ArGameScreen> createState() => _ArGameScreenState();
}

class _ArGameScreenState extends State<ArGameScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;

  final List<ARNode> _snakeNodes = [];
  ARNode? _foodNode;
  String? _snakeModelPath;
  String? _foodModelPath;

  final GameLogic _gameLogic = GameLogic(
    initialLength: GameConstants.initialSnakeLength,
    segmentSize: GameConstants.snakeSegmentSize,
    foodSize: GameConstants.foodSize,
    spawnFoodCallback: (position) {},
    checkCollisionCallback: (position) => false,
    moveSnakeNodesCallback: (positions) {},
  );

  SnakeDirection _currentSwipeDirection = SnakeDirection.none;
  Timer? _gameLoopTimer;
  double _lastFrameTime = 0;
  int _currentScore = 0;
  bool _isGamePaused = false;
  bool _arCoreLoaded = false;
  bool _cameraPermissionGranted = false;
  bool _showPlaneDetection = true;
  bool _modelsReady = false;

  @override
  void initState() {
    super.initState();
    _initializeModels().then((_) {
      _requestCameraPermission();
      AudioManager.playBackgroundMusic();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPlaneDetectionDialog();
      });
    });
  }

  Future<void> _initializeModels() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      // Chemin des fichiers dans le dossier documents
      final snakeModelFile = File('${appDocDir.path}/snake_model.glb');
      final foodModelFile = File('${appDocDir.path}/apple.glb');

      // Copier depuis les assets si les fichiers n'existent pas
      if (!await snakeModelFile.exists()) {
        final snakeData = await rootBundle.load('assets/serpent/snake_model.glb');
        await snakeModelFile.writeAsBytes(snakeData.buffer.asUint8List());
      }

      if (!await foodModelFile.exists()) {
        final foodData = await rootBundle.load('assets/serpent/apple.glb');
        await foodModelFile.writeAsBytes(foodData.buffer.asUint8List());
      }

      setState(() {
        _snakeModelPath = snakeModelFile.path;
        _foodModelPath = foodModelFile.path;
        _modelsReady = true;
      });
    } catch (e) {
      debugPrint('Error initializing models: $e');
      // Fallback aux assets si le stockage local échoue
      setState(() {
        _snakeModelPath = 'assets/serpent/snake_model.glb';
        _foodModelPath = 'assets/serpent/apple.glb';
        _modelsReady = true;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _cameraPermissionGranted = true);
    } else {
      var result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() => _cameraPermissionGranted = true);
      } else {
        debugPrint("Camera permission denied");
      }
    }
  }

  void _showPlaneDetectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Détection de plan", style: AppTypography.headlineSmall),
          content: Text(
            "Déplacez lentement votre appareil pour détecter une surface plane",
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _showPlaneDetection = false);
                Navigator.of(context).pop();
              },
              child: Text("OK", style: AppTypography.button),
            ),
          ],
        );
      },
    );
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isGamePaused && _arCoreLoaded && _cameraPermissionGranted && _modelsReady) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final deltaTime = now - _lastFrameTime;
        _lastFrameTime = now;
        _updateGame(deltaTime);
      }
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    arSessionManager.dispose();
    AudioManager.stopBackgroundMusic();
    super.dispose();
  }

  void _onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: _showPlaneDetection,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
    );

    arObjectManager.onInitialize();

    arObjectManager.onNodeTap = (nodes) {
      debugPrint("Node tapped: ${nodes.join(', ')}");
    };

    setState(() {
      _arCoreLoaded = true;
      _startGameLoop();
    });

    _initializeGameLogic();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_modelsReady) {
        _addInitialSnake();
      }
    });
  }

  void _initializeGameLogic() {
    _gameLogic.spawnFoodCallback = _spawnFood;
    _gameLogic.checkCollisionCallback = _checkCollision;
    _gameLogic.moveSnakeNodesCallback = _moveSnakeNodes;

    _gameLogic.initialize(
      initialLength: GameConstants.initialSnakeLength,
      segmentSize: GameConstants.snakeSegmentSize,
      foodSize: GameConstants.foodSize,
      spawnFood: _spawnFood,
      checkCollision: _checkCollision,
      moveSnakeNodes: _moveSnakeNodes,
    );
  }

  Future<void> _addInitialSnake() async {
    if (!_modelsReady) return;

    for (final position in _gameLogic.snakePositions) {
      await _addSnakeSegment(position);
    }
  }

  Future<void> _addSnakeSegment(vector.Vector3 position) async {
    if (_snakeModelPath == null) return;

    try {
      final newNode = ARNode(
        type: _snakeModelPath!.startsWith('assets/')
            ? NodeType.localGLTF2
            : NodeType.fileSystemAppFolderGLB,
        uri: _snakeModelPath!,
        position: position,
        scale: vector.Vector3.all(GameConstants.snakeSegmentSize * 0.9),
      );

      bool? success = await arObjectManager.addNode(newNode);
      if (success == true) {
        _snakeNodes.add(newNode);
      } else {
        debugPrint("Failed to add snake segment");
      }
    } catch (e) {
      debugPrint("Error adding snake segment: ${e.toString()}");
    }
  }

  Future<void> _spawnFood(vector.Vector3 position) async {
    if (_foodModelPath == null) return;

    if (_foodNode != null) {
      await arObjectManager.removeNode(_foodNode!);
    }

    final newNode = ARNode(
      type: _foodModelPath!.startsWith('assets/')
          ? NodeType.localGLTF2
          : NodeType.fileSystemAppFolderGLB,
      uri: _foodModelPath!,
      position: position,
      scale: vector.Vector3.all(GameConstants.foodSize / 2),
    );

    try {
      await arObjectManager.addNode(newNode);
      _foodNode = newNode;
    } catch (e) {
      debugPrint("Failed to spawn food: $e");
    }
  }

  Future<void> _moveSnakeNodes(List<vector.Vector3> newPositions) async {
    try {
      if (_snakeNodes.length < newPositions.length) {
        for (int i = _snakeNodes.length; i < newPositions.length; i++) {
          await _addSnakeSegment(newPositions[i]);
        }
      } else if (_snakeNodes.length > newPositions.length) {
        while (_snakeNodes.length > newPositions.length) {
          final lastNode = _snakeNodes.removeLast();
          await arObjectManager.removeNode(lastNode);
        }
      }

      for (int i = 0; i < newPositions.length; i++) {
        final node = _snakeNodes[i];
        node.position = newPositions[i];
        final newTransform = Matrix4.copy(node.transformNotifier.value);
        newTransform.setTranslation(newPositions[i]);
        node.transformNotifier.value = newTransform;
      }
    } catch (e) {
      debugPrint("Error moving snake nodes: $e");
    }
  }

  bool _checkCollision(vector.Vector3 position) {
    for (int i = 0; i < _snakeNodes.length; i++) {
      if ((_snakeNodes[i].position - position).length <
          GameConstants.minSegmentDistance &&
          i != 0) {
        return true;
      }
    }
    return false;
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_isGamePaused || !_arCoreLoaded || !_cameraPermissionGranted || !_modelsReady) return;

    const double sensitivity = 20.0;
    if (details.delta.dx > sensitivity &&
        _currentSwipeDirection != SnakeDirection.left) {
      _currentSwipeDirection = SnakeDirection.right;
    } else if (details.delta.dx < -sensitivity &&
        _currentSwipeDirection != SnakeDirection.right) {
      _currentSwipeDirection = SnakeDirection.left;
    } else if (details.delta.dy > sensitivity &&
        _currentSwipeDirection != SnakeDirection.up) {
      _currentSwipeDirection = SnakeDirection.down;
    } else if (details.delta.dy < -sensitivity &&
        _currentSwipeDirection != SnakeDirection.down) {
      _currentSwipeDirection = SnakeDirection.up;
    }
  }

  void _updateGame(double deltaTime) {
    if (!_arCoreLoaded || !_cameraPermissionGranted || !_modelsReady) return;

    final ateFood = _gameLogic.update(deltaTime, _currentSwipeDirection);
    _currentSwipeDirection = SnakeDirection.none;

    if (ateFood) {
      setState(() {
        _currentScore++;
      });
      AudioManager.playSoundEffect(GameConstants.foodEatSound);
    }

    if (_gameLogic.isGameOver) {
      _gameOver();
    }
  }

  void _gameOver() {
    _gameLoopTimer?.cancel();
    AudioManager.playSoundEffect(GameConstants.collisionSound);
    AudioManager.stopBackgroundMusic();
    ScoreManager.saveScore(_currentScore);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameOverScreen(score: _currentScore),
      ),
    );
  }

  void _pauseGame() {
    setState(() {
      _isGamePaused = true;
      _gameLoopTimer?.cancel();
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PauseScreen(onResume: _resumeGame);
      },
    );
  }

  void _resumeGame() {
    setState(() {
      _isGamePaused = false;
      _startGameLoop();
    });
    Navigator.of(context).pop();
  }

  void _showQuickSettings() {
    setState(() {
      _isGamePaused = true;
      _gameLoopTimer?.cancel();
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const QuickSettingsDialog();
      },
    ).then((_) {
      setState(() {
        _isGamePaused = false;
        _startGameLoop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('AR Snake', style: AppTypography.headlineSmall.copyWith(
          color: Colors.white,
          shadows: [
          Shadow(
          blurRadius: 4.0,
          color: Colors.black,
          offset: Offset(2.0, 2.0),
          )],
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.pause_rounded, color: Colors.white),
            onPressed: _pauseGame,
          ),
          IconButton(
            icon: Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: _showQuickSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_cameraPermissionGranted)
            GestureDetector(
              onVerticalDragUpdate: _handleSwipe,
              onHorizontalDragUpdate: _handleSwipe,
              child: ARView(
                onARViewCreated: _onARViewCreated,
                planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 60, color: ColorPalette.errorColor),
                  SizedBox(height: 16),
                  Text(
                    'Permission caméra requise',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                    ),
                    child: Text('Autoriser la caméra', style: AppTypography.button),
                  ),
                ],
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: Center(
              child: ScoreDisplay(score: _currentScore),
            ),
          ),

          if (_showPlaneDetection && _cameraPermissionGranted)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Déplacez votre appareil pour détecter une surface",
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_modelsReady)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        "Chargement des modèles...",
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
