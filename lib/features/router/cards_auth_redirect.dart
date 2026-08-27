String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  const onboardingPath = '/onboarding';
  const cardsPath = '/cards';

  final isOnboarding = uri.path == onboardingPath;

  if (!isAuthed) {
    if (isOnboarding) {
      return null;
    }

    if (_isSafeCardsUri(uri)) {
      final next = Uri.encodeComponent(uri.toString());
      return '$onboardingPath?next=$next';
    }

    return null;
  }

  if (!isOnboarding) {
    return null;
  }

  final next = uri.queryParameters['next'];
  if (next == null || next.isEmpty) {
    return cardsPath;
  }

  final nextUri = Uri.tryParse(next);
  if (nextUri == null || !_isSafeCardsUri(nextUri)) {
    return cardsPath;
  }

  return next;
}

bool _isSafeCardsUri(Uri uri) {
  if (uri.hasScheme || uri.hasAuthority) {
    return false;
  }

  return uri.path == '/cards' || uri.path.startsWith('/cards/');
}
