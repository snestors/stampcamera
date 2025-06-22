import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/widgets/connectivity_app_bar.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .login(_usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = ref.watch(authProvider).value?.errorMessage;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: ConnectivityAppBarWithDetails(
        title: const Text('Iniciar Sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/logo_principal.png',

                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ej: nfarinas',
                      ),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true,
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ingresar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
