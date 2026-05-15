# UniForums — Flutter + Firebase Discussion Platform

A modular, production-structured Flutter application for community discussions. Users can register, create topics, and reply in real time. Built with BLoC state management, a clean repository pattern, and Firebase as the backend.

---

## Screenshots

| `LoginScreen` | `RegisterScreen` |
|:---:|:---:|
| ![LoginScreen](screenshots/login_screen.png) | ![RegisterScreen](screenshots/register_screen.png) |
| Email + password sign-in | Full name, email, password registration |

| `HomeScreen` | `TopicDetailScreen` — reply input |
|:---:|:---:|
| ![HomeScreen](screenshots/home_screen.png) | ![TopicDetailScreen](screenshots/topic_detail_screen.png) |
| Real-time topic feed | Topic body, reply list, `_ReplyInput` bar |

> Place your screenshots under `forums_app/screenshots/` and name them as above.

---

## Project Structure

```
forums_project/
├── forums_app/          # Flutter application (UI, BLoCs, DI)
└── firebase_module/     # Local Dart package (Firebase repos, models)
```

The project is split into two packages deliberately — `firebase_module` is a self-contained data layer that has no Flutter dependency beyond `firebase_core`. This means it can be unit tested without a running device, and swapped for a different backend without touching the UI layer.

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│              forums_app                 │
│                                         │
│  Screens → BLoCs → Repositories (DI)   │
│                    ↓                    │
│           firebase_module               │
│                                         │
│  IAuthRepository   IForumRepository    │
│  IReplyRepository  (abstract contracts) │
│         ↓                  ↓           │
│  AuthRepository  ForumRepository        │
│  ReplyRepository (Firebase impls)       │
│         ↓                  ↓           │
│   FirebaseAuth        Firestore         │
└─────────────────────────────────────────┘
```

Every repository is hidden behind an abstract interface (`IAuthRepository`, `IForumRepository`, `IReplyRepository`). BLoCs depend only on the interfaces — never the concrete Firebase implementations. This is what makes the unit tests possible with mocks.

---

## firebase_module

### Purpose

A local Dart package that owns all Firebase interaction. `forums_app` imports it as a path dependency and only ever talks to the abstract interfaces.

### Models

**`UserModel`** — Immutable value object for an authenticated user.

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase Auth UID |
| `email` | `String` | User's email address |
| `displayName` | `String` | Display name shown in the UI |

Constructed from a Firebase `User` via `UserModel.fromFirebaseUser(user)`. Equality is based on `uid` alone.

---

**`ForumTopic`** — Represents a top-level discussion thread.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore document ID |
| `title` | `String` | Topic heading |
| `content` | `String` | Full body text |
| `authorId` | `String` | UID of the user who posted |
| `authorName` | `String` | Display name at time of posting |
| `createdAt` | `DateTime` | Creation timestamp |
| `replyCount` | `int` | Denormalised reply count (default 0) |

Serialises to/from Firestore via `toFirestore()` / `ForumTopic.fromFirestore(doc)`. Supports `copyWith`.

---

**`ForumReply`** — Represents a reply to a `ForumTopic`.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firestore document ID |
| `topicId` | `String` | ID of the parent topic |
| `content` | `String` | Reply body text |
| `authorId` | `String` | UID of the replying user |
| `authorName` | `String` | Display name at time of reply |
| `createdAt` | `DateTime` | Creation timestamp |

---

### Repositories

**`AuthRepository`** implements `IAuthRepository`

| Method | Description |
|---|---|
| `authStateChanges` | Stream of `UserModel?` — emits on sign-in/out |
| `currentUser` | Returns the currently signed-in `UserModel`, or null |
| `signInWithEmail(email, password)` | Signs in and returns `UserModel` |
| `registerWithEmail(email, password, displayName)` | Creates account, sets display name, returns `UserModel` |
| `signOut()` | Signs out the current user |

All `FirebaseAuthException` codes are mapped to human-readable messages before being thrown.

---

**`ForumRepository`** implements `IForumRepository`

| Method | Description |
|---|---|
| `watchTopics()` | Real-time stream of all topics, newest first |
| `fetchTopics()` | One-time fetch of all topics (for pull-to-refresh) |
| `createTopic(topic)` | Writes a new topic, returns its Firestore document ID |
| `incrementReplyCount(topicId)` | Atomically increments `replyCount` with `FieldValue.increment(1)` |

Reads from and writes to the `topics` Firestore collection.

---

**`ReplyRepository`** implements `IReplyRepository`

| Method | Description |
|---|---|
| `watchReplies(topicId)` | Real-time stream of replies for a topic, sorted by `createdAt` ascending (client-side sort) |
| `addReply(reply)` | Writes a reply to the `replies` collection, returns document ID |

Reads from and writes to the `replies` Firestore collection, filtered by `topicId`.

---

### Firestore Collections

```
topics/
  {topicId}/
    title        : string
    content      : string
    authorId     : string
    authorName   : string
    createdAt    : timestamp
    replyCount   : number

replies/
  {replyId}/
    topicId      : string
    content      : string
    authorId     : string
    authorName   : string
    createdAt    : timestamp
```

---

### Unit Tests

Tests live in `firebase_module/test/` and use Mockito for mocking Firebase dependencies. No real Firebase connection is needed.

```
firebase_module/test/
├── auth_test.dart       # AuthRepository — 5 tests
└── forum_test.dart      # ForumRepository + ReplyRepository — 4 tests
```

**Before running tests for the first time**, generate the mock classes:

```powershell
cd forums_project\firebase_module
dart run build_runner build --delete-conflicting-outputs
```

Then run:

```powershell
flutter test
```

**auth_test.dart covers:**
- Successful sign-in returns a correctly mapped `UserModel`
- `user-not-found` throws with the right message
- `wrong-password` throws with the right message
- Successful registration returns `UserModel`
- `email-already-in-use` throws with the right message
- `currentUser` returns `UserModel` when signed in
- `currentUser` returns null when signed out
- `signOut` calls `FirebaseAuth.signOut()` exactly once

**forum_test.dart covers:**
- `createTopic` calls `collection.add` and returns the document ID
- `incrementReplyCount` calls `doc.update` with a `replyCount` field
- `fetchTopics` returns a correctly mapped list of `ForumTopic`
- `addReply` calls `collection.add` and returns the document ID

---

## forums_app

### Features

- **Authentication** — Register and sign in with email and password. Auth state persists across app restarts via Firebase Auth's built-in persistence.
- **Topic feed** — Real-time list of all discussion topics, newest first.
- **Topic detail** — View a topic's full content and all its replies in real time.
- **Create topic** — Post a new discussion thread.
- **Reply** — Post replies to any topic. Reply count updates automatically.
- **Guest view** — Unauthenticated users can browse but cannot post.

### Screens

| Screen | Route | Description |
|---|---|---|
| `LoginScreen` | `/` (unauthenticated) | Email + password sign-in, with link to register |
| `RegisterScreen` | From login | Full name, email, password registration |
| `HomeScreen` | `/` (authenticated) | Real-time topic feed with FAB to create topic |
| `CreateTopicScreen` | From FAB | Title + content form |
| `TopicDetailScreen` | From topic card | Topic body, reply list, reply input bar |

### State Management — BLoC

**`AuthBloc`** — manages authentication state for the entire app.

| Event | Description |
|---|---|
| `AuthCheckRequested` | Fired on startup — checks for an existing session |
| `AuthLoginRequested` | Triggers email/password sign-in |
| `AuthRegisterRequested` | Triggers account creation |
| `AuthLogoutRequested` | Signs the user out |

| State | Description |
|---|---|
| `AuthInitial` | App just launched, not yet checked |
| `AuthLoading` | Sign-in or register in progress |
| `AuthAuthenticated` | Signed in — carries `UserModel` |
| `AuthUnauthenticated` | Signed out |
| `AuthError` | Auth failed — carries error message string |

`AuthBloc` also subscribes to `authStateChanges` so the UI reacts to external sign-out (e.g. token revocation) without any extra events.

---

**`ForumBloc`** — manages the topic list on `HomeScreen`.

| Event | Description |
|---|---|
| `ForumSubscriptionRequested` | Starts the real-time topic stream |
| `ForumTopicCreateRequested` | Creates a new topic |

| State | Description |
|---|---|
| `ForumStatus.initial` | Not yet loaded |
| `ForumStatus.loading` | Stream connecting |
| `ForumStatus.success` | Topics loaded — carries `List<ForumTopic>` |
| `ForumStatus.failure` | Stream error — carries error message |
| `ForumStatus.creating` | Topic creation in progress |

---

**`ReplyBloc`** — manages replies on `TopicDetailScreen`.

| Event | Description |
|---|---|
| `ReplySubscriptionRequested` | Starts the real-time reply stream for a topic |
| `ReplyAddRequested` | Posts a reply and increments the topic's reply count |

| State | Description |
|---|---|
| `ReplyStatus.initial` | Not yet loaded |
| `ReplyStatus.loading` | Stream connecting |
| `ReplyStatus.success` | Replies loaded — carries `List<ForumReply>` |
| `ReplyStatus.failure` | Error — carries error message shown in snackbar |
| `ReplyStatus.posting` | Reply submission in progress |

---

### Dependency Injection

`GetIt` is used as a service locator. All registrations happen in `lib/core/di/injection.dart` before `runApp`:

```dart
sl.registerLazySingleton<IAuthRepository>(() => AuthRepository());
sl.registerLazySingleton<IForumRepository>(() => ForumRepository());
sl.registerLazySingleton<IReplyRepository>(() => ReplyRepository());
```

BLoCs receive their repositories via constructor injection (`sl()` at `BlocProvider.create` time), keeping them fully testable.

### Theme

A single `AppTheme.light` theme defined in `lib/core/theme/app_theme.dart`. Uses Material 3 with a seed colour of Indigo (`#4F46E5`) and the Inter font (via `google_fonts`). Key customisations: borderless cards with `CardThemeData`, rounded input fields, and floating snackbars.

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`
- A Firebase project with **Firestore** and **Authentication (Email/Password)** enabled
- `flutterfire_cli` installed: `dart pub global activate flutterfire_cli`

### Firebase Setup

1. In [Firebase Console](https://console.firebase.google.com), create a project (or use an existing one).
2. Enable **Authentication → Sign-in method → Email/Password**.
3. Create a **Firestore Database** (start in test mode for development).
4. Register your Android app in **Project Settings → Your apps → Add app**.
5. Download `google-services.json` and place it at `forums_app/android/app/google-services.json`.
6. Run flutterfire to generate `firebase_options.dart`:

```powershell
cd forums_project\forums_app
flutterfire configure
```

### Install Dependencies

```powershell
# App
cd forums_project\forums_app
flutter pub get

# Firebase module
cd ..\firebase_module
flutter pub get
```

### Run

```powershell
cd forums_project\forums_app
flutter run
```

### Run Tests

```powershell
cd forums_project\firebase_module

# First time only — generate mocks
dart run build_runner build --delete-conflicting-outputs

flutter test
```

### Full Reset

```powershell
cd forums_project\forums_app
flutter clean
flutter pub get
flutterfire configure
flutter run
```

---

## Security Notes

Never commit the following files — add them to `.gitignore`:

```
# Firebase config — contains project credentials
forums_app/android/app/google-services.json
forums_app/ios/Runner/GoogleService-Info.plist
forums_app/lib/firebase_options.dart
```

Any developer cloning the repo runs `flutterfire configure` linked to the shared Firebase project to regenerate these files locally.

---

## Dependencies

### forums_app

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.9.0 | Firebase initialisation |
| `firebase_auth` | ^6.5.1 | Authentication |
| `cloud_firestore` | ^6.4.1 | Realtime database |
| `flutter_bloc` | ^9.1.1 | BLoC state management |
| `bloc` | ^9.2.1 | Core BLoC library |
| `equatable` | ^2.0.5 | Value equality for states/events |
| `get_it` | ^9.2.1 | Dependency injection |
| `google_fonts` | ^8.1.0 | Inter font |
| `intl` | ^0.20.2 | Date formatting |

### firebase_module

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.9.0 | Firebase initialisation |
| `firebase_auth` | ^6.5.1 | Auth repository implementation |
| `cloud_firestore` | ^6.4.1 | Forum/reply repository implementation |
| `mockito` | ^5.4.4 | Mock generation for tests |
| `build_runner` | ^2.4.13 | Code generation for Mockito |
