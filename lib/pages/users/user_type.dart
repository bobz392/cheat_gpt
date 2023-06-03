enum UserType { japanese, english, chat, image, chinese }

extension UserTypeInfo on UserType {
  String get name {
    switch (this) {
      case UserType.chinese:
        return '中文老师';
      case UserType.japanese:
        return '日文老师';
      case UserType.english:
        return '英语老师';
      case UserType.chat:
        return '自由聊天';
      case UserType.image:
        return '图片生成';
    }
  }
}
