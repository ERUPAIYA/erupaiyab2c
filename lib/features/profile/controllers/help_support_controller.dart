import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/help_topic.dart';
import '../models/support_latest_transaction.dart';
import '../repositories/help_support_repository.dart';

class HelpSupportState {
  const HelpSupportState({
    this.isLoading = false,
    this.latestTransactions = const [],
    this.helpTopics = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<SupportLatestTransaction> latestTransactions;
  final List<HelpTopic> helpTopics;
  final String? errorMessage;

  HelpSupportState copyWith({
    bool? isLoading,
    List<SupportLatestTransaction>? latestTransactions,
    List<HelpTopic>? helpTopics,
    String? errorMessage,
  }) {
    return HelpSupportState(
      isLoading: isLoading ?? this.isLoading,
      latestTransactions: latestTransactions ?? this.latestTransactions,
      helpTopics: helpTopics ?? this.helpTopics,
      errorMessage: errorMessage,
    );
  }
}

final helpSupportRepositoryProvider = Provider<HelpSupportRepository>(
  (ref) => HelpSupportRepository(),
);

final helpSupportControllerProvider =
    StateNotifierProvider<HelpSupportController, HelpSupportState>(
  (ref) => HelpSupportController(
    repository: ref.watch(helpSupportRepositoryProvider),
  ),
);

class HelpSupportController extends StateNotifier<HelpSupportState> {
  HelpSupportController({required HelpSupportRepository repository})
      : _repository = repository,
        super(const HelpSupportState());

  final HelpSupportRepository _repository;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchLatestTransactionsAndTopics();
      state = state.copyWith(
        isLoading: false,
        latestTransactions: data.latestTransactions,
        helpTopics: data.helpTopics,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong.Please try again.',
      );
    }
  }
}
