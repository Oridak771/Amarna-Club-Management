import 'package:intl/intl.dart';

/// Conversions between the device's local clock and Odoo's storage format.
///
/// Odoo stores every `Datetime` as a naive UTC string ("2026-11-16 08:30:00")
/// and every `Date` as a calendar day ("2026-11-16"). The app works in local
/// time, so values are converted at this boundary only.
final DateFormat _odooDateTime = DateFormat('yyyy-MM-dd HH:mm:ss');
final DateFormat _odooDate = DateFormat('yyyy-MM-dd');

/// Local [DateTime] -> Odoo Datetime string (UTC).
String toOdooDateTime(DateTime local) => _odooDateTime.format(local.toUtc());

/// Odoo Datetime string (UTC) -> local [DateTime]. Null when empty/invalid.
DateTime? fromOdooDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z');
  return parsed?.toLocal();
}

/// Calendar day -> Odoo Date string (no time part, no zone).
String toOdooDate(DateTime day) => _odooDate.format(day);

/// Odoo Date string -> local midnight of that day. Null when empty/invalid.
DateTime? fromOdooDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Start (local midnight) and end (exclusive) of the local day containing
/// [day], expressed as Odoo UTC Datetime strings for domain filters.
(String, String) odooDayBounds(DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return (toOdooDateTime(start), toOdooDateTime(end));
}
