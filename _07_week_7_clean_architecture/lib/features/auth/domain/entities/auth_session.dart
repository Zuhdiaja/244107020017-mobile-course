/// Entity murni milik domain.
///
/// Tanpa `toJson/fromJson/toMap/fromMap` — mapping data luar adalah tugas
/// `AuthSessionModel` di layer `data`. Tanpa import framework apa pun.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}
