import 'dart:convert';

void stringToBase64(String str) {
  print(base64Encode(utf8.encode(str)));
}

void main() {
  stringToBase64("your password");
}
