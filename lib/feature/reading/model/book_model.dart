// lib/features/reading/model/book_model.dart

enum BookStatus { reading, completed, paused, wishlist }

extension BookStatusX on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.reading:
        return 'Reading';
      case BookStatus.completed:
        return 'Completed';
      case BookStatus.paused:
        return 'Paused';
      case BookStatus.wishlist:
        return 'Wishlist';
    }
  }
}

enum BookCategory {
  trading,
  psychology,
  philosophy,
  business,
  science,
  biography,
  selfDevelopment,
  other,
}

extension BookCategoryX on BookCategory {
  String get label {
    switch (this) {
      case BookCategory.trading:
        return 'Trading';
      case BookCategory.psychology:
        return 'Psychology';
      case BookCategory.philosophy:
        return 'Philosophy';
      case BookCategory.business:
        return 'Business';
      case BookCategory.science:
        return 'Science';
      case BookCategory.biography:
        return 'Biography';
      case BookCategory.selfDevelopment:
        return 'Self-Development';
      case BookCategory.other:
        return 'Other';
    }
  }
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final BookStatus status;
  final BookCategory category;
  final int totalPages;
  final int currentPage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime lastReadAt;
  final int dailyPageGoal;
  final String? notes;
  final double? rating;
  final String? filePath;  // path to PDF on device

  /// Pages read today. Resets when [lastReadAt] crosses midnight.
  /// Used to check whether the daily goal has been met.
  final int pagesReadToday;

  /// User-controlled shelf position (smaller = higher on the list). Set by
  /// drag-to-reorder; defaults to startedAt millis so existing books keep
  /// their natural order until the user rearranges them.
  final int sortOrder;

  /// Cached cover image path (first PDF page rendered to a PNG). Null until
  /// the viewmodel successfully generates it.
  final String? coverPath;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.category,
    required this.totalPages,
    required this.currentPage,
    required this.startedAt,
    this.completedAt,
    required this.lastReadAt,
    this.dailyPageGoal = 20,
    this.notes,
    this.rating,
    this.filePath,
    this.pagesReadToday = 0,
    this.sortOrder = 0,
    this.coverPath,
  });

  double get progressPercent =>
      totalPages > 0 ? currentPage / totalPages : 0;

  int get pagesRemaining => totalPages - currentPage;

  bool get isCompleted => status == BookStatus.completed;

  bool get isCurrentlyReading => status == BookStatus.reading;

  bool get readTodayAlready {
    final now = DateTime.now();
    return lastReadAt.year == now.year &&
        lastReadAt.month == now.month &&
        lastReadAt.day == now.day;
  }

  /// True if pagesReadToday meets or exceeds the daily page goal.
  bool get dailyGoalMet => pagesReadToday >= dailyPageGoal;

  BookModel copyWith({
    BookStatus? status,
    int? totalPages,
    int? currentPage,
    DateTime? completedAt,
    DateTime? lastReadAt,
    int? dailyPageGoal,
    int? pagesReadToday,
    String? notes,
    double? rating,
    String? filePath,
    int? sortOrder,
    String? coverPath,
  }) {
    return BookModel(
      id: id,
      title: title,
      author: author,
      status: status ?? this.status,
      category: category,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      dailyPageGoal: dailyPageGoal ?? this.dailyPageGoal,
      pagesReadToday: pagesReadToday ?? this.pagesReadToday,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      filePath: filePath ?? this.filePath,
      sortOrder: sortOrder ?? this.sortOrder,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'status': status.index,
      'category': category.index,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'dailyPageGoal': dailyPageGoal,
      'pagesReadToday': pagesReadToday,
      'notes': notes,
      'rating': rating,
      'filePath': filePath,
      'sortOrder': sortOrder,
      'coverPath': coverPath,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> m) {
    return BookModel(
      id: m['id'] as String,
      title: m['title'] as String,
      author: m['author'] as String,
      status: BookStatus.values[m['status'] as int],
      category: BookCategory.values[m['category'] as int],
      totalPages: m['totalPages'] as int,
      currentPage: m['currentPage'] as int,
      startedAt: DateTime.parse(m['startedAt'] as String),
      completedAt: m['completedAt'] != null
          ? DateTime.parse(m['completedAt'] as String)
          : null,
      lastReadAt: DateTime.parse(m['lastReadAt'] as String),
      dailyPageGoal: m['dailyPageGoal'] as int? ?? 20,
      pagesReadToday: m['pagesReadToday'] as int? ?? 0,
      notes: m['notes'] as String?,
      rating: (m['rating'] as num?)?.toDouble(),
      filePath: m['filePath'] as String?,
      sortOrder: m['sortOrder'] as int? ??
          DateTime.parse(m['startedAt'] as String).millisecondsSinceEpoch,
      coverPath: m['coverPath'] as String?,
    );
  }
}
