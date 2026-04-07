// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Shape Merge';

  @override
  String get play => 'Jouer';

  @override
  String get leaderboard => 'Classement';

  @override
  String get shop => 'Boutique';

  @override
  String get settings => 'Paramètres';

  @override
  String get bestScore => 'Meilleur Score';

  @override
  String get score => 'Score';

  @override
  String get shapes => 'Formes';

  @override
  String get merges => 'Fusions';

  @override
  String get capacity => 'Capacité du plateau';

  @override
  String get gameOver => 'Game Over';

  @override
  String get victory => 'Victoire';

  @override
  String get boardFull => 'Plateau plein et aucune fusion possible !';

  @override
  String get noPairs => 'Aucune fusion possible !';

  @override
  String get boardFullWarning => 'Plateau plein — fusionne vite !';

  @override
  String get noPairsNewShapes => 'Pas de paires — nouvelles formes ajoutées !';

  @override
  String get replay => 'Rejouer';

  @override
  String get menu => 'Menu';

  @override
  String get signInGoogle => 'Se connecter avec Google';

  @override
  String get signInToSave =>
      'Connecte-toi pour sauvegarder ton score et voir le classement';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get soundOn => 'Son activé';

  @override
  String get soundOff => 'Son désactivé';

  @override
  String get musicOn => 'Musique activée';

  @override
  String get musicOff => 'Musique désactivée';

  @override
  String get jokerBomb => 'Bombe';

  @override
  String get jokerBombDesc =>
      'Détruit toutes les formes du même type et couleur';

  @override
  String get jokerWildcard => 'Wildcard';

  @override
  String get jokerWildcardDesc =>
      'Fusionne avec n\'importe quelle forme du même niveau';

  @override
  String get jokerReducer => 'Réducteur';

  @override
  String get jokerReducerDesc => 'Réduit le niveau d\'une forme de 1';

  @override
  String get onboardingTitle1 => 'Comment jouer';

  @override
  String get onboardingDesc1 =>
      'Fais glisser des formes identiques pour les fusionner et marquer des points !';

  @override
  String get onboardingTitle2 => 'Tes Jokers';

  @override
  String get onboardingDesc2 =>
      'Tu commences avec 3 de chaque joker. Utilise-les judicieusement !';

  @override
  String get startPlaying => 'Commencer à jouer';

  @override
  String get next => 'Suivant';

  @override
  String get packSmall => 'Petit Pack';

  @override
  String get packMedium => 'Pack Moyen';

  @override
  String get packLarge => 'Grand Pack';

  @override
  String get watchAd => 'Regarder une pub';

  @override
  String get watchAdReward =>
      'Regarde une pub pour obtenir +1 joker de ton choix';

  @override
  String get adNotReady => 'Pub pas encore prête, réessaie dans un instant';

  @override
  String get chooseJoker => 'Choisis un joker à recharger';

  @override
  String get rank => 'Rang';

  @override
  String get allTime => 'Tous les temps';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get maxLevel => 'Niveau max';

  @override
  String fusionsCount(int count) {
    return '$count fusions';
  }

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get connected => 'Connecté';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get quit => 'Quitter';

  @override
  String get howToPlay => 'Comment jouer';

  @override
  String get newRecord => 'Nouveau Record !';

  @override
  String get classicMode => 'Mode Classique';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get displayName => 'Pseudo';

  @override
  String get chooseAvatar => 'Choisis ton avatar';

  @override
  String get save => 'Enregistrer';

  @override
  String get profileUpdated => 'Profil mis à jour !';

  @override
  String get signOutConfirm => 'Te déconnecter ?';
}
