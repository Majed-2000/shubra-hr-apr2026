import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @shubra.
  ///
  /// In en, this message translates to:
  /// **'Shubra Al-Taif'**
  String get shubra;

  /// No description provided for @updateinfo.
  ///
  /// In en, this message translates to:
  /// **'Update Info'**
  String get updateinfo;

  /// No description provided for @requestloan.
  ///
  /// In en, this message translates to:
  /// **'Request Loan'**
  String get requestloan;

  /// No description provided for @prevloan.
  ///
  /// In en, this message translates to:
  /// **'Received Loan Requests'**
  String get prevloan;

  /// No description provided for @deliveredloan.
  ///
  /// In en, this message translates to:
  /// **'Loan Requests'**
  String get deliveredloan;

  /// No description provided for @requestleave.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get requestleave;

  /// No description provided for @leaverequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get leaverequests;

  /// No description provided for @loanrequests.
  ///
  /// In en, this message translates to:
  /// **'Loan Requests'**
  String get loanrequests;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Suggestion / Complaint'**
  String get complaint;

  /// No description provided for @moves.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get moves;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'request Leave'**
  String get leave;

  /// No description provided for @custody.
  ///
  /// In en, this message translates to:
  /// **'Registered Custody'**
  String get custody;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rate;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @myinfo.
  ///
  /// In en, this message translates to:
  /// **'Your Personal Info'**
  String get myinfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @empcode.
  ///
  /// In en, this message translates to:
  /// **'Employee Code'**
  String get empcode;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobile;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get manager;

  /// No description provided for @addnoti.
  ///
  /// In en, this message translates to:
  /// **'Add Notifications to Employees'**
  String get addnoti;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications Center'**
  String get notifications;

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'First Quarter'**
  String get first;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'Second Quarter'**
  String get second;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @vacbal.
  ///
  /// In en, this message translates to:
  /// **'Vacation balance'**
  String get vacbal;

  /// No description provided for @addedays.
  ///
  /// In en, this message translates to:
  /// **'Added Days'**
  String get addedays;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @resendotp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in'**
  String get resendotp;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @veriy.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get veriy;

  /// No description provided for @selectrange.
  ///
  /// In en, this message translates to:
  /// **'Please select vacation date and end date'**
  String get selectrange;

  /// No description provided for @notoday.
  ///
  /// In en, this message translates to:
  /// **'You cannot request leave for today or a previous day'**
  String get notoday;

  /// No description provided for @invalidfile.
  ///
  /// In en, this message translates to:
  /// **'Please attach an image'**
  String get invalidfile;

  /// No description provided for @nobalance.
  ///
  /// In en, this message translates to:
  /// **'Your vacation balance is insufficient'**
  String get nobalance;

  /// No description provided for @minimum5.
  ///
  /// In en, this message translates to:
  /// **'Minumum Days for this type is 5'**
  String get minimum5;

  /// No description provided for @morahalavac.
  ///
  /// In en, this message translates to:
  /// **'This Emp has active vacation'**
  String get morahalavac;

  /// No description provided for @iqamaend.
  ///
  /// In en, this message translates to:
  /// **'Sorry , Return date is bigger than Iqama Date'**
  String get iqamaend;

  /// No description provided for @third.
  ///
  /// In en, this message translates to:
  /// **'Third Quarter'**
  String get third;

  /// No description provided for @noaccepttoday.
  ///
  /// In en, this message translates to:
  /// **'You cannot accept leave for today or previous date'**
  String get noaccepttoday;

  /// No description provided for @fourth.
  ///
  /// In en, this message translates to:
  /// **'Fourth Quarter'**
  String get fourth;

  /// No description provided for @bankno.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number'**
  String get bankno;

  /// No description provided for @basicsal.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get basicsal;

  /// No description provided for @addsal.
  ///
  /// In en, this message translates to:
  /// **'Additional Salary'**
  String get addsal;

  /// No description provided for @notovac.
  ///
  /// In en, this message translates to:
  /// **'You cannot request two leaved in same period'**
  String get notovac;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transportation Allowance'**
  String get transport;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing Allowance'**
  String get housing;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN Number'**
  String get iban;

  /// No description provided for @compreg.
  ///
  /// In en, this message translates to:
  /// **'Suggestion / Complaint'**
  String get compreg;

  /// No description provided for @compadd.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get compadd;

  /// No description provided for @entercompadd.
  ///
  /// In en, this message translates to:
  /// **'Enter Title'**
  String get entercompadd;

  /// No description provided for @entercompdesc.
  ///
  /// In en, this message translates to:
  /// **'Enter Details'**
  String get entercompdesc;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get description;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent Successfully'**
  String get sent;

  /// No description provided for @notsent.
  ///
  /// In en, this message translates to:
  /// **'Failed to Send Request'**
  String get notsent;

  /// No description provided for @nodata.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get nodata;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @enterempcode.
  ///
  /// In en, this message translates to:
  /// **'Enter Employee Code'**
  String get enterempcode;

  /// No description provided for @movetype.
  ///
  /// In en, this message translates to:
  /// **'Move Type'**
  String get movetype;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @riyal.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get riyal;

  /// No description provided for @grdgm.
  ///
  /// In en, this message translates to:
  /// **'Executive Manager Evaluation'**
  String get grdgm;

  /// No description provided for @grdhr.
  ///
  /// In en, this message translates to:
  /// **'HR Evaluation'**
  String get grdhr;

  /// No description provided for @grdmdm.
  ///
  /// In en, this message translates to:
  /// **'General Manager Evaluation'**
  String get grdmdm;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @hbd.
  ///
  /// In en, this message translates to:
  /// **'Happy Birthday'**
  String get hbd;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @vactype.
  ///
  /// In en, this message translates to:
  /// **'Vacation Type'**
  String get vactype;

  /// No description provided for @enteriqama.
  ///
  /// In en, this message translates to:
  /// **'Please enter National ID / iqama number'**
  String get enteriqama;

  /// No description provided for @iqama.
  ///
  /// In en, this message translates to:
  /// **'National ID / Iqama Number'**
  String get iqama;

  /// No description provided for @totdays.
  ///
  /// In en, this message translates to:
  /// **'Maximum Vacation days is'**
  String get totdays;

  /// No description provided for @nodays.
  ///
  /// In en, this message translates to:
  /// **'No. of Days'**
  String get nodays;

  /// No description provided for @leavedate.
  ///
  /// In en, this message translates to:
  /// **'Leave Date'**
  String get leavedate;

  /// No description provided for @statusdate.
  ///
  /// In en, this message translates to:
  /// **'Status Date'**
  String get statusdate;

  /// No description provided for @newaccountreg.
  ///
  /// In en, this message translates to:
  /// **'New Account Registeration'**
  String get newaccountreg;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterpassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Password'**
  String get enterpassword;

  /// No description provided for @failednewreg.
  ///
  /// In en, this message translates to:
  /// **'Failed Registering Account'**
  String get failednewreg;

  /// No description provided for @signinmgr.
  ///
  /// In en, this message translates to:
  /// **'Sign In Manager'**
  String get signinmgr;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registermgr.
  ///
  /// In en, this message translates to:
  /// **'Manager Account Registeration'**
  String get registermgr;

  /// No description provided for @wronginfo.
  ///
  /// In en, this message translates to:
  /// **'Wrong Information'**
  String get wronginfo;

  /// No description provided for @entervactype.
  ///
  /// In en, this message translates to:
  /// **'Enter vacation type'**
  String get entervactype;

  /// No description provided for @entermobile.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Mobile Number'**
  String get entermobile;

  /// No description provided for @enteremail.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Valid Email'**
  String get enteremail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @invac.
  ///
  /// In en, this message translates to:
  /// **'Internal Leave'**
  String get invac;

  /// No description provided for @outvac.
  ///
  /// In en, this message translates to:
  /// **'External Leave'**
  String get outvac;

  /// No description provided for @dievac.
  ///
  /// In en, this message translates to:
  /// **'Bereavement Leave'**
  String get dievac;

  /// No description provided for @marryvac.
  ///
  /// In en, this message translates to:
  /// **'Marriage Leave'**
  String get marryvac;

  /// No description provided for @childvac.
  ///
  /// In en, this message translates to:
  /// **'Newborn Leave'**
  String get childvac;

  /// No description provided for @hajjvac.
  ///
  /// In en, this message translates to:
  /// **'Hajj Leave'**
  String get hajjvac;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @refused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get refused;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @enterdate.
  ///
  /// In en, this message translates to:
  /// **'Enter Date'**
  String get enterdate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attachement'**
  String get attach;

  /// No description provided for @enternodays.
  ///
  /// In en, this message translates to:
  /// **'Enter No. of Days'**
  String get enternodays;

  /// No description provided for @enternote.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Note'**
  String get enternote;

  /// No description provided for @enteramount.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Amount'**
  String get enteramount;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @internet.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get internet;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Year'**
  String get year;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
