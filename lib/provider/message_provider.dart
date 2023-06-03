// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessagesNotifier extends StateNotifier<List<types.Message>> {
  ChatMessagesNotifier() : super([]);

  void addTextMessage(types.Message message) {
    state = [message, ...state];
  }
}

/// message provider
final messagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<types.Message>>((ref) {
  return ChatMessagesNotifier();
});
