import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../home/models/banner_model.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import '../repositories/service_extras_repository.dart';

final serviceExtrasRepositoryProvider = Provider<ServiceExtrasRepository>(
  (ref) => ServiceExtrasRepository(),
);

final servicePageBannersProvider =
    FutureProvider.autoDispose.family<List<BannerModel>, String>(
  (ref, slug) async {
    final repo = ref.watch(serviceExtrasRepositoryProvider);
    return repo.fetchPageBanners(slug: slug, lang: 'en');
  },
);

final serviceLatestTransactionsProvider =
    FutureProvider.autoDispose.family<List<LatestTransaction>, String>(
  (ref, service) async {
    final repo = ref.watch(serviceExtrasRepositoryProvider);
    return repo.fetchLatestTransactions(service: service);
  },
);

