import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/category.dart';

class CategoryManagerModal extends StatefulWidget {
  final List<Category> customCategories;
  final ValueChanged<List<Category>> onCategoriesChanged;

  const CategoryManagerModal({
    super.key,
    required this.customCategories,
    required this.onCategoriesChanged,
  });

  @override
  State<CategoryManagerModal> createState() => _CategoryManagerModalState();
}

class _CategoryManagerModalState extends State<CategoryManagerModal> {
  late final TextEditingController _nameCtrl;
  bool _isExpense = true;
  IconData _selectedIcon = Icons.stars_rounded;
  Color _selectedColor = const Color(0xFF10B981);
  String? _errorText;

  static const List<IconData> _kAvailableIcons = [
    Icons.stars_rounded,
    Icons.coffee_rounded,
    Icons.local_cafe_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_takeoff_rounded,
    Icons.spa_rounded,
    Icons.laptop_mac_rounded,
    Icons.smartphone_rounded,
    Icons.local_gas_station_rounded,
    Icons.build_rounded,
    Icons.music_note_rounded,
    Icons.savings_rounded,
    Icons.credit_card_rounded,
    Icons.clean_hands_rounded,
  ];

  static const List<Color> _kAvailableColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addCategory() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'សូមបញ្ចូលឈ្មោះប្រភេទ');
      return;
    }

    final exists = widget.customCategories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      setState(() => _errorText = 'ប្រភេទនេះមានរួចហើយ');
      return;
    }

    final newCat = Category(
      name,
      _selectedIcon,
      _selectedColor,
      isExpense: _isExpense,
      isCustom: true,
    );

    final updated = List<Category>.from(widget.customCategories)..add(newCat);
    widget.onCategoriesChanged(updated);
    _nameCtrl.clear();
    setState(() => _errorText = null);
  }

  void _deleteCategory(Category cat) {
    final updated = List<Category>.from(widget.customCategories)
      ..removeWhere((c) => c.name == cat.name);
    widget.onCategoriesChanged(updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 22,
          right: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'គ្រប់គ្រងប្រភេទផ្ទាល់ខ្លួន',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(34, 34),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

            // Type tab
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _typeOption('ប្រភេទចំណាយ', true, AppColors.expense),
                  _typeOption('ប្រភេទចំណូល', false, AppColors.income),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'ឈ្មោះប្រភេទថ្មី',
                errorText: _errorText,
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                  onPressed: _addCategory,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'ជ្រើសរើស Icon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kAvailableIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final icon = _kAvailableIcons[i];
                  final selected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: selected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: selected ? _selectedColor : Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'ជ្រើសរើស ពណ៌',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kAvailableColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final color = _kAvailableColors[i];
                  final selected = color == _selectedColor;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            if (widget.customCategories.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'ប្រភេទផ្ទាល់ខ្លួនរបស់អ្នក (${widget.customCategories.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ...widget.customCategories.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c.icon, color: c.color, size: 20),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.isExpense ? 'ចំណាយ' : 'ចំណូល'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () => _deleteCategory(c),
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'រួចរាល់',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _typeOption(String label, bool isExp, Color color) {
    final selected = _isExpense == isExp;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = isExp),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
