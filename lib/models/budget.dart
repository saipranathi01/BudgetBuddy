class MonthlyBudget {
  final String id;
  final String monthKey;
  final double totalBudget;
  final DateTime createdAt;

  MonthlyBudget({
    required this.id,
    required this.monthKey,
    required this.totalBudget,
    required this.createdAt,
  });

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) => MonthlyBudget(
        id: map['id'] as String,
        monthKey: map['month_key'] as String,
        totalBudget: (map['total_budget'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'month_key': monthKey,
        'total_budget': totalBudget,
        'created_at': createdAt.toIso8601String(),
      };
}

class CategoryBudget {
  final String id;
  final String monthKey;
  final String category;
  final double limit;
  final DateTime createdAt;

  CategoryBudget({
    required this.id,
    required this.monthKey,
    required this.category,
    required this.limit,
    required this.createdAt,
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
        id: map['id'] as String,
        monthKey: map['month_key'] as String,
        category: map['category'] as String,
        limit: (map['limit'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'month_key': monthKey,
        'category': category,
        'limit': limit,
        'created_at': createdAt.toIso8601String(),
      };
}
