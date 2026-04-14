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
  String get gameOver => 'Fin de partie';

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
  String get signInSuccess => 'Connexion réussie';

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
      'Cible une forme et détruit toutes les formes de même type et couleur';

  @override
  String get jokerWildcard => 'Wildcard';

  @override
  String get jokerWildcardDesc =>
      'Invoque une forme spéciale qui fusionne avec n\'importe quelle forme du même niveau';

  @override
  String get jokerReducer => 'Réducteur';

  @override
  String get jokerReducerDesc =>
      'Réduit le niveau d\'une forme de 1. Au niveau 1, elle disparaît !';

  @override
  String get jokerRadar => 'Radar';

  @override
  String get jokerRadarDesc =>
      'Révèle toutes les fusions possibles pendant 5 secondes';

  @override
  String get jokerEvolution => 'Évolution';

  @override
  String get jokerEvolutionDesc =>
      'Augmente le niveau d\'une forme de +1 sans fusion';

  @override
  String get jokerMegaBomb => 'Méga Bombe';

  @override
  String get jokerMegaBombDesc =>
      'Détruit toutes les formes du même niveau, peu importe leur type';

  @override
  String get onboardingTitle1 => 'Comment jouer';

  @override
  String get onboardingDesc1 =>
      'Glisse une forme sur une forme identique pour les fusionner et marquer des points !';

  @override
  String get onboardingTitle2 => 'Tes Jokers';

  @override
  String get onboardingDesc2 =>
      'Utilise tes jokers pour détruire, transformer ou révéler des fusions !';

  @override
  String get onboardingTitle3 => 'Attention !';

  @override
  String get onboardingDesc3 =>
      'Le plateau se remplit à chaque coup. Plus de place = Game Over !';

  @override
  String get startPlaying => 'Commencer à jouer';

  @override
  String get skipTutorial => 'Passer';

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

  @override
  String streakDay(int n) {
    return 'Jour $n';
  }

  @override
  String get streakConnectedToday => 'Connexion du jour validée !';

  @override
  String get streakBroken => 'Série interrompue';

  @override
  String get streakBrokenDesc => 'Ton streak s\'est interrompu…';

  @override
  String get streakSaveNudge =>
      'Connecte-toi pour ne jamais perdre ton streak.';

  @override
  String get streakCollect => 'Déjà collecté';

  @override
  String get streakLost => 'Streak perdu';

  @override
  String get streakLostDesc =>
      'Reviens chaque jour pour accumuler\ndes bonus plus intéressants.';

  @override
  String get dailyObjectivesTitle => 'OBJECTIFS DU JOUR';

  @override
  String objectiveFusions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Réaliser $n fusions',
      one: 'Réaliser 1 fusion',
    );
    return '$_temp0';
  }

  @override
  String objectiveScore(int n) {
    return 'Atteindre un score de $n';
  }

  @override
  String objectiveParties(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Jouer $n parties',
      one: 'Jouer 1 partie',
    );
    return '$_temp0';
  }

  @override
  String objectiveFormeMax(int n) {
    return 'Atteindre la forme rang $n';
  }

  @override
  String objectiveJokersUses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Utiliser $n jokers',
      one: 'Utiliser 1 joker',
    );
    return '$_temp0';
  }

  @override
  String get objectiveBonusAll => 'Bonus tout compléter';

  @override
  String get objectiveCompleted => 'Objectif complété !';

  @override
  String get collectReward => 'Collecter';

  @override
  String get rewardReceived => 'Récompense reçue !';

  @override
  String get allObjectivesCompleted => 'Tous les objectifs complétés !';

  @override
  String get levelBadge => 'Nv';

  @override
  String levelUp(int n) {
    return 'NIVEAU $n !';
  }

  @override
  String xpGained(int n) {
    return '+$n XP';
  }

  @override
  String xpToNextLevel(int n, int lv) {
    return '$n XP avant le niveau $lv';
  }

  @override
  String get connectToSave => 'Connecte-toi pour sauvegarder';

  @override
  String get later => 'Plus tard';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get deleteAccountConfirm => 'Supprimer définitivement ?';

  @override
  String get tutorialObjectiveLabel => 'OBJECTIF';

  @override
  String get tutorialObjectiveText =>
      'Fusionne les formes identiques (même forme + même couleur + même niveau) pour monter de niveau et atteindre le score max !';

  @override
  String get tutorialControlsLabel => 'CONTRÔLES';

  @override
  String get tutorialControlsText =>
      'Glisse une forme sur une forme identique pour fusionner. Si pas de match, elle revient à sa place.';

  @override
  String get tutorialJokersLabel => 'JOKERS';

  @override
  String get tutorialClassicLabel => 'Classiques';

  @override
  String get tutorialPremiumLabel => 'PREMIUM';

  @override
  String get tutorialGameOverLabel => 'FIN DE PARTIE';

  @override
  String get tutorialGameOverText =>
      'Le plateau se remplit à chaque mouvement. Plus de place + aucune fusion possible = Game Over !';

  @override
  String get tutorialTitle => 'SHAPE MERGE 2048';

  @override
  String get tutorialGoButton => 'GO !';

  @override
  String get hudNewBest => '★ RECORD !';

  @override
  String hudBest(String n) {
    return 'RECORD $n';
  }

  @override
  String get scoreLabel => 'SCORE';

  @override
  String objectivesSummary(int done, int total) {
    return '$done/$total objectifs';
  }

  @override
  String get noScoresYet => 'Aucun score pour le moment';

  @override
  String get leaderboardYou => 'Toi';

  @override
  String get leaderboardError => 'Erreur de chargement du classement';

  @override
  String get packStarName => 'Pack Étoile';

  @override
  String get packCometName => 'Pack Comète';

  @override
  String get packDiamondName => 'Pack Diamant';

  @override
  String get badgeStarter => 'STARTER';

  @override
  String get badgePopular => 'POPULAIRE';

  @override
  String get badgeBestValue => 'MEILLEUR CHOIX';

  @override
  String get purchaseSuccess => 'Achat réussi !';

  @override
  String get purchaseError => 'Erreur d\'achat';

  @override
  String get purchasesRestored => 'Achats restaurés !';

  @override
  String get restoringPurchases => 'Recherche d\'achats précédents…';

  @override
  String get jokerCategoryClassic => 'CLASSIQUE';

  @override
  String get jokerCategoryPremium => 'PREMIUM';

  @override
  String get noAdsTitle => 'ZÉRO PUB + JOKERS';

  @override
  String get badgeOneTimePurchase => '✨ ACHAT UNIQUE';

  @override
  String get noAdsDescription => 'Supprime toutes les pubs !';

  @override
  String get sectionJokerPacks => 'PACKS JOKERS';

  @override
  String get sectionFreeJoker => 'JOKER GRATUIT';

  @override
  String get badgeFree => 'GRATUIT';

  @override
  String get freeLabel => 'GRATUIT';

  @override
  String get validateButton => 'VALIDER';

  @override
  String get rewardLabel => 'Récompense : ';

  @override
  String get rewardAdded => 'Ajouté à ton inventaire !';

  @override
  String get xpLabel => 'XP';

  @override
  String get dayLabel => 'JOUR';

  @override
  String get levelShortLabel => 'NIV';

  @override
  String get defaultPlayerName => 'Joueur';

  @override
  String get defaultGuestName => 'Invité';

  @override
  String get okButton => 'OK';

  @override
  String get notifStreakTitle => 'Votre série est en danger !';

  @override
  String get notifStreakBody =>
      'Jouez une partie pour maintenir votre série de jeu.';

  @override
  String get notifChannelName => 'Série de jeu';

  @override
  String get notifChannelDesc =>
      'Rappels pour garder votre série de jeu active.';

  @override
  String get musicLabel => 'Musique';

  @override
  String languageLabel(String lang) {
    return 'LANGUE : $lang';
  }

  @override
  String get maxShapesWarning => 'Max 30 formes';

  @override
  String get storeNotAvailable => 'Boutique indisponible';

  @override
  String signInError(String error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get jokerSuggestCriticalBomb => 'Bombe pour libérer la grille !';

  @override
  String get jokerSuggestCriticalReducer =>
      'Réducteur pour réduire une forme !';

  @override
  String get jokerSuggestHighBomb => 'Bombe pour faire de la place';

  @override
  String get jokerSuggestMegaBomb => 'Méga Bombe pour tout nettoyer';

  @override
  String get jokerSuggestRadar => 'Radar pour trouver les fusions';

  @override
  String get jokerSuggestWildcard => 'Wildcard pour débloquer';

  @override
  String get jokerSuggestEvolution => 'Évolution pour booster une forme';

  @override
  String get jokerSuggestReducer => 'Réducteur pour créer une paire';

  @override
  String get jokerSuggestUse => 'Utiliser';

  @override
  String get coachWelcome => 'Bienvenue ! 🎮';

  @override
  String get coachWelcomeDesc => 'On va apprendre les bases ensemble !';

  @override
  String get coachWaitMerge => 'À toi ! 🧩';

  @override
  String get coachWaitMergeDesc =>
      'Glisse une forme sur une forme identique (même forme, même couleur, même niveau) pour fusionner !';

  @override
  String get coachMergeDone => 'Bravo ! 🎉';

  @override
  String get coachMergeDoneDesc =>
      'Tu maîtrises la fusion ! Chaque fusion augmente ton score.';

  @override
  String get coachJokers => 'Tes Jokers 🃏';

  @override
  String get coachJokersDesc =>
      'Voici tes jokers ! Chacun a un pouvoir unique.';

  @override
  String get coachWaitJokerLongPress => 'Essaie ! 👇';

  @override
  String get coachWaitJokerLongPressDesc =>
      'Fais un appui long sur un joker pour voir sa description.';

  @override
  String get coachJokerDone => 'Parfait ! 👏';

  @override
  String get coachJokerDoneDesc =>
      'Tu peux consulter la description de chaque joker à tout moment.';

  @override
  String get coachJokerUse => 'Utiliser un Joker 🎯';

  @override
  String get coachJokerUseDesc =>
      'Touche un joker pour l\'activer, puis touche une forme sur la grille pour appliquer son pouvoir.';

  @override
  String get coachScore => 'Score ⭐';

  @override
  String get coachScoreDesc =>
      'Ton score actuel. Chaque fusion rapporte des points.';

  @override
  String get coachCapacity => 'Capacité ⭕';

  @override
  String get coachCapacityDesc =>
      'Nombre de formes sur la grille. Quand c\'est plein et qu\'il n\'y a plus de fusion possible, la partie est finie !';

  @override
  String get coachMerges => 'Fusions ⚡';

  @override
  String get coachMergesDesc =>
      'Nombre total de fusions réalisées dans cette partie.';

  @override
  String get coachComplete => 'C\'est parti ! 🚀';

  @override
  String get coachCompleteDesc =>
      'Tu es prêt ! Fusionne, utilise tes jokers et bats ton record !';

  @override
  String get coachTapContinue => 'Touche pour continuer';

  @override
  String get coachSkip => 'Passer';
}
