/// Statut de péremption d'un produit.
enum ExpiryStatus { none, ok, soon, expired }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Nombre de jours entiers entre aujourd'hui et la date de péremption
/// (négatif si déjà périmé). Seule la date compte, pas l'heure.
int daysUntil(DateTime expiry, DateTime now) =>
    _day(expiry).difference(_day(now)).inDays;

/// Classe un produit :
/// - périmé : la date est strictement avant aujourd'hui,
/// - bientôt : de aujourd'hui (jour J inclus) à [soonDays] jours inclus,
/// - ok : au-delà,
/// - none : pas de date.
ExpiryStatus classifyExpiry(DateTime? expiry, DateTime now,
    {int soonDays = 30}) {
  if (expiry == null) return ExpiryStatus.none;
  final d = daysUntil(expiry, now);
  if (d < 0) return ExpiryStatus.expired;
  if (d <= soonDays) return ExpiryStatus.soon;
  return ExpiryStatus.ok;
}
