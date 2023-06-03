// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:dart_openai/openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromptResponse {
  String content;
  bool finish;
  PromptResponse({
    required this.content,
    required this.finish,
  });

  PromptResponse copyWith({
    String? content,
    bool? finish,
  }) {
    return PromptResponse(
      content: content ?? this.content,
      finish: finish ?? this.finish,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'finish': finish,
    };
  }

  factory PromptResponse.fromMap(Map<String, dynamic> map) {
    return PromptResponse(
      content: map['content'] as String,
      finish: map['finish'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory PromptResponse.fromJson(String source) =>
      PromptResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ChatResponse(content: $content, finish: $finish)';

  @override
  bool operator ==(covariant PromptResponse other) {
    if (identical(this, other)) return true;

    return other.content == content && other.finish == finish;
  }

  @override
  int get hashCode => content.hashCode ^ finish.hashCode;
}

/// chat gpt response stream notifier
class GptPromptResponseNotifier extends StateNotifier<PromptResponse?> {
  GptPromptResponseNotifier() : super(null);

  void chatStart(String prompt) {
    // cteate stream
    var chatStream = OpenAI.instance.chat.createStream(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: prompt,
          role: OpenAIChatMessageRole.user,
        )
      ],
    );
    // add my prompt message
    String content = '';
    // listen to stream
    chatStream.listen((chatStreamEvent) {
      final partial = chatStreamEvent.choices.first.delta.content;
      debugPrint('partial -> $partial');
      if (partial != null) {
        content += partial;
      }
      state = PromptResponse(content: content, finish: false);
    }, onError: (error) {
      content = error.toString();
      state = PromptResponse(content: content, finish: true);
    }, onDone: () {
      content = content.trim();
      debugPrint('done -> content');
      state = PromptResponse(content: content, finish: true);
    });
  }

  /// update current gpt-chat token
  void updateToken(String token) {
    OpenAI.apiKey = token;
  }
}

/// stream response provider
final promptResponseProvider =
    StateNotifierProvider<GptPromptResponseNotifier, PromptResponse?>((ref) {
  return GptPromptResponseNotifier();
});

final sendEnableProvider = StateProvider((ref) => true);
