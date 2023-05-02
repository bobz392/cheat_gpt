enum ChatType { chat, cn, jap, en, image }

extension ChatTypeName on ChatType {
  String get displayName {
    switch (this) {
      case ChatType.cn:
        return 'CN';
      case ChatType.en:
        return 'English';
      case ChatType.image:
        return 'Image';
      case ChatType.chat:
        return 'Chat';
      case ChatType.jap:
        return "Jap";
    }
  }

  String buildCommand(String message) {
    switch (this) {
      case ChatType.cn:
        return '翻译成中文: $message';
      case ChatType.en:
        return '翻译成英语: $message';
      case ChatType.image:
        return message;
      case ChatType.chat:
        return message;
      case ChatType.jap:
        return '翻译成日语: $message';
    }
  }

  String? get ttsLanguage {
    switch (this) {
      case ChatType.cn:
        return 'zh-CN';
      case ChatType.en:
        return 'en-US';
      case ChatType.jap:
        return "ja-JP";
      default:
        return null;
    }
  }
}

extension ConvertToChatType on int {
  ChatType get toChatType {
    const allTypes = ChatType.values;
    if (this < allTypes.length) {
      return allTypes[this];
    } else {
      return allTypes[0];
    }
  }
}
