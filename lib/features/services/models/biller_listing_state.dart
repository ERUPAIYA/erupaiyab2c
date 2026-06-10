import 'biller_model.dart';

class BillerListingState {
  const BillerListingState({
    this.isFetching = false,
    this.isFetchingMore = false,
    this.billers = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
  });

  final bool isFetching;
  final bool isFetchingMore;
  final List<Biller> billers;
  final String searchQuery;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int limit;

  bool get hasMore => currentPage < totalPages;

  List<Biller> get filteredBillers {
    if (searchQuery.isEmpty) return billers;
    final query = searchQuery.toLowerCase();
    return billers
        .where((b) => b.billerName.toLowerCase().contains(query))
        .toList();
  }

  static const _sentinel = Object();

  BillerListingState copyWith({
    bool? isFetching,
    bool? isFetchingMore,
    List<Biller>? billers,
    String? searchQuery,
    Object? errorMessage = _sentinel,
    int? currentPage,
    int? totalPages,
    int? limit,
  }) {
    return BillerListingState(
      isFetching: isFetching ?? this.isFetching,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      billers: billers ?? this.billers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
    );
  }
}
