import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

class ContactsCacheState {
  const ContactsCacheState({
    this.isLoading = false,
    this.contacts = const [],
    this.searchIndex = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Contact> contacts;
  final List<Map<String, String>> searchIndex;
  final String? errorMessage;

  ContactsCacheState copyWith({
    bool? isLoading,
    List<Contact>? contacts,
    List<Map<String, String>>? searchIndex,
    String? errorMessage,
  }) {
    return ContactsCacheState(
      isLoading: isLoading ?? this.isLoading,
      contacts: contacts ?? this.contacts,
      searchIndex: searchIndex ?? this.searchIndex,
      errorMessage: errorMessage,
    );
  }
}

final contactsCacheControllerProvider =
    StateNotifierProvider<ContactsCacheController, ContactsCacheState>(
  (ref) => ContactsCacheController(),
);

class ContactsCacheController extends StateNotifier<ContactsCacheState> {
  ContactsCacheController() : super(const ContactsCacheState());

  bool _didLoadOnce = false;

  Future<void> fetchIfNeeded() async {
    if (_didLoadOnce || state.isLoading) return;
    await _fetchContacts();
  }

  Future<void> reload() async {
    await _fetchContacts(force: true);
  }

  Future<void> _fetchContacts({bool force = false}) async {
    if (state.isLoading) return;
    if (_didLoadOnce && !force) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;
      final index = list
          .map(
            (c) => {
              'name': c.displayName.toLowerCase(),
              'phone': c.phones.isNotEmpty
                  ? _digitsOnly(c.phones.first.number)
                  : '',
            },
          )
          .toList();
      _didLoadOnce = true;
      state = state.copyWith(
        isLoading: false,
        contacts: list,
        searchIndex: index,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
