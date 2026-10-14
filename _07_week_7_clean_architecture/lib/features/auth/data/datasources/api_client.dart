import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          if (renewed.access == null) throw Exception(renewed.failure?.message);
          await store.save(access: renewed.access!, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions..headers['Authorization'] = 'Bearer ${renewed.access}',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}
