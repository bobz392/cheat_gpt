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

  ChatType get next {
    switch (this) {
      case ChatType.cn:
        return ChatType.jap;
      case ChatType.en:
        return ChatType.image;
      case ChatType.image:
        return ChatType.image;
      case ChatType.chat:
        return ChatType.cn;
      case ChatType.jap:
        return ChatType.en;
    }
  }

  int get rawValue {
    switch (this) {
      case ChatType.cn:
        return 1;
      case ChatType.en:
        return 3;
      case ChatType.image:
        return 4;
      case ChatType.chat:
        return 0;
      case ChatType.jap:
        return 2;
    }
  }

  ChatType get last {
    switch (this) {
      case ChatType.cn:
        return ChatType.chat;
      case ChatType.en:
        return ChatType.jap;
      case ChatType.image:
        return ChatType.en;
      case ChatType.chat:
        return ChatType.chat;
      case ChatType.jap:
        return ChatType.cn;
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
