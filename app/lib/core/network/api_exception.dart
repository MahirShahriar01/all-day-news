/// A user-presentable failure from the network layer.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isOffline => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
