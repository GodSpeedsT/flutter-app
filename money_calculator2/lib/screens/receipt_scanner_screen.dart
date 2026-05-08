import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/ocr_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum ScanState { idle, scanning, reviewing, saving, error }

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  final _ocrService = OcrService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  ScanState _state = ScanState.idle;
  File? _imageFile;
  OcrScanResult? _result;
  String _statusText = '';
  String _errorText = '';
  double _scanProgress = 0;

  // Form controllers
  late TextEditingController _storeCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String _category = 'Еда';
  bool _isExpense = true;

  // Animation for scanner line
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  // Scan history (in-memory для сессии)
  final List<_ScanHistoryItem> _history = [];

  static const _categories = [
    'Еда', 'Транспорт', 'Развлечения', 'Здоровье',
    'Связь', 'Одежда', 'Дом', 'Прочее',
  ];

  @override
  void initState() {
    super.initState();
    _storeCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = CurvedAnimation(
      parent: _scanLineCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      HapticFeedback.lightImpact();
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2000,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _state = ScanState.scanning;
        _statusText = 'Загрузка изображения...';
        _scanProgress = 0.1;
        _result = null;
        _errorText = '';
      });
      await _processImage(_imageFile!);
    } catch (e) {
      setState(() {
        _state = ScanState.error;
        _errorText = 'Ошибка доступа к камере: $e';
      });
    }
  }

  Future<void> _processImage(File file) async {
    try {
      final result = await _ocrService.processReceipt(
        file,
        onStatus: (status) {
          setState(() {
            _statusText = status;
            _scanProgress = switch (status) {
              String s when s.contains('Загрузка') => 0.25,
              String s when s.contains('Запуск') => 0.50,
              String s when s.contains('Обработка') => 0.75,
              String s when s.contains('Получение') => 0.90,
              _ => _scanProgress,
            };
          });
        },
      );
      HapticFeedback.mediumImpact();
      setState(() {
        _result = result;
        _state = ScanState.reviewing;
        _scanProgress = 1.0;
        _storeCtrl.text = result.storeName ?? '';
        _amountCtrl.text = result.totalAmount?.toStringAsFixed(2) ?? '';
        _noteCtrl.text = '';
        _category = _guessCategory(result.storeName);
      });
    } catch (e) {
      setState(() {
        _state = ScanState.error;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _guessCategory(String? storeName) {
    if (storeName == null) return 'Еда';
    final name = storeName.toLowerCase();
    if (name.contains('такси') || name.contains('метро') || name.contains('автобус')) {
      return 'Транспорт';
    }
    if (name.contains('аптека') || name.contains('клиника') || name.contains('медицин')) {
      return 'Здоровье';
    }
    if (name.contains('кино') || name.contains('театр') || name.contains('спорт')) {
      return 'Развлечения';
    }
    if (name.contains('мтс') || name.contains('билайн') || name.contains('мегафон')) {
      return 'Связь';
    }
    return 'Еда';
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final transaction = Transaction(
      id: _uuid.v4(),
      title: _storeCtrl.text.isNotEmpty ? _storeCtrl.text : 'Чек',
      amount: amount,
      category: _category,
      date: _result?.date ?? DateTime.now(),
      isExpense: _isExpense,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      receiptImagePath: _imageFile?.path,
    );
    provider.addTransaction(transaction);

    // Добавить в историю сессии
    setState(() {
      _history.insert(
        0,
        _ScanHistoryItem(
          storeName: _storeCtrl.text.isNotEmpty ? _storeCtrl.text : 'Чек',
          amount: amount,
          category: _category,
          savedAt: DateTime.now(),
          imageFile: _imageFile,
        ),
      );
      _state = ScanState.idle;
      _imageFile = null;
      _result = null;
    });

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Транзакция сохранена!'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_state) {
                  ScanState.idle => _buildIdle(),
                  ScanState.scanning => _buildScanning(),
                  ScanState.reviewing => _buildReviewing(),
                  ScanState.saving => _buildScanning(),
                  ScanState.error => _buildError(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Сканер чеков',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'OCR-распознавание',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (_state != ScanState.idle)
            GestureDetector(
              onTap: () => setState(() {
                _state = ScanState.idle;
                _imageFile = null;
                _result = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      children: [
        // Камера / галерея кнопки
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              // Иконка + подпись
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'Сфотографируйте чек',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Данные будут распознаны автоматически',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Камера',
                      gradient: AppTheme.primaryGradient,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Галерея',
                      gradient: AppTheme.accentGradient,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // OCR сервер статус
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'OCR-сервис: 192.168.80.1:3000',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ЛОКАЛЬНЫЙ',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // История сканирований
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: const [
              Text(
                'История сканирований',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._history.map((item) => _HistoryTile(item: item)),
        ],
      ],
    );
  }

  Widget _buildScanning() {
    return Column(
      children: [
        // Preview изображения
        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.file(
                  _imageFile!,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Overlay с анимацией сканирования
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.background.withOpacity(0.2),
                        AppTheme.background.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                // Сканирующая линия
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, __) {
                    return Positioned(
                      top: _scanLineAnim.value * 240,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primary,
                              AppTheme.primary,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              // Прогресс-бар
              LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${(_scanProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Шаги
              _ScanStep(
                label: 'Загрузка изображения',
                done: _scanProgress > 0.25,
                active: _scanProgress <= 0.25,
              ),
              _ScanStep(
                label: 'Запуск распознавания',
                done: _scanProgress > 0.5,
                active: _scanProgress > 0.25 && _scanProgress <= 0.5,
              ),
              _ScanStep(
                label: 'Обработка OCR',
                done: _scanProgress > 0.75,
                active: _scanProgress > 0.5 && _scanProgress <= 0.75,
              ),
              _ScanStep(
                label: 'Получение результатов',
                done: _scanProgress >= 1.0,
                active: _scanProgress > 0.75 && _scanProgress < 1.0,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview маленькое
        if (_imageFile != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 80,
                  width: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Чек распознан ✓',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_result?.items.length ?? 0} позиций найдено',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (_result?.date != null)
                      Text(
                        'Дата: ${_result!.date!.day}.${_result!.date!.month.toString().padLeft(2, '0')}.${_result!.date!.year}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),

        // Форма редактирования
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Редактировать данные',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Тип транзакции
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isExpense
                              ? AppTheme.accentRed.withOpacity(0.15)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isExpense
                                ? AppTheme.accentRed
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '💸 Расход',
                            style: TextStyle(
                              color: _isExpense
                                  ? AppTheme.accentRed
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isExpense
                              ? AppTheme.primary.withOpacity(0.15)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_isExpense
                                ? AppTheme.primary
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '💰 Доход',
                            style: TextStyle(
                              color: !_isExpense
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _storeCtrl,
                label: 'Название магазина / организации',
                icon: Icons.store_rounded,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _amountCtrl,
                label: 'Сумма',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Категория
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceElevated,
                    icon: const Icon(Icons.expand_more,
                        color: AppTheme.textSecondary),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(
                              color: AppTheme.textPrimary)),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _noteCtrl,
                label: 'Заметка (необязательно)',
                icon: Icons.note_rounded,
              ),
            ],
          ),
        ),

        // Позиции из чека
        if (_result != null && _result!.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Позиции из чека',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_result!.items.length} шт.',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._result!.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (item.price != null)
                          Text(
                            AppFormatter.currency(item.price!,
                                context.read<AppProvider>().currency),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // Raw text (collapsible)
        if (_result?.rawText != null && _result!.rawText.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RawTextExpansion(rawText: _result!.rawText),
        ],

        const SizedBox(height: 24),

        // Кнопки
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _state = ScanState.idle;
                  _imageFile = null;
                  _result = null;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _saveTransaction,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Сохранить транзакцию',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                color: AppTheme.accentRed, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ошибка распознавания',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorText,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '💡 Убедитесь, что OCR-сервер запущен на 192.168.80.1:3000',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _state = ScanState.idle;
                    _imageFile = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cardBorder),
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Назад'),
                ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _state = ScanState.scanning;
                        _statusText = 'Повторная попытка...';
                        _scanProgress = 0.1;
                      });
                      _processImage(_imageFile!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Повторить',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        prefixIcon:
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

// ─── Вспомогательные виджеты ────────────────────────────────────────────────

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final bool isLast;

  const _ScanStep({
    required this.label,
    this.done = false,
    this.active = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppTheme.primary
        : active
        ? AppTheme.accent
        : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.primary.withOpacity(0.15)
                  : active
                  ? AppTheme.accent.withOpacity(0.15)
                  : AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check, size: 12, color: AppTheme.primary)
                : active
                ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _RawTextExpansion extends StatefulWidget {
  final String rawText;
  const _RawTextExpansion({required this.rawText});

  @override
  State<_RawTextExpansion> createState() => _RawTextExpansionState();
}

class _RawTextExpansionState extends State<_RawTextExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.text_snippet_outlined,
                      color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Исходный текст OCR',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.rawText,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanHistoryItem {
  final String storeName;
  final double amount;
  final String category;
  final DateTime savedAt;
  final File? imageFile;

  _ScanHistoryItem({
    required this.storeName,
    required this.amount,
    required this.category,
    required this.savedAt,
    this.imageFile,
  });
}

class _HistoryTile extends StatelessWidget {
  final _ScanHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          if (item.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(item.imageFile!,
                  width: 44, height: 44, fit: BoxFit.cover),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt,
                  color: AppTheme.textSecondary, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.storeName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.category} • ${item.savedAt.hour}:${item.savedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            AppFormatter.currency(item.amount,
                context.read<AppProvider>().currency),
            style: const TextStyle(
              color: AppTheme.accentRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}