class MonetizationPeriodStats {
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int views;
  final int likes;
  final int score;
  final int totalScore;
  final int pool;
  final int estimatedAmount;

  MonetizationPeriodStats({
    this.periodStart,
    this.periodEnd,
    this.views = 0,
    this.likes = 0,
    this.score = 0,
    this.totalScore = 0,
    this.pool = 0,
    this.estimatedAmount = 0,
  });

  factory MonetizationPeriodStats.fromJson(Map<String, dynamic> json) {
    return MonetizationPeriodStats(
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : null,
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : null,
      views: (json['views'] ?? 0) as int,
      likes: (json['likes'] ?? 0) as int,
      score: (json['score'] ?? 0) as int,
      totalScore: (json['total_score'] ?? 0) as int,
      pool: (json['pool'] ?? 0) as int,
      estimatedAmount: (json['estimated_amount'] ?? 0) as int,
    );
  }
}

class MonetizationOverview {
  final MonetizationPeriodStats creatorFund;
  final MonetizationPeriodStats adRevenue;
  final int totalCreatorFund;
  final int totalAdRevenue;

  MonetizationOverview({
    required this.creatorFund,
    required this.adRevenue,
    required this.totalCreatorFund,
    required this.totalAdRevenue,
  });

  factory MonetizationOverview.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] ?? {};
    return MonetizationOverview(
      creatorFund: MonetizationPeriodStats.fromJson(json['creator_fund'] ?? {}),
      adRevenue: MonetizationPeriodStats.fromJson(json['ad_revenue'] ?? {}),
      totalCreatorFund: (totals['creator_fund'] ?? 0) as int,
      totalAdRevenue: (totals['ad_revenue'] ?? 0) as int,
    );
  }
}

class MonetizationPayout {
  final int id;
  final String type;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int amount;
  final int views;
  final int likes;
  final int score;
  final int totalScore;
  final String status;
  final DateTime? processedAt;

  MonetizationPayout({
    required this.id,
    required this.type,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
    required this.views,
    required this.likes,
    required this.score,
    required this.totalScore,
    required this.status,
    this.processedAt,
  });

  factory MonetizationPayout.fromJson(Map<String, dynamic> json) {
    return MonetizationPayout(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'])
          : DateTime.now(),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : DateTime.now(),
      amount: (json['amount'] ?? 0) as int,
      views: (json['views_count'] ?? 0) as int,
      likes: (json['likes_count'] ?? 0) as int,
      score: (json['engagement_score'] ?? 0) as int,
      totalScore: (json['total_engagement_score'] ?? 0) as int,
      status: json['status'] ?? 'pending',
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
    );
  }

  String get typeLabel {
    if (type == 'creator_fund') return 'Creator Fund';
    if (type == 'ad_revenue') return 'Revenus publicitaires';
    return type;
  }
}
