// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shape Merge';

  @override
  String get play => 'Play';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get shop => 'Shop';

  @override
  String get settings => 'Settings';

  @override
  String get bestScore => 'Best Score';

  @override
  String get score => 'Score';

  @override
  String get shapes => 'Shapes';

  @override
  String get merges => 'Merges';

  @override
  String get capacity => 'Board Capacity';

  @override
  String get gameOver => 'Game Over';

  @override
  String get victory => 'Victory';

  @override
  String get boardFull => 'Board full and no possible merge!';

  @override
  String get noPairs => 'No possible merge!';

  @override
  String get boardFullWarning => 'Board full — merge fast!';

  @override
  String get noPairsNewShapes => 'No pairs — new shapes added!';

  @override
  String get replay => 'Play Again';

  @override
  String get menu => 'Menu';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInToSave =>
      'Sign in to save your score and see the leaderboard';

  @override
  String get signOut => 'Sign Out';

  @override
  String get soundOn => 'Sound On';

  @override
  String get soundOff => 'Sound Off';

  @override
  String get musicOn => 'Music On';

  @override
  String get musicOff => 'Music Off';

  @override
  String get jokerBomb => 'Bomb';

  @override
  String get jokerBombDesc =>
      'Targets a shape and destroys all shapes of the same type and color';

  @override
  String get jokerWildcard => 'Wildcard';

  @override
  String get jokerWildcardDesc =>
      'Spawns a special shape that merges with any shape of the same level';

  @override
  String get jokerReducer => 'Reducer';

  @override
  String get jokerReducerDesc =>
      'Reduces a shape\'s level by 1. At level 1, it vanishes!';

  @override
  String get jokerRadar => 'Radar';

  @override
  String get jokerRadarDesc => 'Reveals all possible merges for 5 seconds';

  @override
  String get jokerEvolution => 'Evolution';

  @override
  String get jokerEvolutionDesc =>
      'Increases a shape\'s level by +1 without merging';

  @override
  String get jokerMegaBomb => 'Mega Bomb';

  @override
  String get jokerMegaBombDesc =>
      'Destroys all shapes of the same level, regardless of type';

  @override
  String get onboardingTitle1 => 'How to Play';

  @override
  String get onboardingDesc1 =>
      'Drag identical shapes to merge them and score points!';

  @override
  String get onboardingTitle2 => 'Your Jokers';

  @override
  String get onboardingDesc2 =>
      'You start with 3 of each joker. Use them wisely!';

  @override
  String get startPlaying => 'Start Playing';

  @override
  String get next => 'Next';

  @override
  String get packSmall => 'Small Pack';

  @override
  String get packMedium => 'Medium Pack';

  @override
  String get packLarge => 'Large Pack';

  @override
  String get watchAd => 'Watch an Ad';

  @override
  String get watchAdReward => 'Watch an ad to get +1 joker of your choice';

  @override
  String get adNotReady => 'Ad not ready yet, try again in a moment';

  @override
  String get chooseJoker => 'Choose a joker to recharge';

  @override
  String get rank => 'Rank';

  @override
  String get allTime => 'All Time';

  @override
  String get thisWeek => 'This Week';

  @override
  String get maxLevel => 'Max Level';

  @override
  String fusionsCount(int count) {
    return '$count merges';
  }

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get quit => 'Quit';

  @override
  String get howToPlay => 'How to Play';

  @override
  String get newRecord => 'New Record!';

  @override
  String get classicMode => 'Classic Mode';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get chooseAvatar => 'Choose your avatar';

  @override
  String get save => 'Save';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get signOutConfirm => 'Sign out?';

  @override
  String streakDay(int n) {
    return 'Day $n';
  }

  @override
  String get streakConnectedToday => 'Daily login validated!';

  @override
  String get streakBroken => 'Streak broken';

  @override
  String get streakBrokenDesc => 'Your streak was interrupted…';

  @override
  String get streakSaveNudge => 'Sign in to never lose your streak.';

  @override
  String get streakCollect => 'Awesome!';

  @override
  String get streakLost => 'Streak lost';

  @override
  String get streakLostDesc => 'Come back every day to earn\nbetter bonuses.';

  @override
  String get dailyObjectivesTitle => 'DAILY GOALS';

  @override
  String objectiveFusions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Make $n merges',
      one: 'Make 1 merge',
    );
    return '$_temp0';
  }

  @override
  String objectiveScore(int n) {
    return 'Reach a score of $n';
  }

  @override
  String objectiveParties(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n games',
      one: 'Play 1 game',
    );
    return '$_temp0';
  }

  @override
  String objectiveFormeMax(int n) {
    return 'Reach shape rank $n';
  }

  @override
  String objectiveJokersUses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Use $n jokers',
      one: 'Use 1 joker',
    );
    return '$_temp0';
  }

  @override
  String get objectiveBonusAll => 'Complete all bonus';

  @override
  String get objectiveCompleted => 'Objective completed!';

  @override
  String get collectReward => 'Collect';

  @override
  String get rewardReceived => 'Reward received!';

  @override
  String get allObjectivesCompleted => 'All objectives completed!';

  @override
  String get levelBadge => 'Lv';

  @override
  String levelUp(int n) {
    return 'LEVEL $n!';
  }

  @override
  String xpGained(int n) {
    return '+$n XP';
  }

  @override
  String xpToNextLevel(int n, int lv) {
    return '$n XP to level $lv';
  }

  @override
  String get connectToSave => 'Sign in to save progress';

  @override
  String get later => 'Later';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountConfirm => 'Delete permanently?';

  @override
  String get tutorialObjectiveLabel => 'OBJECTIVE';

  @override
  String get tutorialObjectiveText =>
      'Merge identical shapes (same shape + same color + same level) to level up and reach the highest score!';

  @override
  String get tutorialControlsLabel => 'CONTROLS';

  @override
  String get tutorialControlsText =>
      'Drag a shape onto an identical shape to merge. If no match, it snaps back.';

  @override
  String get tutorialJokersLabel => 'JOKERS';

  @override
  String get tutorialClassicLabel => 'Classic';

  @override
  String get tutorialPremiumLabel => 'PREMIUM';

  @override
  String get tutorialGameOverLabel => 'GAME OVER';

  @override
  String get tutorialGameOverText =>
      'The board fills up with each move. No space + no possible merges = Game Over!';

  @override
  String get tutorialTitle => 'SHAPE MERGE 2048';

  @override
  String get tutorialGoButton => 'GO!';

  @override
  String get hudNewBest => '★ NEW BEST';

  @override
  String hudBest(String n) {
    return 'BEST $n';
  }

  @override
  String get scoreLabel => 'SCORE';

  @override
  String objectivesSummary(int done, int total) {
    return '$done/$total objectives';
  }

  @override
  String get noScoresYet => 'No scores yet';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardError => 'Error loading leaderboard';

  @override
  String get packStarName => 'Star Pack';

  @override
  String get packCometName => 'Comet Pack';

  @override
  String get packDiamondName => 'Diamond Pack';

  @override
  String get badgeStarter => 'STARTER';

  @override
  String get badgePopular => 'POPULAR';

  @override
  String get badgeBestValue => 'BEST VALUE';

  @override
  String get purchaseSuccess => 'Purchase successful!';

  @override
  String get purchaseError => 'Purchase error';

  @override
  String get purchasesRestored => 'Purchases restored!';

  @override
  String get restoringPurchases => 'Looking for previous purchases…';

  @override
  String get jokerCategoryClassic => 'CLASSIC';

  @override
  String get jokerCategoryPremium => 'PREMIUM';

  @override
  String get noAdsTitle => 'NO ADS + JOKERS';

  @override
  String get badgeOneTimePurchase => '✨ ONE-TIME PURCHASE';

  @override
  String get noAdsDescription => 'Remove all ads!';

  @override
  String get sectionJokerPacks => 'JOKER PACKS';

  @override
  String get sectionFreeJoker => 'FREE JOKER';

  @override
  String get badgeFree => 'FREE';

  @override
  String get freeLabel => 'FREE';

  @override
  String get validateButton => 'CONFIRM';

  @override
  String get rewardLabel => 'Reward: ';

  @override
  String get xpLabel => 'XP';

  @override
  String get dayLabel => 'DAY';

  @override
  String get levelShortLabel => 'LV';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get defaultGuestName => 'Guest';

  @override
  String get okButton => 'OK';

  @override
  String get notifStreakTitle => 'Your streak is at risk!';

  @override
  String get notifStreakBody => 'Play a game to keep your streak alive.';

  @override
  String get notifChannelName => 'Game Streak';

  @override
  String get notifChannelDesc => 'Reminders to keep your game streak active.';

  @override
  String get musicLabel => 'Music';

  @override
  String languageLabel(String lang) {
    return 'LANGUAGE: $lang';
  }

  @override
  String get maxShapesWarning => 'Max 30 shapes';
}
