/// One leave request as returned by the backend.
///
/// `nullable everything` is intentional — the manager-side endpoint
/// returns extra fields ([id], [empname], [emcd], [url]) that the
/// employee-side endpoint omits.
class Leave {
  String? id;
  String? status;
  String? status_date;
  String? leavedate;
  String? leavedateto;
  int? nodays;
  String? notice;
  String? emcd;
  String? url;
  String? empname;
  int? addeddays;
  String? type;
}
