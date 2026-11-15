import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

/// Перетворює користувача Firebase Auth на незалежну доменну модель.
UserProfile fromFirebaseUser(User user) => UserProfile(
  uid: user.uid,
  email: user.email ?? '',
  displayName: user.displayName,
  photoUrl: user.photoURL,
  createdAt: user.metadata.creationTime,
  providers: user.providerData.map((provider) => provider.providerId).toList(),
);
