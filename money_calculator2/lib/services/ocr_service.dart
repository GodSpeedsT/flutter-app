import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OcrService {
  static const String _baseUrl = 'http://192.168.80.1:3000/api/ocr';

  /// Upload image and return document_id
  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка загрузки файла: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['document_id'] as String;
  }

  /// Start OCR recognition, returns task_id
  Future<String> startRecognition(String documentId) async {
    final uri = Uri.parse('$_baseUrl/recognize');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'document_id': documentId,
            'language': 'rus',
            'preprocessing_enabled': true,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка запуска распознавания: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['task_id'] as String;
  }

  /// Poll task status until done, returns result_id
  Future<String> waitForResult(String taskId) async {
    final uri = Uri.parse('$_baseUrl/tasks/$taskId');

    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Ошибка получения статуса задачи');
      }

      final data = jsonDecode(response.body);
      final status = data['status'] as String?;

      if (status == 'completed' || status == 'done') {
        return data['result_id'] as String;
      } else if (status == 'failed' || status == 'error') {
        throw Exception('Задача распознавания завершилась с ошибкой');
      }
    }
    throw Exception('Время ожидания истекло');
  }

  /// Download and parse OCR result
  Future<OcrScanResult> downloadResult(String resultId) async {
    final uri = Uri.parse('$_baseUrl/results/$resultId/download');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки результата');
    }

    final rawText = response.body;
    return _parseReceiptText(rawText);
  }

  /// Full pipeline: file → result
  Future<OcrScanResult> processReceipt(File imageFile,
      {void Function(String status)? onStatus}) async {
    onStatus?.call('Загрузка изображения...');
    final documentId = await uploadImage(imageFile);

    onStatus?.call('Запуск распознавания...');
    final taskId = await startRecognition(documentId);

    onStatus?.call('Обработка текста...');
    final resultId = await waitForResult(taskId);

    onStatus?.call('Получение результатов...');
    return await downloadResult(resultId);
  }

  OcrScanResult _parseReceiptText(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? storeName;
    double? totalAmount;
    DateTime? date;
    final items = <OcrLineItem>[];

    // Try to find store name (usually in first 3 lines)
    if (lines.isNotEmpty) {
      storeName = lines.first;
    }

    // Regex for price like 1234.56 or 1 234,56
    final priceRegex = RegExp(r'(\d[\d\s]*[.,]\d{2})');
    final totalRegex = RegExp(
        r'(?:итого|итог|total|к оплате|сумма|sum)[:\s]+(\d[\d\s]*[.,]\d{2})',
        caseSensitive: false);
    final dateRegex = RegExp(r'(\d{2}[./\-]\d{2}[./\-]\d{4}|\d{4}[./\-]\d{2}[./\-]\d{2})');

    for (final line in lines) {
      // Find total
      final totalMatch = totalRegex.firstMatch(line);
      if (totalMatch != null) {
        final amountStr = totalMatch.group(1)!
            .replaceAll(' ', '')
            .replaceAll(',', '.');
        totalAmount = double.tryParse(amountStr);
        continue;
      }

      // Find date
      final dateMatch = dateRegex.firstMatch(line);
      if (dateMatch != null && date == null) {
        final raw = dateMatch.group(1)!;
        date = _parseDate(raw);
      }

      // Find line items with prices
      final priceMatch = priceRegex.firstMatch(line);
      if (priceMatch != null) {
        final amountStr = priceMatch.group(1)!
            .replaceAll(' ', '')
            .replaceAll(',', '.');
        final price = double.tryParse(amountStr);
        final name = line.substring(0, priceMatch.start).trim();
        if (name.isNotEmpty && price != null && price > 0) {
          items.add(OcrLineItem(name: name, price: price));
        }
      }
    }

    return OcrScanResult(
      storeName: storeName,
      totalAmount: totalAmount,
      date: date,
      items: items,
      rawText: rawText,
    );
  }

  DateTime? _parseDate(String raw) {
    try {
      final parts = raw.split(RegExp(r'[./\-]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }
}