class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'A server error occurred']);

  @override
  String toString() => message;
}
