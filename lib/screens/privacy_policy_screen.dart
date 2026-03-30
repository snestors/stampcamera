import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/routes/app_router.dart' show markPrivacyPolicyAccepted;

class PrivacyAcceptanceScreen extends StatefulWidget {
  const PrivacyAcceptanceScreen({super.key});

  @override
  State<PrivacyAcceptanceScreen> createState() =>
      _PrivacyAcceptanceScreenState();
}

class _PrivacyAcceptanceScreenState extends State<PrivacyAcceptanceScreen> {
  bool _isAccepted = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _acceptPolicy() async {
    if (!_isAccepted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_policy_accepted', true);
    await prefs.setString('privacy_policy_version', '1.0');
    markPrivacyPolicyAccepted(); // Update in-memory cache

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003B5C),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.white),
                  //SizedBox(height: 16),
                  Image.asset('assets/splash/branding.png', height: 120),
                  const SizedBox(height: 1),
                  const Text(
                    'Aplicación de Inspección Vehicular',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'A&G Ajustadores y Peritos de Seguro',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Política de Privacidad y Uso',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003B5C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Por favor, lee y acepta los términos antes de continuar.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: BoxBorder.all(
                            color: Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _PolicySummarySection(
                                title: '📱 Uso Exclusivo Profesional',
                                content:
                                    'Esta aplicación es para trabajadores, inspectores y clientes autorizados de A&G Ajustadores únicamente.',
                              ),
                              _PolicySummarySection(
                                title: '📸 Fotografías Permitidas',
                                content:
                                    '• Solo mercaderías de clientes de A&G\n• Evidencias de inspección vehicular\n• Incidentes por mala praxis de proveedores',
                              ),
                              _PolicySummarySection(
                                title: '🚫 Estrictamente Prohibido',
                                content:
                                    '• Fotografías personales\n• Instalaciones de terceros (APM, DPW, etc.)\n• Mercaderías de no-clientes\n• Uso fuera del ámbito profesional',
                              ),
                              _PolicySummarySection(
                                title: '⚠️ Penalizaciones',
                                content:
                                    'El mal uso resultará en penalizaciones y suspensión del acceso a la aplicación.',
                              ),
                              _PolicySummarySection(
                                title: '🔒 Seguridad',
                                content:
                                    'Todas las fotografías se almacenan en servidores seguros de A&G Ajustadores.',
                              ),
                              _PolicySummarySection(
                                title: '📞 Contacto',
                                content:
                                    'A&G Ajustadores y Peritos de Seguro\nwww.aygajustadores.com',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAccepted,
                          onChanged: _hasScrolledToBottom
                              ? (value) {
                                  setState(() {
                                    _isAccepted = value ?? false;
                                  });
                                }
                              : null,
                          activeColor: const Color(0xFF003B5C),
                        ),
                        const Expanded(
                          child: Text(
                            'He leído y acepto la Política de Privacidad y me comprometo a usar la aplicación exclusivamente para fines profesionales autorizados.',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),

                    if (!_hasScrolledToBottom)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Desplázate hacia abajo para continuar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAccepted ? _acceptPolicy : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003B5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Aceptar y Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySummarySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySummarySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003B5C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
