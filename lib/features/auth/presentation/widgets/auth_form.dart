import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final String formTitle;
  final String buttonLabel;
  final bool isLoading;
  final void Function(String email, String password) onSubmit;

  const AuthForm({
    super.key,
    required this.formTitle,
    required this.buttonLabel,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.formTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'メールアドレス'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _email = value,
            validator: (value) => value == null || value.isEmpty ? 'メールアドレスを入力してください' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'パスワード'),
            obscureText: true,
            onChanged: (value) => _password = value,
            validator: (value) => value == null || value.length < 6 ? '6文字以上で入力してください' : null,
          ),
          const SizedBox(height: 24),
          widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(_email, _password);
              }
            },
            child: Text(widget.buttonLabel),
          ),
        ],
      ),
    );
  }
}