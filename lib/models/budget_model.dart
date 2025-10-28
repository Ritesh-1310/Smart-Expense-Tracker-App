class BudgetModel {
  final int? id;
  final String category;
  final double limit; // monthly limit

  BudgetModel({this.id, required this.category, required this.limit});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budget_limit': limit, 
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> m) {
    return BudgetModel(
      id: m['id'],
      category: m['category'],
      limit: (m['budget_limit'] as num).toDouble(), 
    );
  }
}
