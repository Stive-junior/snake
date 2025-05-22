import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:verse/screens/pause_screen.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/utils/score_manager.dart';
import 'package:verse/utils/game_logic.dart';
import 'package:verse/widgets/score_display.dart';
import 'package:verse/utils/audio_manager.dart';
import 'package:verse/screens/game_over_screen.dart';
import 'package:verse/widgets/quick_settings_dialog.dart';
import 'package:verse/utils/constants.dart';
import 'package:verse/utils/model_loader.dart';

class ArGameScreen extends StatefulWidget {
  const ArGameScreen({super.key});

  @override
  State<ArGameScreen> createState() => _ArGameScreenState();
}

class _ArGameScreenState extends State<ArGameScreen> with WidgetsBindingObserver {
  // Managers AR
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  late ARLocationManager arLocationManager;

  // Nodes AR
  final List<ARNode> _snakeNodes = [];
  ARNode? _foodNode;

  // Modèles
  final ModelLoader _modelLoader = ModelLoader();
  NodeType _modelNodeType = NodeType.fileSystemAppFolderGLB;

  // Logique de jeu
  late GameLogic _gameLogic;

  // État du jeu
  SnakeDirection _currentSwipeDirection = SnakeDirection.none;
  Timer? _gameLoopTimer;
  double _lastFrameTime = 0;
  int _currentScore = 0;
  bool _isGamePaused = false;
  bool _arCoreLoaded = false;
  bool _cameraPermissionGranted = false;
  bool _showPlaneDetection = true;
  bool _modelsReady = false;
  bool _initialized = false;
  bool _errorState = false;
  String _errorMessage = '';
  String _debugInfo = '';
  bool _appInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
    _gameLogic = GameLogic(
      initialLength: GameConstants.initialSnakeLength,
      segmentSize: GameConstants.snakeSegmentSize,
      foodSize: GameConstants.foodSize,
      spawnFoodCallback: _spawnFood,
      checkCollisionCallback: _checkCollision,
      moveSnakeNodesCallback: _moveSnakeNodes,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appInBackground = state != AppLifecycleState.resumed;

    if (state == AppLifecycleState.paused) {
      _pauseGame();
    } else if (state == AppLifecycleState.resumed && _isGamePaused && !_errorState) {
      _resumeGame();
    }
  }

  Future<void> _initializeGame() async {
    try {
      // Configuration initiale
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialisation des modèles
      await _initializeModels();

      // Vérification des permissions
      await _checkPermissions();

      // Démarrer la musique
      AudioManager.playBackgroundMusic();

      // Détection de plan
      if (mounted && !_errorState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPlaneDetectionDialog();
        });
      }

      setState(() {
        _modelsReady = _modelLoader.isInitialized;
        _initialized = true;
      });
    } catch (e) {
      _handleError("Erreur d'initialisation: ${e.toString()}");
    }
  }

  Future<void> _initializeModels() async {
    await _modelLoader.initialize();
    await _updateModelSourceInfo();
    _updateNodeType();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception("Permission caméra refusée");
    }
    setState(() => _cameraPermissionGranted = true);
  }

  Future<void> _updateModelSourceInfo() async {
    if (_modelLoader.isInitialized) {
      final info = await _modelLoader.getDebugInfo();
      if (mounted) {
        setState(() => _debugInfo = info);
      }
    }
  }

  void _updateNodeType() {
    setState(() {
      if (_modelLoader.currentSource == ModelSource.remote) {
        _modelNodeType = NodeType.webGLB;
      } else {
        final snakePath = _modelLoader.snakeModelPath ?? '';
        _modelNodeType = snakePath.startsWith('assets')
            ? NodeType.localGLTF2
            : NodeType.fileSystemAppFolderGLB;
      }
    });
  }

  Future<void> _toggleModelSource() async {
    try {
      setState(() => _modelsReady = false);
      await _modelLoader.toggleModelSource();
      _updateNodeType();
      await _updateModelSourceInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Source: ${_modelLoader.currentSource == ModelSource.local ? 'Locale' : 'Distante'}",
            style: AppTypography.bodyMedium,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      if (_arCoreLoaded) {
        await _resetArSession();
      }
    } catch (e) {
      _handleError("Changement de source échoué: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _modelsReady = _modelLoader.isInitialized);
      }
    }
  }

  Future<void> _resetArSession() async {
    try {
      // Nettoyage des nœuds existants
      for (final node in _snakeNodes) {
        await arObjectManager.removeNode(node);
      }
      _snakeNodes.clear();

      if (_foodNode != null) {
        await arObjectManager.removeNode(_foodNode!);
        _foodNode = null;
      }

      // Réinitialisation AR
      if (mounted) {
        setState(() {
          _currentScore = 0;
          _arCoreLoaded = false;
        });
      }


      // Rechargement après un délai
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_errorState) {
          setState(() => _arCoreLoaded = true);
          if (_modelsReady) _addInitialSnake();
        }
      });
    } catch (e) {
      _handleError("Réinitialisation AR échouée: ${e.toString()}");
    }
  }

  void _showPlaneDetectionDialog() {
    if (_errorState || !_cameraPermissionGranted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Détection de plan", style: AppTypography.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Déplacez lentement pour détecter une surface plane",
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() => _showPlaneDetection = false);
              }
              Navigator.of(context).pop();
            },
            child: Text("OK", style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch / 1000;

    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        if (!_isGamePaused && _arCoreLoaded && _cameraPermissionGranted &&
            _modelsReady && !_errorState && !_appInBackground) {
          final now = DateTime.now().millisecondsSinceEpoch / 1000;
          final deltaTime = now - _lastFrameTime;
          _lastFrameTime = now;
          _updateGame(deltaTime);
        }
      },
    );
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    if (_arCoreLoaded) {
      arSessionManager.dispose();
    }

    AudioManager.stopBackgroundMusic();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    // Configuration de la session AR
    arSessionManager.onInitialize(
      showFeaturePoints: true,
      showPlanes: _showPlaneDetection,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );

    arObjectManager.onInitialize();
    arObjectManager.onNodeTap = (nodes) => debugPrint("Node tapped: ${nodes.join(', ')}");


    if (mounted) {
      setState(() => _arCoreLoaded = true);
    }

    _startGameLoop();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_modelsReady && !_errorState && mounted) {
        _addInitialSnake();
      }
    });
  }

  Future<void> _addInitialSnake() async {
    if (!_modelsReady || _errorState) return;

    try {
      for (final position in _gameLogic.snakePositions) {
        await _addSnakeSegment(position);
      }
    } catch (e) {
      _handleError("Création serpent initial échouée: ${e.toString()}");
    }
  }

  Future<void> _addSnakeSegment(vector.Vector3 position) async {
    final snakePath = _modelLoader.snakeModelPath;
    if (snakePath == null || _errorState) return;

    try {
      final newNode = ARNode(
        type: _modelNodeType,
        uri: snakePath,
        position: position,
        scale: vector.Vector3(0.2, 0.2, 0.2),
        rotation: vector.Vector4(0, 0, 0, 0),
      );

      final success = await arObjectManager.addNode(newNode);
      if (success == true) {
        _snakeNodes.add(newNode);
      } else {
        throw Exception("Échec d'ajout du segment");
      }
    } catch (e) {
      throw Exception("Erreur ajout segment: ${e.toString()}");
    }
  }

  Future<void> _spawnFood(vector.Vector3 position) async {
    final foodPath = _modelLoader.foodModelPath;
    if (foodPath == null || _errorState) return;

    try {
      if (_foodNode != null) {
        await arObjectManager.removeNode(_foodNode!);
      }

      final newNode = ARNode(
        type: _modelNodeType,
        uri: foodPath,
        position: position,
        scale: vector.Vector3(0.2, 0.2, 0.2),
        rotation: vector.Vector4(0, 0, 0, 0),
      );

      await arObjectManager.addNode(newNode);
      _foodNode = newNode;
    } catch (e) {
      throw Exception("Erreur création nourriture: ${e.toString()}");
    }
  }

  Future<void> _moveSnakeNodes(List<vector.Vector3> newPositions) async {
    if (_errorState) return;

    try {
      // Ajout de nouveaux segments
      if (_snakeNodes.length < newPositions.length) {
        for (int i = _snakeNodes.length; i < newPositions.length; i++) {
          await _addSnakeSegment(newPositions[i]);
        }
      }
      // Suppression de segments
      else if (_snakeNodes.length > newPositions.length) {
        while (_snakeNodes.length > newPositions.length) {
          final lastNode = _snakeNodes.removeLast();
          await arObjectManager.removeNode(lastNode);
        }
      }

      // Mise à jour des positions
      for (int i = 0; i < newPositions.length; i++) {
        final node = _snakeNodes[i];
        node.position = newPositions[i];
        final newTransform = Matrix4.copy(node.transformNotifier.value);
        newTransform.setTranslation(newPositions[i]);
        node.transformNotifier.value = newTransform;
      }
    } catch (e) {
      _handleError("Mouvement serpent échoué: ${e.toString()}");
    }
  }

  bool _checkCollision(vector.Vector3 position) {
    try {
      for (int i = 0; i < _snakeNodes.length; i++) {
        if ((_snakeNodes[i].position - position).length <
            GameConstants.minSegmentDistance && i != 0) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _handleError("Détection collision échouée: ${e.toString()}");
      return true;
    }
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_isGamePaused || !_arCoreLoaded || !_modelsReady || _errorState) return;

    try {
      const double sensitivity = 20.0;
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      if (dx.abs() > dy.abs()) {
        if (dx > sensitivity && _currentSwipeDirection != SnakeDirection.left) {
          _currentSwipeDirection = SnakeDirection.right;
        } else if (dx < -sensitivity && _currentSwipeDirection != SnakeDirection.right) {
          _currentSwipeDirection = SnakeDirection.left;
        }
      } else {
        if (dy > sensitivity && _currentSwipeDirection != SnakeDirection.up) {
          _currentSwipeDirection = SnakeDirection.down;
        } else if (dy < -sensitivity && _currentSwipeDirection != SnakeDirection.down) {
          _currentSwipeDirection = SnakeDirection.up;
        }
      }
    } catch (e) {
      _handleError("Gestion swipe échouée: ${e.toString()}");
    }
  }

  void _updateGame(double deltaTime) {
    if (!_arCoreLoaded || !_modelsReady || _errorState) return;

    try {
      final ateFood = _gameLogic.update(deltaTime, _currentSwipeDirection);
      _currentSwipeDirection = SnakeDirection.none;

      if (ateFood) {
        if (mounted) {
          setState(() => _currentScore++);
        }
        AudioManager.playSoundEffect(GameConstants.foodEatSound);
      }

      if (_gameLogic.isGameOver) {
        _gameOver();
      }
    } catch (e) {
      _handleError("Mise à jour jeu échouée: ${e.toString()}");
    }
  }

  void _gameOver() {
    try {
      _gameLoopTimer?.cancel();
      AudioManager.playSoundEffect(GameConstants.collisionSound);
      AudioManager.stopBackgroundMusic();
      ScoreManager.saveScore(_currentScore);

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameOverScreen(score: _currentScore),
            )
        );
      }
    } catch (e) {
      _handleError("Fin de jeu échouée: ${e.toString()}");
    }
  }

  void _pauseGame() {
    if (_errorState) return;

    _gameLoopTimer?.cancel();
    if (mounted) {
      setState(() => _isGamePaused = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PauseScreen(onResume: _resumeGame),
      );
    }
  }

  void _resumeGame() {
    if (_errorState) return;

    if (mounted) {
      setState(() => _isGamePaused = false);
      _startGameLoop();
      Navigator.of(context).pop();
    }
  }

  void _showQuickSettings() {
    if (_errorState) return;

    _gameLoopTimer?.cancel();
    if (mounted) {
      setState(() => _isGamePaused = true);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Paramètres', style: AppTypography.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Musique', style: AppTypography.bodyMedium),
                  value: AudioManager.isMusicEnabled,
                  onChanged: (value) => AudioManager.toggleMusic(value),
                ),
                SwitchListTile(
                  title: Text('Effets sonores', style: AppTypography.bodyMedium),
                  value: AudioManager.isSfxEnabled, // Corrected this line
                  onChanged: (value) => AudioManager.toggleSfx(value),
                ),
                ListTile(
                  title: Text('Source modèles', style: AppTypography.bodyMedium),
                  trailing: Switch(
                    value: _modelLoader.currentSource == ModelSource.remote,
                    onChanged: (value) => _toggleModelSource(),
                  ),
                  subtitle: Text(
                    _modelLoader.currentSource == ModelSource.local
                        ? 'Locale'
                        : 'Distante',
                    style: AppTypography.bodySmall,
                  ),
                ),
                if (kDebugMode) ...[
                  const Divider(),
                  ListTile(
                    title: Text('Debug', style: AppTypography.bodyMedium),
                    trailing: const Icon(Icons.bug_report),
                    onTap: () {
                      Navigator.of(context).pop();
                      _resumeGame(); // Ensure game resumes after closing dialog.
                      _showDebugInfo();
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeGame(); // Make sure to resume the game.
              },
              child: Text('Fermer', style: AppTypography.button),
            ),
          ],
        ),
      );
    }
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Info', style: AppTypography.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modèles:', style: AppTypography.bodyLarge),
              Text(_debugInfo, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              Text('État AR:', style: AppTypography.bodyLarge),
              Text('AR Core chargé: $_arCoreLoaded'),
              Text('Nœuds serpent: ${_snakeNodes.length}'),
              Text('Type de nœud: $_modelNodeType'),
              const SizedBox(height: 16),
              Text('Jeu:', style: AppTypography.bodyLarge),
              Text('Score: $_currentScore'),
              Text('Pause: $_isGamePaused'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _modelLoader.cleanLocalFiles();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fichiers nettoyés')),
                );
              }
              Navigator.of(context).pop();
              _resumeGame(); // Add this line to resume the game after cleanup
            },
            child: Text('Nettoyer', style: AppTypography.button),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeGame(); // Add this line to resume the game after closing
            },
            child: Text('Fermer', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  void _handleError(String message) {
    debugPrint("ERREUR: $message");
    if (_errorState) return;

    if (mounted) {
      setState(() {
        _errorState = true;
        _errorMessage = message;
        _isGamePaused = true;
      });
    }

    _gameLoopTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Erreur', style: AppTypography.headlineSmall.copyWith(
            color: ColorPalette.errorColor,
          )),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                Text(_debugInfo, style: AppTypography.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text('Réessayer', style: AppTypography.button),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Quitter', style: AppTypography.button.copyWith(
                color: ColorPalette.errorColor,
              )),
            ),
          ],
        ),
      );
    });
  }

  void _resetGame() {
    try {
      if (mounted) {
        setState(() {
          _errorState = false;
          _errorMessage = '';
          _isGamePaused = false;
          _currentScore = 0;
          _snakeNodes.clear();
          _foodNode = null;
          _arCoreLoaded = false; // Add this line
        });
      }
      _initializeGame();
    } catch (e) {
      debugPrint("Réinitialisation échouée: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AR Snake',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              )
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _modelLoader.currentSource == ModelSource.local
                  ? Icons.cloud_off
                  : Icons.cloud,
              color: Colors.white,
            ),
            onPressed: _toggleModelSource,
            tooltip: 'Changer source modèles',
          ),
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.white),
            onPressed: _pauseGame,
            tooltip: 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showQuickSettings,
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorState) {
      return _buildErrorScreen();}

    if (!_initialized) {
      return _buildLoadingScreen();
    }

    if (!_cameraPermissionGranted) {
      return _buildPermissionScreen();
    }

    return Stack(
      children: [
        // Vue AR principale
        GestureDetector(
          onVerticalDragUpdate: _handleSwipe,
          onHorizontalDragUpdate: _handleSwipe,
          child: ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            showPlatformType: false,
          ),
        ),

        // Score
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 0,
          right: 0,
          child: Center(
            child: ScoreDisplay(score: _currentScore),
          ),
        ),

        // Overlay détection de plan
        if (_showPlaneDetection && _cameraPermissionGranted)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Recherche de surface plane...",
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Déplacez lentement votre appareil",
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Overlay chargement modèles
        if (!_modelsReady)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Chargement des modèles...",
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (_modelLoader.currentSource == ModelSource.remote)
                      const SizedBox(height: 8),
                    if (_modelLoader.currentSource == ModelSource.remote)
                      Text(
                        "Cette opération peut prendre quelques instants",
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: ColorPalette.primaryColor,
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text(
              "Initialisation du jeu...",
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (!status.isGranted) {
        throw Exception("Permission caméra refusée");
      }

      setState(() => _cameraPermissionGranted = true);
    } catch (e) {
      _handleError("Erreur permission caméra: ${e.toString()}");
    }
  }


  Widget _buildPermissionScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 60,
                color: ColorPalette.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Permission requise',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'L\'accès à la caméra est nécessaire pour jouer en réalité augmentée',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Autoriser la caméra',
                  style: AppTypography.button,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: ColorPalette.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: ColorPalette.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                "Oups, quelque chose a mal tourné",
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: AppTypography.button,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Quitter',
                  style: AppTypography.button.copyWith(
                    color: ColorPalette.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

