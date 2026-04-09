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
  String get jokerBombDesc => 'Destroys all shapes of the same type and color';

  @override
  String get jokerWildcard => 'Wildcard';

  @override
  String get jokerWildcardDesc => 'Merges with any shape of the same level';

  @override
  String get jokerReducer => 'Reducer';

  @override
  String get jokerReducerDesc => 'Reduces a shape\'s level by 1';

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
}
