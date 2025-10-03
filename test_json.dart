import 'dart:convert';

void main() {
  final header = {
    'memo': 'Generated transaction',
    'principal': 'acc://e017033ead91ca77ccfb9b357a3e9776216a2bffd44f020c/book',
    'timestamp': 1705531868703
  };

  final body = {
    'to': [
      {'amount': '9876543210', 'url': 'acc://6ce0fdf3100dd10e560dc9d46559641c65f080d51beaf153/ACME'},
      {'amount': '1000', 'url': 'acc://alice.acme/credits'},
      {'amount': '5', 'url': 'acc://helen.corp/credits'}
    ],
    'type': 'send-tokens'
  };

  print('Dart jsonEncode results:');
  print('Header: ${jsonEncode(header)}');
  print('Body: ${jsonEncode(body)}');
}