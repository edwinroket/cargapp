import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _verPassword  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok   = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error al iniciar sesión'),
                 backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(  // ← agregar esto
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('CargApp',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16a34a))),
                const SizedBox(height: 4),
                Text('Encuentra la bencina más barata',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText   : 'Email',
                    prefixIcon  : Icon(Icons.email_outlined),
                    border      : OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Ingresa tu email' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller  : _passwordCtrl,
                  obscureText : !_verPassword,
                  decoration  : InputDecoration(
                    labelText : 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border    : const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_verPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: auth.cargando ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: auth.cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar sesión',
                          style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegistroScreen())),
                  child: const Text('¿No tienes cuenta? Regístrate',
                      style: TextStyle(color: Color(0xFF16a34a))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}