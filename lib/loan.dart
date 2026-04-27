/// One loan request as returned by the backend. Manager view fills [id],
/// [empname], and [emcd]; employee view leaves them null.
class Loan {
  String? id;
  String? status;
  String? status_date;
  String? loandate;
  int? loanamount;
  String? notice;
  String? emcd;
  String? empname;
}
