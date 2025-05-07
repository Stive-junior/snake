class GameConstants {
  // Vitesse de déplacement du serpent (en unités AR par seconde, à ajuster)
  static const double snakeSpeed = 0.1;

  // Taille initiale du serpent (nombre de segments)
  static const int initialSnakeLength = 3;

  // Taille d'un segment du serpent en unités AR (à adapter à votre modèle 3D)
  static const double snakeSegmentSize = 0.9;

  // Distance minimale entre les segments du serpent pour éviter les collisions internes
  static const double minSegmentDistance = snakeSegmentSize * 0.9;

  // Taille de la nourriture en unités AR (à adapter à votre modèle 3D)
  static const double foodSize = 0.08;

  // Fréquence d'apparition de la nourriture (en secondes)
  static const double foodSpawnInterval = 5.0;

  // Noms des fichiers d'assets 3D
static const String snakeModelPath = 'serpent/snake_model.glb';
static const String foodModelPath = 'serpent/apple.glb';

  // Noms des fichiers audio
  static const String foodEatSound = 'serpent/eat.mp3';
  static const String collisionSound = 'serpent/collision.mp3';
  static const String backgroundMusic = 'serpent/background.mp3';

  // Clés pour la sauvegarde des scores
  static const String highScoresKey = 'high_scores';

  // Nombre maximum de meilleurs scores à sauvegarder
  static const int maxHighScores = 10;
}
