import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// key value storage keys.
class ChatGptKeys {
  static const String tokenKey = 'com.chatgpt.token.key';
}

extension ChatGptKeyReader on String {
  Future<File> _getLocalFile() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    return File('$dir/$this.txt');
  }
}

class ChatGptTokenNotifier extends StateNotifier<String?> {
  ChatGptTokenNotifier() : super(null);

  void readToken() async {
    try {
      File file = await ChatGptKeys.tokenKey._getLocalFile();
      state = await file.readAsString();
    } catch (error) {
      state = '';
    }
  }

  void removeToken() async {
    try {
      File file = await ChatGptKeys.tokenKey._getLocalFile();
      await file.delete();
      state = null;
    } catch (error) {
      state = null;
    }
  }

  void writeToken(String address) async {
    try {
      File file = await ChatGptKeys.tokenKey._getLocalFile();
      await file.writeAsString(address);
      state = address;
    } catch (error) {
      state = null;
    }
  }
}

final tokenProvider =
    StateNotifierProvider<ChatGptTokenNotifier, String?>((ref) {
  var notify = ChatGptTokenNotifier();
  notify.readToken();
  return notify;
});
