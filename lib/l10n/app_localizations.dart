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
  /// **'Sign In'**
  String get login;

  /// No description provided for @shubra.
  ///
  /// In en, this message translates to:
  /// **'Shubra Al-Taif Company'**
  String get shubra;

  /// No description provided for @updateinfo.
  ///
  /// In en, this message translates to:
  /// **'Update Personal Information'**
  String get updateinfo;

  /// No description provided for @requestloan.
  ///
  /// In en, this message translates to:
  /// **'Loan Request'**
  String get requestloan;

  /// No description provided for @prevloan.
  ///
  /// In en, this message translates to:
  /// **'Previous Loan Records'**
  String get prevloan;

  /// No description provided for @deliveredloan.
  ///
  /// In en, this message translates to:
  /// **'Received Loans'**
  String get deliveredloan;

  /// No description provided for @requestleave.
  ///
  /// In en, this message translates to:
  /// **'Submit Leave Request'**
  String get requestleave;

  /// No description provided for @leaverequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Records'**
  String get leaverequests;

  /// No description provided for @loanrequests.
  ///
  /// In en, this message translates to:
  /// **'Loan Requests'**
  String get loanrequests;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Submit a Suggestion or Complaint'**
  String get complaint;

  /// No description provided for @moves.
  ///
  /// In en, this message translates to:
  /// **'Monthly Transactions'**
  String get moves;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave Request'**
  String get leave;

  /// No description provided for @custody.
  ///
  /// In en, this message translates to:
  /// **'Registered Custody'**
  String get custody;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Annual Performance Review'**
  String get rate;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @myinfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get myinfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @empcode.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get empcode;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobile;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager'**
  String get manager;

  /// No description provided for @addnoti.
  ///
  /// In en, this message translates to:
  /// **'Send Notification to Employees'**
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
  /// **'Leave Balance'**
  String get vacbal;

  /// No description provided for @addedays.
  ///
  /// In en, this message translates to:
  /// **'Added Days'**
  String get addedays;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication Code'**
  String get otp;

  /// No description provided for @resendotp.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
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
  /// **'Please select the leave start and end dates'**
  String get selectrange;

  /// No description provided for @notoday.
  ///
  /// In en, this message translates to:
  /// **'Leave cannot be requested for today or a previous date'**
  String get notoday;

  /// No description provided for @invalidfile.
  ///
  /// In en, this message translates to:
  /// **'Please attach a valid file'**
  String get invalidfile;

  /// No description provided for @nobalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient leave balance'**
  String get nobalance;

  /// No description provided for @minimum5.
  ///
  /// In en, this message translates to:
  /// **'The minimum duration for an external leave is five days'**
  String get minimum5;

  /// No description provided for @morahalavac.
  ///
  /// In en, this message translates to:
  /// **'This employee already has an active transferred leave'**
  String get morahalavac;

  /// No description provided for @iqamaend.
  ///
  /// In en, this message translates to:
  /// **'The return date exceeds the Iqama expiry date'**
  String get iqamaend;

  /// No description provided for @third.
  ///
  /// In en, this message translates to:
  /// **'Third Quarter'**
  String get third;

  /// No description provided for @noaccepttoday.
  ///
  /// In en, this message translates to:
  /// **'Leave cannot be approved for today or a previous date'**
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
  /// **'Basic Salary'**
  String get basicsal;

  /// No description provided for @addsal.
  ///
  /// In en, this message translates to:
  /// **'Additional Salary'**
  String get addsal;

  /// No description provided for @notovac.
  ///
  /// In en, this message translates to:
  /// **'Two overlapping leave requests cannot be submitted for the same period'**
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
  /// **'Medical Insurance'**
  String get insurance;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @compreg.
  ///
  /// In en, this message translates to:
  /// **'Submit a Suggestion or Complaint'**
  String get compreg;

  /// No description provided for @compadd.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get compadd;

  /// No description provided for @entercompadd.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get entercompadd;

  /// No description provided for @entercompdesc.
  ///
  /// In en, this message translates to:
  /// **'Please enter the details'**
  String get entercompdesc;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get description;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully'**
  String get sent;

  /// No description provided for @notsent.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit the request'**
  String get notsent;

  /// No description provided for @nodata.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get nodata;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @enterempcode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the employee ID'**
  String get enterempcode;

  /// No description provided for @movetype.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get movetype;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Reference Code'**
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
  /// **'Human Resources Evaluation'**
  String get grdhr;

  /// No description provided for @grdmdm.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager Evaluation'**
  String get grdmdm;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get send;

  /// No description provided for @hbd.
  ///
  /// In en, this message translates to:
  /// **'Warmest wishes on your birthday,'**
  String get hbd;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @vactype.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get vactype;

  /// No description provided for @enteriqama.
  ///
  /// In en, this message translates to:
  /// **'Please enter the National ID or Iqama number'**
  String get enteriqama;

  /// No description provided for @iqama.
  ///
  /// In en, this message translates to:
  /// **'National ID / Iqama'**
  String get iqama;

  /// No description provided for @totdays.
  ///
  /// In en, this message translates to:
  /// **'Maximum allowed days:'**
  String get totdays;

  /// No description provided for @nodays.
  ///
  /// In en, this message translates to:
  /// **'Number of Days'**
  String get nodays;

  /// No description provided for @leavedate.
  ///
  /// In en, this message translates to:
  /// **'Leave Date'**
  String get leavedate;

  /// No description provided for @statusdate.
  ///
  /// In en, this message translates to:
  /// **'Decision Date'**
  String get statusdate;

  /// No description provided for @newaccountreg.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get newaccountreg;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterpassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterpassword;

  /// No description provided for @failednewreg.
  ///
  /// In en, this message translates to:
  /// **'Account creation failed'**
  String get failednewreg;

  /// No description provided for @signinmgr.
  ///
  /// In en, this message translates to:
  /// **'Manager Sign In'**
  String get signinmgr;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registermgr.
  ///
  /// In en, this message translates to:
  /// **'Create Manager Account'**
  String get registermgr;

  /// No description provided for @wronginfo.
  ///
  /// In en, this message translates to:
  /// **'The entered information is incorrect'**
  String get wronginfo;

  /// No description provided for @entervactype.
  ///
  /// In en, this message translates to:
  /// **'Please select the leave type'**
  String get entervactype;

  /// No description provided for @entermobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get entermobile;

  /// No description provided for @enteremail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enteremail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
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
  /// **'Maternity Leave'**
  String get childvac;

  /// No description provided for @hajjvac.
  ///
  /// In en, this message translates to:
  /// **'Hajj Leave'**
  String get hajjvac;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get accepted;

  /// No description provided for @refused.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get refused;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get pending;

  /// No description provided for @enterdate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get enterdate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attach;

  /// No description provided for @enternodays.
  ///
  /// In en, this message translates to:
  /// **'Please enter the number of days'**
  String get enternodays;

  /// No description provided for @enternote.
  ///
  /// In en, this message translates to:
  /// **'Please enter a note'**
  String get enternote;

  /// No description provided for @enteramount.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount'**
  String get enteramount;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get paid;

  /// No description provided for @internet.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the server'**
  String get internet;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Please select the evaluation year'**
  String get year;

  /// No description provided for @attendanceLog.
  ///
  /// In en, this message translates to:
  /// **'Attendance Log'**
  String get attendanceLog;

  /// No description provided for @attendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily fingerprint records'**
  String get attendanceSubtitle;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get checkOut;

  /// No description provided for @noCheckIn.
  ///
  /// In en, this message translates to:
  /// **'No check-in'**
  String get noCheckIn;

  /// No description provided for @noCheckOut.
  ///
  /// In en, this message translates to:
  /// **'No check-out'**
  String get noCheckOut;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @allRecords.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get allRecords;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @filterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get filterYear;

  /// No description provided for @noAttendance.
  ///
  /// In en, this message translates to:
  /// **'No attendance records for this month'**
  String get noAttendance;

  /// No description provided for @salaryDetails.
  ///
  /// In en, this message translates to:
  /// **'Salary Details'**
  String get salaryDetails;

  /// No description provided for @salarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your full monthly breakdown'**
  String get salarySubtitle;

  /// No description provided for @netSalary.
  ///
  /// In en, this message translates to:
  /// **'Net Salary'**
  String get netSalary;

  /// No description provided for @allowances.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowances;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductions;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalAllowances.
  ///
  /// In en, this message translates to:
  /// **'Total Allowances'**
  String get totalAllowances;

  /// No description provided for @totalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total Deductions'**
  String get totalDeductions;

  /// No description provided for @noSalaryData.
  ///
  /// In en, this message translates to:
  /// **'Salary details are not available right now'**
  String get noSalaryData;

  /// No description provided for @digitalCard.
  ///
  /// In en, this message translates to:
  /// **'Digital Card'**
  String get digitalCard;

  /// No description provided for @digitalCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your digital employee badge'**
  String get digitalCardSubtitle;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get shareCard;

  /// No description provided for @noCardData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your card right now'**
  String get noCardData;

  /// No description provided for @shareCardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the card'**
  String get shareCardFailed;

  /// No description provided for @colleagues.
  ///
  /// In en, this message translates to:
  /// **'Manager & Colleagues'**
  String get colleagues;

  /// No description provided for @colleaguesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your direct manager and team'**
  String get colleaguesSubtitle;

  /// No description provided for @directManager.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager'**
  String get directManager;

  /// No description provided for @colleaguesCount.
  ///
  /// In en, this message translates to:
  /// **'Colleagues ({count})'**
  String colleaguesCount(int count);

  /// No description provided for @noColleagues.
  ///
  /// In en, this message translates to:
  /// **'You have no colleagues under the same manager'**
  String get noColleagues;

  /// No description provided for @noManager.
  ///
  /// In en, this message translates to:
  /// **'No direct manager assigned'**
  String get noManager;

  /// No description provided for @callBtn.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callBtn;

  /// No description provided for @emailBtn.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailBtn;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the call'**
  String get callFailed;

  /// No description provided for @emailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the email app'**
  String get emailFailed;
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
