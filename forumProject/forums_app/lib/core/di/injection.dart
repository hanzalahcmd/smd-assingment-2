import 'package:firebase_module/firebase_module.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

/// Call once in [main] before [runApp].
Future<void> setupDependencies() async {
  // Repositories (singletons — one instance per app lifetime)
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<IForumRepository>(() => ForumRepository());
  sl.registerLazySingleton<IReplyRepository>(() => ReplyRepository());
}
