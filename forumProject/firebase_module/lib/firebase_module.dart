/// Firebase Module — exposes Auth and Firestore repositories
/// plus all shared data models.
library firebase_module;

// Models
export 'models/user_model.dart';
export 'models/forum_topic.dart';
export 'models/forum_reply.dart';

// Auth
export 'auth/auth_repository.dart';

// DB
export 'db/forum_repository.dart';
export 'db/reply_repository.dart';
