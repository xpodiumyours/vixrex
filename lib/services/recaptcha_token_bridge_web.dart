import 'dart:js_interop';

@JS('__getRecaptchaToken')
external JSPromise<JSString?> _getRecaptchaToken(JSString action);

Future<String?> requestRecaptchaToken(String action) async {
  final result = await _getRecaptchaToken(action.toJS).toDart;
  final token = result?.toDart;
  if (token == null || token.isEmpty) return null;
  return token;
}
