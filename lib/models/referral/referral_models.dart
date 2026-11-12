num _num(Object? v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
String _str(Object? v) => v?.toString().trim() ?? '';

/// `referrals/earnings/detailed_stats/` (API ref R2).
///
/// Real response (Oct 2026): `sharing_link` is a plain URL string,
/// `tier_progress` is `{gold|platinum|diamond: {unlocked, requirement}}` and
/// PDI numbers come along under `pdi`.
class ReferralStats {
  const ReferralStats({
    required this.referralCode,
    required this.tier,
    required this.tierProgress,
    required this.nextTierHint,
    required this.totalReferred,
    required this.activeReferred,
    required this.totalEarned,
    required this.availableBalance,
    required this.pendingEarnings,
    required this.links,
    this.pdi,
  });

  final String referralCode;
  final String tier;

  /// 0–100
  final num tierProgress;

  /// What unlocks the next tier, e.g. "3 Sell Listings + 1 Buy Request".
  final String nextTierHint;
  final int totalReferred;
  final int activeReferred;
  final num totalEarned;
  final num availableBalance;
  final num pendingEarnings;

  /// label → url (invite, sell, rent, listings, inspection).
  final Map<String, String> links;
  final PdiReferralStats? pdi;

  static const _tiers = ['gold', 'platinum', 'diamond'];
  static const _host = 'https://housypoint.com';

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map? ?? const {};
    final earnings = json['earnings'] as Map? ?? const {};
    final code = _str(json['referral_code']);
    final tierRaw = _str(json['tier_display']).isNotEmpty
        ? _str(json['tier_display'])
        : _str(json['tier']);

    // Progress = share of tiers unlocked; hint = first locked tier's requirement.
    num progress = 0;
    var hint = '';
    final tp = json['tier_progress'];
    if (tp is Map) {
      final unlocked = _tiers.where((t) => (tp[t] as Map?)?['unlocked'] == true).length;
      progress = unlocked / _tiers.length * 100;
      for (final t in _tiers) {
        final info = tp[t] as Map?;
        if (info != null && info['unlocked'] != true) {
          hint = '${t[0].toUpperCase()}${t.substring(1)}: ${_str(info['requirement'])}';
          break;
        }
      }
    } else {
      progress = _num(tp);
    }

    final links = <String, String>{};
    final sharing = json['sharing_link'];
    if (sharing is String && sharing.isNotEmpty) {
      links['Invite to Housy Point'] = sharing;
    } else if (sharing is Map) {
      if (_str(sharing['main']).isNotEmpty) links['Invite to Housy Point'] = _str(sharing['main']);
    }
    if (code.isNotEmpty) {
      // Same deep links V1 built from the code.
      links.putIfAbsent('Invite to Housy Point', () => '$_host/?ref=$code');
      links['Sell a property'] = '$_host/add-property/?ref=$code';
      links['Rent out a property'] = '$_host/add-rent-property/?ref=$code';
      links['Browse listings'] = '$_host/listings/?ref=$code';
      links['Book a home inspection'] = '$_host/pdi_service_page/?ref=$code';
    }

    final pdi = json['pdi'];
    return ReferralStats(
      referralCode: code,
      tier: tierRaw.isEmpty ? 'Gold Partner' : tierRaw[0].toUpperCase() + tierRaw.substring(1),
      tierProgress: progress,
      nextTierHint: hint,
      totalReferred: _num(users['total_referred']).toInt(),
      activeReferred: _num(users['active_referred']).toInt(),
      totalEarned: _num(earnings['total_earned']),
      availableBalance: _num(earnings['available_balance']),
      pendingEarnings: _num(earnings['pending_earnings']),
      links: links,
      pdi: pdi is Map ? PdiReferralStats.fromJson(Map<String, dynamic>.from(pdi)) : null,
    );
  }
}

/// `referrals/pdi-stats` (R3).
class PdiReferralStats {
  const PdiReferralStats({required this.bookings, required this.earnings, required this.pending});

  final int bookings;
  final num earnings;
  final num pending;

  /// Accepts both the `pdi-stats` keys and the nested `pdi` block of R2.
  factory PdiReferralStats.fromJson(Map<String, dynamic> json) => PdiReferralStats(
    bookings: _num(json['pdi_bookings_count'] ?? json['bookings_count']).toInt(),
    earnings: _num(json['pdi_earnings'] ?? json['earnings']),
    pending: _num(json['pdi_pending'] ?? json['pending']),
  );
}

/// One row of `referrals/earnings/earnings_history` (R4).
class ReferralEarning {
  const ReferralEarning({
    required this.amount,
    required this.type,
    required this.description,
    required this.status,
    this.createdAt,
  });

  final num amount;
  final String type;
  final String description;
  final String status;
  final DateTime? createdAt;

  factory ReferralEarning.fromJson(Map<String, dynamic> json) => ReferralEarning(
    amount: _num(json['amount']),
    type: _str(json['earning_type_display']).isNotEmpty
        ? _str(json['earning_type_display'])
        : _str(json['earning_type']),
    description: _str(json['description']),
    status: _str(json['status_display']).isNotEmpty
        ? _str(json['status_display'])
        : _str(json['status']),
    createdAt: DateTime.tryParse(_str(json['created_at'])),
  );
}

/// One row of `referrals/withdrawals` (R5).
class Withdrawal {
  const Withdrawal({required this.amount, required this.accountName, required this.status, this.createdAt});

  final num amount;
  final String accountName;
  final String status;
  final DateTime? createdAt;

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
    amount: _num(json['amount']),
    accountName: _str(json['account_name']),
    status: _str(json['status_display']).isNotEmpty
        ? _str(json['status_display'])
        : _str(json['status']),
    createdAt: DateTime.tryParse(_str(json['created_at'])),
  );
}

/// One row of `referrals/referred-users/detailed` (R7).
class ReferredUser {
  const ReferredUser({required this.name, this.joinedAt, this.isActive = false});

  final String name;
  final DateTime? joinedAt;
  final bool isActive;

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    final name = _str(json['full_name']).isNotEmpty
        ? _str(json['full_name'])
        : '${_str(json['first_name'])} ${_str(json['last_name'])}'.trim();
    return ReferredUser(
      name: name.isEmpty ? 'Housy Point user' : name,
      joinedAt: DateTime.tryParse(_str(json['date_joined'])),
      isActive: json['is_active'] == true,
    );
  }
}
