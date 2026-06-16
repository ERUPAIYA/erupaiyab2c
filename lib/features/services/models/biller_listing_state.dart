import 'biller_model.dart';

class BillerListingState {
  const BillerListingState({
    this.isFetching = false,
    this.isFetchingMore = false,
    this.billers = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
  });

  final bool isFetching;
  final bool isFetchingMore;
  final List<Biller> billers;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int limit;

  bool get hasMore => currentPage < totalPages;

  static const _sentinel = Object();

  BillerListingState copyWith({
    bool? isFetching,
    bool? isFetchingMore,
    List<Biller>? billers,
    Object? errorMessage = _sentinel,
    int? currentPage,
    int? totalPages,
    int? limit,
  }) {
    return BillerListingState(
      isFetching: isFetching ?? this.isFetching,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      billers: billers ?? this.billers,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
    );
  }
}
