class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String? description;
  final DateTime createdAt;
  final String status;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentSaved,
    required this.targetDate,
    this.description,
    required this.createdAt,
    required this.status,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
        id: map['id'] as String,
        title: map['title'] as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        currentSaved: (map['current_saved'] as num).toDouble(),
        targetDate: DateTime.parse(map['target_date'] as String),
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: map['status'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'target_amount': targetAmount,
        'current_saved': currentSaved,
        'target_date': targetDate.toIso8601String(),
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'status': status,
      };
}

class SavingsTransaction {
  final String id;
  final String goalId;
  final double amount;
  final String type;
  final DateTime date;
  final String? description;

  SavingsTransaction({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
  });

  factory SavingsTransaction.fromMap(Map<String, dynamic> map) => SavingsTransaction(
        id: map['id'] as String,
        goalId: map['goal_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        date: DateTime.parse(map['date'] as String),
        description: map['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        'description': description,
      };
}
