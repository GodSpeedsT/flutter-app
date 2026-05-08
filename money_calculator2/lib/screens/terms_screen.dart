import 'package:flutter/material.dart';
import 'package:money_calculator2/screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with TickerProviderStateMixin {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isAdult = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => _agreedToTerms && _agreedToPrivacy && _isAdult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Logo area
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'ФинансыПро',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Прежде чем начать, пожалуйста,\nознакомьтесь с условиями',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildSection(
                          '📋 Пользовательское соглашение',
                          [
                            'Приложение «ФинансыПро» предназначено для личного финансового учёта и оптимизации расходов.',
                            'Пользователь несёт полную ответственность за корректность вводимых данных.',
                            'Приложение не является финансовым советником и не несёт ответственности за финансовые решения пользователя.',
                            'Данные хранятся локально на устройстве пользователя и не передаются третьим лицам.',
                            'Разработчик оставляет за собой право обновлять приложение и изменять функциональность.',
                            'Запрещается использование приложения в целях, противоречащих законодательству РФ.',
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          '🔒 Политика конфиденциальности',
                          [
                            'Мы не собираем персональные данные пользователей.',
                            'Все финансовые данные хранятся исключительно на вашем устройстве.',
                            'Функция сканирования чеков отправляет изображения только на локальный сервер (localhost), указанный вами.',
                            'Разрешения на камеру используются только для фотографирования чеков.',
                            'Приложение не использует аналитику и не отслеживает действия пользователя.',
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          '🛡️ Защита детей (COPPA)',
                          [
                            'Приложение предназначено для лиц старше 18 лет.',
                            'Мы не собираем данные от детей и не направляем им рекламу.',
                            'Если вам менее 18 лет — пожалуйста, используйте приложение под наблюдением родителей или законных представителей.',
                            'При обнаружении использования приложения несовершеннолетними без разрешения родителей мы оставляем право заблокировать доступ.',
                            'Родители/опекуны могут обратиться к нам для удаления данных несовершеннолетнего.',
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          '📷 Разрешения приложения',
                          [
                            'Камера — используется для фотографирования чеков и документов.',
                            'Хранилище — для сохранения фотографий чеков на устройство.',
                            'Интернет (localhost) — для отправки изображений на локальный OCR-сервис.',
                            'Все разрешения запрашиваются только в момент использования соответствующих функций.',
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Checkboxes
                        _buildCheckbox(
                          value: _isAdult,
                          onChanged: (v) =>
                              setState(() => _isAdult = v ?? false),
                          label:
                          'Мне исполнилось 18 лет или я использую приложение с разрешения родителей',
                        ),
                        const SizedBox(height: 12),
                        _buildCheckbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                          label:
                          'Я прочитал(а) и принимаю Пользовательское соглашение',
                        ),
                        const SizedBox(height: 12),
                        _buildCheckbox(
                          value: _agreedToPrivacy,
                          onChanged: (v) =>
                              setState(() => _agreedToPrivacy = v ?? false),
                          label:
                          'Я согласен(на) с Политикой конфиденциальности',
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Bottom button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: AnimatedOpacity(
                    opacity: _canProceed ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _canProceed
                            ? AppTheme.primaryGradient
                            : const LinearGradient(
                          colors: [
                            AppTheme.surfaceElevated,
                            AppTheme.surfaceElevated
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _canProceed
                              ? () {
                            context.read<AppProvider>().acceptTerms();
                          }
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'Принять и продолжить',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppTheme.primary, fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppTheme.primary : AppTheme.cardBorder,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
