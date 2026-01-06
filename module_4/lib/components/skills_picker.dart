import 'package:flutter/material.dart';
import '../services/skills_service.dart';

/// A beautiful LinkedIn-style skills picker with autocomplete
class SkillsPicker extends StatefulWidget {
  final List<String> selectedSkills;
  final ValueChanged<List<String>> onSkillsChanged;
  final int maxSkills;

  const SkillsPicker({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
    this.maxSkills = 20,
  });

  @override
  State<SkillsPicker> createState() => _SkillsPickerState();
}

class _SkillsPickerState extends State<SkillsPicker> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _skillsService = SkillsService();

  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay hiding to allow tap on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _skillsService.searchSkills(query);

      // Filter out already selected skills
      final filtered = results
          .where(
            (s) => !widget.selectedSkills.any(
              (selected) => selected.toLowerCase() == s.toLowerCase(),
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _suggestions = filtered;
          _showSuggestions = filtered.isNotEmpty || query.trim().isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _addSkill(String skill) {
    if (widget.selectedSkills.length >= widget.maxSkills) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxSkills} skills allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for duplicates (case-insensitive)
    if (widget.selectedSkills.any(
      (s) => s.toLowerCase() == skill.toLowerCase(),
    )) {
      return;
    }

    final newSkills = [...widget.selectedSkills, skill];
    widget.onSkillsChanged(newSkills);

    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _addCustomSkill() {
    final customSkill = _searchController.text.trim();
    if (customSkill.isEmpty) return;

    // Normalize the skill name
    final normalizedSkill = customSkill
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.toUpperCase() == word && word.length <= 5) {
            return word; // Keep acronyms
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    _addSkill(normalizedSkill);

    // Also add to Firebase for future suggestions
    _skillsService.addCustomSkill(normalizedSkill);
  }

  void _removeSkill(String skill) {
    final newSkills = widget.selectedSkills.where((s) => s != skill).toList();
    widget.onSkillsChanged(newSkills);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Skills Chips
        if (widget.selectedSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedSkills.map((skill) {
              return _buildSkillChip(skill);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Search Input with Suggestions
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? const Color(0xFF0F1E3C)
                      : Colors.grey.shade300,
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _addCustomSkill(),
                decoration: InputDecoration(
                  hintText: widget.selectedSkills.isEmpty
                      ? 'Search skills (e.g. Python, Flutter, Marketing...)'
                      : 'Add more skills...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF0F1E3C),
                          ),
                          onPressed: _addCustomSkill,
                          tooltip: 'Add custom skill',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Suggestions Dropdown
            if (_showSuggestions) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _suggestions.isEmpty
                      ? _buildAddCustomOption()
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount:
                              _suggestions.length + 1, // +1 for custom option
                          itemBuilder: (context, index) {
                            if (index == _suggestions.length) {
                              return _buildAddCustomOption();
                            }
                            return _buildSuggestionItem(_suggestions[index]);
                          },
                        ),
                ),
              ),
            ],
          ],
        ),

        // Helper text
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.selectedSkills.length}/${widget.maxSkills} skills added. '
                'Type to search or add custom skills.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F1E3C).withValues(alpha: 0.1),
            const Color(0xFF0F1E3C).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0F1E3C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              color: Color(0xFF0F1E3C),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E3C).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF0F1E3C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String skill) {
    return InkWell(
      onTap: () => _addSkill(skill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E3C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.label_outline,
                size: 16,
                color: Color(0xFF0F1E3C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.add, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomOption() {
    final customSkill = _searchController.text.trim();
    if (customSkill.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _addCustomSkill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.add_circle_outline,
                size: 16,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Add "'),
                    TextSpan(
                      text: customSkill,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '" as custom skill'),
                  ],
                ),
              ),
            ),
            Icon(Icons.keyboard_return, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
