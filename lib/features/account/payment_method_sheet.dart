import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/crypto.dart';
import '../../core/i18n.dart';
import '../../theme/app_colors.dart';
import 'account_providers.dart';

/// Label of a payment detail key (« email_or_phone » → « Email or phone »).
String paymentFieldLabel(String key, Translate t) {
  const fr = {
    'email_or_phone': 'Email ou téléphone',
    'account_name': 'Nom du compte',
    'recipient_name': 'Nom du bénéficiaire',
    'currency': 'Devise',
    'wallet_address': 'Adresse du portefeuille',
    'network': 'Réseau',
    'cashtag': 'Cashtag',
    'handle': 'Identifiant',
    'phone': 'Téléphone',
    'phone_number': 'Numéro de téléphone',
    'full_name': 'Nom complet',
    'email': 'Email',
    'bank_name': 'Nom de la banque',
    'account_number': 'Numéro de compte',
    'routing_number': 'Routing / SWIFT',
    'account_holder': 'Titulaire du compte',
  };
  const es = {
    'email_or_phone': 'Correo o teléfono',
    'account_name': 'Nombre de la cuenta',
    'recipient_name': 'Nombre del beneficiario',
    'currency': 'Moneda',
    'wallet_address': 'Dirección de la billetera',
    'network': 'Red',
    'cashtag': 'Cashtag',
    'handle': 'Usuario',
    'phone': 'Teléfono',
    'phone_number': 'Número de teléfono',
    'full_name': 'Nombre completo',
    'email': 'Correo',
    'bank_name': 'Nombre del banco',
    'account_number': 'Número de cuenta',
    'routing_number': 'Routing / SWIFT',
    'account_holder': 'Titular de la cuenta',
  };
  final english = key.replaceAll('_', ' ');
  return t('${english[0].toUpperCase()}${english.substring(1)}', fr[key] ?? english, es[key] ?? english);
}

String providerLabel(String type, Translate t) => switch (type) {
      'ZELLE' => 'Zelle',
      'CASHAPP' => 'Cash App',
      'VIRTUAL_CURRENCY' => t('Crypto', 'Crypto', 'Cripto'),
      'BANK' => t('Bank transfer', 'Virement bancaire', 'Transferencia bancaria'),
      _ => type.replaceAll('_', ' '),
    };

const _providers = ['ZELLE', 'CASHAPP', 'VIRTUAL_CURRENCY', 'BANK'];

const _fieldsByProvider = {
  'ZELLE': ['email_or_phone', 'recipient_name'],
  'CASHAPP': ['cashtag', 'recipient_name'],
  'BANK': ['bank_name', 'account_number', 'routing_number', 'account_holder'],
};

class PaymentMethodSheet extends ConsumerStatefulWidget {
  const PaymentMethodSheet({super.key});

  @override
  ConsumerState<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends ConsumerState<PaymentMethodSheet> {
  String _provider = 'ZELLE';
  final _fields = <String, TextEditingController>{};
  String _currency = 'USDT';
  String _network = 'TRC20';
  final _wallet = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  void _resetFields() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _fields.clear();
    for (final key in _fieldsByProvider[_provider] ?? const <String>[]) {
      _fields[key] = TextEditingController(text: key == 'cashtag' ? r'$' : '');
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _wallet.dispose();
    super.dispose();
  }

  Future<void> _save(Translate t) async {
    setState(() => _error = null);
    final Map<String, String> details;
    if (_provider == 'VIRTUAL_CURRENCY') {
      final error = cryptoAddressError(_network, _wallet.text, t);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      details = {'currency': _currency, 'network': _network, 'wallet_address': _wallet.text.trim()};
    } else {
      details = {for (final e in _fields.entries) e.key: e.value.text.trim()};
      if (details.values.any((v) => v.isEmpty || v == r'$')) {
        setState(() => _error = t('Please fill in every field.', 'Veuillez remplir tous les champs.', 'Completa todos los campos.'));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountActionsProvider).addPaymentMethod(_provider, details);
      ref.invalidate(paymentMethodsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = apiErrorMessage(error, t('Something went wrong. Please try again.', 'Une erreur est survenue. Réessayez.', 'Algo salió mal. Inténtalo de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);
    final networks = networksByCurrency[_currency]!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('Add Receiving Payment Method', 'Ajouter un moyen de réception', 'Añadir un medio de cobro'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _provider,
                isExpanded: true,
                dropdownColor: AppColors.card,
                decoration: InputDecoration(labelText: t('Payment Provider Type', 'Type de moyen de paiement', 'Tipo de medio de pago')),
                items: [for (final p in _providers) DropdownMenuItem(value: p, child: Text(providerLabel(p, t)))],
                onChanged: (value) => setState(() {
                  _provider = value ?? _provider;
                  _error = null;
                  _resetFields();
                }),
              ),
              const SizedBox(height: 14),
              if (_provider == 'VIRTUAL_CURRENCY') ...[
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  decoration: InputDecoration(labelText: paymentFieldLabel('currency', t)),
                  items: [for (final e in cryptoCurrencies.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                  onChanged: (value) => setState(() {
                    _currency = value ?? _currency;
                    if (!networksByCurrency[_currency]!.contains(_network)) _network = networksByCurrency[_currency]!.first;
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(_currency),
                  initialValue: _network,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  decoration: InputDecoration(labelText: paymentFieldLabel('network', t)),
                  items: [for (final n in networks) DropdownMenuItem(value: n, child: Text(cryptoNetworks[n]!))],
                  onChanged: (value) => setState(() => _network = value ?? _network),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _wallet,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: paymentFieldLabel('wallet_address', t),
                    hintText: addressHints[_network],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t(
                    'Check the network: a payment sent on another network is lost.',
                    "Vérifiez le réseau : un paiement envoyé sur un autre réseau est perdu.",
                    'Revisa la red: un pago enviado por otra red se pierde.',
                  ),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFCD34D)),
                ),
              ] else
                for (final e in _fields.entries) ...[
                  TextField(
                    controller: e.value,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: paymentFieldLabel(e.key, t)),
                  ),
                  const SizedBox(height: 14),
                ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : () => _save(t),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _saving
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t('Save Method', 'Enregistrer', 'Guardar'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
