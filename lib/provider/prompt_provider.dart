import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final promptsProvider = FutureProvider<List<List<dynamic>>>((ref) async {
  const path = 'assets/awesome-chatgpt-prompts/prompts.csv';
  final csvData = await rootBundle.loadString(path);
  final csvTable = const CsvToListConverter(eol: "\n").convert(csvData);
  csvTable.removeAt(0);
  return csvTable;
});

final selectPromptProvider = StateProvider<String>((ref) {
  return '';
});

final zhPromptsProvider = FutureProvider<List<dynamic>>((ref) async {
  const path = 'assets/awesome-chatgpt-prompts-zh/prompts-zh.json';
  final jsonString = await rootBundle.loadString(path);
  final zhJson = json.decode(jsonString);
  return zhJson;
});

final modelTypeProvider = StateProvider((ref) {
  // "gpt-3.5-turbo"
  // "gpt-4"
  return 0;
});
