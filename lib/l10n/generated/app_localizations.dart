import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shape Merge'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get bestScore;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @shapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get shapes;

  /// No description provided for @merges.
  ///
  /// In en, this message translates to:
  /// **'Merges'**
  String get merges;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Board Capacity'**
  String get capacity;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @boardFull.
  ///
  /// In en, this message translates to:
  /// **'Board full and no possible merge!'**
  String get boardFull;

  /// No description provided for @noPairs.
  ///
  /// In en, this message translates to:
  /// **'No possible merge!'**
  String get noPairs;

  /// No description provided for @boardFullWarning.
  ///
  /// In en, this message translates to:
  /// **'Board full — merge fast!'**
  String get boardFullWarning;

  /// No description provided for @noPairsNewShapes.
  ///
  /// In en, this message translates to:
  /// **'No pairs — new shapes added!'**
  String get noPairsNewShapes;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get replay;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @signInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get signInSuccess;

  /// No description provided for @signInToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your score and see the leaderboard'**
  String get signInToSave;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound On'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound Off'**
  String get soundOff;

  /// No description provided for @musicOn.
  ///
  /// In en, this message translates to:
  /// **'Music On'**
  String get musicOn;

  /// No description provided for @musicOff.
  ///
  /// In en, this message translates to:
  /// **'Music Off'**
  String get musicOff;

  /// No description provided for @jokerBomb.
  ///
  /// In en, this message translates to:
  /// **'Bomb'**
  String get jokerBomb;

  /// No description provided for @jokerBombDesc.
  ///
  /// In en, this message translates to:
  /// **'Targets a shape and destroys all shapes of the same type and color'**
  String get jokerBombDesc;

  /// No description provided for @jokerWildcard.
  ///
  /// In en, this message translates to:
  /// **'Wildcard'**
  String get jokerWildcard;

  /// No description provided for @jokerWildcardDesc.
  ///
  /// In en, this message translates to:
  /// **'Spawns a special shape that merges with any shape of the same level'**
  String get jokerWildcardDesc;

  /// No description provided for @jokerReducer.
  ///
  /// In en, this message translates to:
  /// **'Reducer'**
  String get jokerReducer;

  /// No description provided for @jokerReducerDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduces a shape\'s level by 1. At level 1, it vanishes!'**
  String get jokerReducerDesc;

  /// No description provided for @jokerRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get jokerRadar;

  /// No description provided for @jokerRadarDesc.
  ///
  /// In en, this message translates to:
  /// **'Reveals all possible merges for 5 seconds'**
  String get jokerRadarDesc;

  /// No description provided for @jokerEvolution.
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get jokerEvolution;

  /// No description provided for @jokerEvolutionDesc.
  ///
  /// In en, this message translates to:
  /// **'Increases a shape\'s level by +1 without merging'**
  String get jokerEvolutionDesc;

  /// No description provided for @jokerMegaBomb.
  ///
  /// In en, this message translates to:
  /// **'Mega Bomb'**
  String get jokerMegaBomb;

  /// No description provided for @jokerMegaBombDesc.
  ///
  /// In en, this message translates to:
  /// **'Destroys all shapes of the same level, regardless of type'**
  String get jokerMegaBombDesc;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Drag a shape onto an identical one to merge them and score points!'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Your Jokers'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Use your jokers to destroy, transform or reveal merges!'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Watch Out!'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'The board fills up with each move. No space left = Game Over!'**
  String get onboardingDesc3;

  /// No description provided for @startPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start Playing'**
  String get startPlaying;

  /// No description provided for @skipTutorial.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipTutorial;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @packSmall.
  ///
  /// In en, this message translates to:
  /// **'Small Pack'**
  String get packSmall;

  /// No description provided for @packMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Pack'**
  String get packMedium;

  /// No description provided for @packLarge.
  ///
  /// In en, this message translates to:
  /// **'Large Pack'**
  String get packLarge;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an Ad'**
  String get watchAd;

  /// No description provided for @watchAdReward.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get +1 joker of your choice'**
  String get watchAdReward;

  /// No description provided for @adNotReady.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready yet, try again in a moment'**
  String get adNotReady;

  /// No description provided for @chooseJoker.
  ///
  /// In en, this message translates to:
  /// **'Choose a joker to recharge'**
  String get chooseJoker;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'Max Level'**
  String get maxLevel;

  /// No description provided for @fusionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} merges'**
  String fusionsCount(int count);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record!'**
  String get newRecord;

  /// No description provided for @classicMode.
  ///
  /// In en, this message translates to:
  /// **'Classic Mode'**
  String get classicMode;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose your avatar'**
  String get chooseAvatar;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirm;

  /// No description provided for @streakDay.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String streakDay(int n);

  /// No description provided for @streakConnectedToday.
  ///
  /// In en, this message translates to:
  /// **'Daily login validated!'**
  String get streakConnectedToday;

  /// No description provided for @streakBroken.
  ///
  /// In en, this message translates to:
  /// **'Streak broken'**
  String get streakBroken;

  /// No description provided for @streakBrokenDesc.
  ///
  /// In en, this message translates to:
  /// **'Your streak was interrupted…'**
  String get streakBrokenDesc;

  /// No description provided for @streakSaveNudge.
  ///
  /// In en, this message translates to:
  /// **'Sign in to never lose your streak.'**
  String get streakSaveNudge;

  /// No description provided for @streakCollect.
  ///
  /// In en, this message translates to:
  /// **'Already collected'**
  String get streakCollect;

  /// No description provided for @streakLost.
  ///
  /// In en, this message translates to:
  /// **'Streak lost'**
  String get streakLost;

  /// No description provided for @streakLostDesc.
  ///
  /// In en, this message translates to:
  /// **'Come back every day to earn\nbetter bonuses.'**
  String get streakLostDesc;

  /// No description provided for @dailyObjectivesTitle.
  ///
  /// In en, this message translates to:
  /// **'DAILY GOALS'**
  String get dailyObjectivesTitle;

  /// No description provided for @objectiveFusions.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Make 1 merge} other{Make {n} merges}}'**
  String objectiveFusions(int n);

  /// No description provided for @objectiveScore.
  ///
  /// In en, this message translates to:
  /// **'Reach a score of {n}'**
  String objectiveScore(int n);

  /// No description provided for @objectiveParties.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Play 1 game} other{Play {n} games}}'**
  String objectiveParties(int n);

  /// No description provided for @objectiveFormeMax.
  ///
  /// In en, this message translates to:
  /// **'Reach shape rank {n}'**
  String objectiveFormeMax(int n);

  /// No description provided for @objectiveJokersUses.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Use 1 joker} other{Use {n} jokers}}'**
  String objectiveJokersUses(int n);

  /// No description provided for @objectiveBonusAll.
  ///
  /// In en, this message translates to:
  /// **'Complete all bonus'**
  String get objectiveBonusAll;

  /// No description provided for @objectiveCompleted.
  ///
  /// In en, this message translates to:
  /// **'Objective completed!'**
  String get objectiveCompleted;

  /// No description provided for @collectReward.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collectReward;

  /// No description provided for @rewardReceived.
  ///
  /// In en, this message translates to:
  /// **'Reward received!'**
  String get rewardReceived;

  /// No description provided for @allObjectivesCompleted.
  ///
  /// In en, this message translates to:
  /// **'All objectives completed!'**
  String get allObjectivesCompleted;

  /// No description provided for @levelBadge.
  ///
  /// In en, this message translates to:
  /// **'Lv'**
  String get levelBadge;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {n}!'**
  String levelUp(int n);

  /// No description provided for @xpGained.
  ///
  /// In en, this message translates to:
  /// **'+{n} XP'**
  String xpGained(int n);

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{n} XP to level {lv}'**
  String xpToNextLevel(int n, int lv);

  /// No description provided for @connectToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save progress'**
  String get connectToSave;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get deleteAccountConfirm;

  /// No description provided for @tutorialObjectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'OBJECTIVE'**
  String get tutorialObjectiveLabel;

  /// No description provided for @tutorialObjectiveText.
  ///
  /// In en, this message translates to:
  /// **'Merge identical shapes (same shape + same color + same level) to level up and reach the highest score!'**
  String get tutorialObjectiveText;

  /// No description provided for @tutorialControlsLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTROLS'**
  String get tutorialControlsLabel;

  /// No description provided for @tutorialControlsText.
  ///
  /// In en, this message translates to:
  /// **'Drag a shape onto an identical shape to merge. If no match, it snaps back.'**
  String get tutorialControlsText;

  /// No description provided for @tutorialJokersLabel.
  ///
  /// In en, this message translates to:
  /// **'JOKERS'**
  String get tutorialJokersLabel;

  /// No description provided for @tutorialClassicLabel.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get tutorialClassicLabel;

  /// No description provided for @tutorialPremiumLabel.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get tutorialPremiumLabel;

  /// No description provided for @tutorialGameOverLabel.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get tutorialGameOverLabel;

  /// No description provided for @tutorialGameOverText.
  ///
  /// In en, this message translates to:
  /// **'The board fills up with each move. No space + no possible merges = Game Over!'**
  String get tutorialGameOverText;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'SHAPE MERGE 2048'**
  String get tutorialTitle;

  /// No description provided for @tutorialGoButton.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get tutorialGoButton;

  /// No description provided for @hudNewBest.
  ///
  /// In en, this message translates to:
  /// **'★ NEW BEST'**
  String get hudNewBest;

  /// No description provided for @hudBest.
  ///
  /// In en, this message translates to:
  /// **'BEST {n}'**
  String hudBest(String n);

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get scoreLabel;

  /// No description provided for @objectivesSummary.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} objectives'**
  String objectivesSummary(int done, int total);

  /// No description provided for @noScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet'**
  String get noScoresYet;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardError.
  ///
  /// In en, this message translates to:
  /// **'Error loading leaderboard'**
  String get leaderboardError;

  /// No description provided for @packStarName.
  ///
  /// In en, this message translates to:
  /// **'Star Pack'**
  String get packStarName;

  /// No description provided for @packCometName.
  ///
  /// In en, this message translates to:
  /// **'Comet Pack'**
  String get packCometName;

  /// No description provided for @packDiamondName.
  ///
  /// In en, this message translates to:
  /// **'Diamond Pack'**
  String get packDiamondName;

  /// No description provided for @badgeStarter.
  ///
  /// In en, this message translates to:
  /// **'STARTER'**
  String get badgeStarter;

  /// No description provided for @badgePopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get badgePopular;

  /// No description provided for @badgeBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get badgeBestValue;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful!'**
  String get purchaseSuccess;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase error'**
  String get purchaseError;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored!'**
  String get purchasesRestored;

  /// No description provided for @restoringPurchases.
  ///
  /// In en, this message translates to:
  /// **'Looking for previous purchases…'**
  String get restoringPurchases;

  /// No description provided for @jokerCategoryClassic.
  ///
  /// In en, this message translates to:
  /// **'CLASSIC'**
  String get jokerCategoryClassic;

  /// No description provided for @jokerCategoryPremium.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get jokerCategoryPremium;

  /// No description provided for @noAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'NO ADS + JOKERS'**
  String get noAdsTitle;

  /// No description provided for @badgeOneTimePurchase.
  ///
  /// In en, this message translates to:
  /// **'✨ ONE-TIME PURCHASE'**
  String get badgeOneTimePurchase;

  /// No description provided for @noAdsDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads!'**
  String get noAdsDescription;

  /// No description provided for @sectionJokerPacks.
  ///
  /// In en, this message translates to:
  /// **'JOKER PACKS'**
  String get sectionJokerPacks;

  /// No description provided for @sectionFreeJoker.
  ///
  /// In en, this message translates to:
  /// **'FREE JOKER'**
  String get sectionFreeJoker;

  /// No description provided for @badgeFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get badgeFree;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeLabel;

  /// No description provided for @validateButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get validateButton;

  /// No description provided for @rewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward: '**
  String get rewardLabel;

  /// No description provided for @rewardAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to your inventory!'**
  String get rewardAdded;

  /// No description provided for @xpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get dayLabel;

  /// No description provided for @levelShortLabel.
  ///
  /// In en, this message translates to:
  /// **'LV'**
  String get levelShortLabel;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// No description provided for @defaultGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get defaultGuestName;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @notifStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak is at risk!'**
  String get notifStreakTitle;

  /// No description provided for @notifStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Play a game to keep your streak alive.'**
  String get notifStreakBody;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Game Streak'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders to keep your game streak active.'**
  String get notifChannelDesc;

  /// No description provided for @musicLabel.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get musicLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE: {lang}'**
  String languageLabel(String lang);

  /// No description provided for @maxShapesWarning.
  ///
  /// In en, this message translates to:
  /// **'Max 30 shapes'**
  String get maxShapesWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
