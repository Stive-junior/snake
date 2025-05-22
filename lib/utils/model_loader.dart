import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModelSource {
  local,
  remote
}

class ModelLoader {
  static const String _prefKey = 'model_source';
  static const String _remoteBaseUrl =
      'https://github.com/timweri/simple-gltf-glb/blob/master/samples/Box';

  // Chemins pour les modèles
  static const String snakeModelAsset = 'assets/serpent/snake_model.glb';
  static const String foodModelAsset = 'assets/serpent/apple.glb';

  // Noms de fichiers pour stockage local
  static const String snakeModelFilename = 'snake_model.glb';
  static const String foodModelFilename = 'apple.glb';

  // Chemins pour les modèles distants
  static const String snakeModelRemote = '$_remoteBaseUrl/Box.glb';
  static const String foodModelRemote = '$_remoteBaseUrl/Box.glb';

  // Singleton
  static final ModelLoader _instance = ModelLoader._internal();
  factory ModelLoader() => _instance;
  ModelLoader._internal();

  // État
  ModelSource _currentSource = ModelSource.local;
  String? _snakeModelPath;
  String? _foodModelPath;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get snakeModelPath => _snakeModelPath;
  String? get foodModelPath => _foodModelPath;
  ModelSource get currentSource => _currentSource;

  // Initialise les préférences et les chemins
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceIndex = prefs.getInt(_prefKey) ?? ModelSource.local.index;
    _currentSource = ModelSource.values[sourceIndex];

    await _setupModels();
  }

  // Configure les chemins des modèles selon la source actuelle
  Future<void> _setupModels() async {
    try {
      switch (_currentSource) {
        case ModelSource.local:
          await _setupLocalModels();
          break;
        case ModelSource.remote:
          await _setupRemoteModels();
          break;
      }
      _isInitialized = true;
    } catch (e) {
      // En cas d'erreur, utiliser les assets comme fallback
      _setupAssetModels();
      _isInitialized = true;
    }
  }

  // Configure les modèles depuis les assets vers le stockage local
  Future<void> _setupLocalModels() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDocDir.path}/models');

    // Créer le répertoire s'il n'existe pas
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Chemins des fichiers locaux
    final snakeModelFile = File('${modelsDir.path}/$snakeModelFilename');
    final foodModelFile = File('${modelsDir.path}/$foodModelFilename');

    // Copier les fichiers depuis les assets si nécessaire
    if (!await snakeModelFile.exists()) {
      final snakeData = await rootBundle.load(snakeModelAsset);
      await snakeModelFile.writeAsBytes(
          snakeData.buffer.asUint8List(), flush: true);
    }

    if (!await foodModelFile.exists()) {
      final foodData = await rootBundle.load(foodModelAsset);
      await foodModelFile.writeAsBytes(
          foodData.buffer.asUint8List(), flush: true);
    }

    // Vérifier que les fichiers existent
    if (!await snakeModelFile.exists() || !await foodModelFile.exists()) {
      throw Exception("Échec lors de la création des fichiers modèles locaux");
    }

    // Utiliser les chemins absolus corrects
    _snakeModelPath = snakeModelFile.path;
    _foodModelPath = foodModelFile.path;
  }

  // Configure les chemins pour les modèles distants
  Future<void> _setupRemoteModels() async {
    _snakeModelPath = snakeModelRemote;
    _foodModelPath = foodModelRemote;
    //check if the files exist
    if (!await checkFileExists(_snakeModelPath) ||
        !await checkFileExists(_foodModelPath)) {
      throw Exception("Failed to create remote model files");
    }
  }

  // Fallback aux assets en cas d'erreur
  void _setupAssetModels() {
    _snakeModelPath = snakeModelAsset;
    _foodModelPath = foodModelAsset;
    _currentSource = ModelSource.local;
  }

  // Change la source des modèles
  Future<void> toggleModelSource() async {
    _currentSource = _currentSource == ModelSource.local
        ? ModelSource.remote
        : ModelSource.local;

    // Enregistrer la préférence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, _currentSource.index);

    // Reconfigurer les chemins
    await _setupModels();
  }

  // Nettoie les fichiers locaux pour forcer le rechargement
  Future<void> cleanLocalFiles() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDocDir.path}/models');

      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
      }
    } catch (e) {
      print("Erreur lors du nettoyage des fichiers: $e");
    }
  }

  // Vérifie si le fichier existe
  Future<bool> checkFileExists(String? path) async {
    if (path == null) return false;

    // Pour les URLs distantes, on vérifie l'existence en essayant de récupérer les headers.
    if (path.startsWith('http')) {
      try {
        final client = HttpClient();
        final request = await client.headUrl(Uri.parse(path));
        final response = await request.close();
        return response.statusCode == 200;
      } catch (e) {
        print("Error checking remote file: $e");
        return false; // Considérer toute erreur comme une non-existence.
      }
    }

    // Pour les assets, on suppose qu'ils existent
    if (path.startsWith('assets')) return true;

    // Pour les fichiers locaux, on vérifie l'existence
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  // Log détaillé des chemins de fichiers
  Future<String> getDebugInfo() async {
    final snakeExists = await checkFileExists(_snakeModelPath);
    final foodExists = await checkFileExists(_foodModelPath);

    return '''
Source: ${_currentSource.toString()}
Snake model path: $_snakeModelPath
Snake exists: $snakeExists
Food model path: $_foodModelPath
Food exists: $foodExists
    ''';
  }
}