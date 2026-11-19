import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta programada para [FakeHttpAdapter].
typedef FakeResponder = ResponseBody Function(RequestOptions options);

/// Adaptador HTTP en memoria: devuelve la respuesta programada y guarda la
/// última petición para inspeccionarla.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeResponder? responder;
  Object? errorToThrow;
  RequestOptions? lastRequest;
  String? lastBody;

  /// Programa una respuesta JSON con [statusCode].
  void respondJson(Object? body, {int statusCode = 200}) {
    responder = (_) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      lastBody = utf8.decode(
        await requestStream.expand((chunk) => chunk).toList(),
      );
    }
    final error = errorToThrow;
    if (error != null) {
      if (error is DioException) throw error;
      throw DioException(requestOptions: options, error: error);
    }
    return responder!(options);
  }

  @override
  void close({bool force = false}) {}
}
