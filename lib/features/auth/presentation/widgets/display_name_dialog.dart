// lib/features/auth/presentation/widgets/display_name_dialog.dart
import 'package:flutter/material.dart';

class DisplayNameDialog extends StatefulWidget {
  final String? initialName;

  const DisplayNameDialog({super.key, this.initialName});

  @override
  State<DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<DisplayNameDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('名前を設定'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '名前',
            hintText: 'あなたの表示名を入力してください',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '名前を入力してください';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_nameController.text.trim());
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
