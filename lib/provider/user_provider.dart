import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_chat_gpt/pages/users/user_type.dart';

final userTypeProvider = Provider<List<UserType>>((ref) {
  return UserType.values;
});
