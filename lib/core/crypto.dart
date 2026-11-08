import 'i18n.dart';

// Crypto wallets: coins, networks and a quick format check of the address, same tables as
// frontend/src/utils/crypto.ts. The backend (app/core/crypto_address.py) also checks each checksum.

const cryptoCurrencies = {
  'USDT': 'USDT (Tether)',
  'USDC': 'USDC (USD Coin)',
  'BTC': 'BTC (Bitcoin)',
  'ETH': 'ETH (Ethereum)',
};

const cryptoNetworks = {
  'TRC20': 'TRC20 (Tron)',
  'ERC20': 'ERC20 (Ethereum)',
  'BEP20': 'BEP20 (BNB Smart Chain)',
  'POLYGON': 'Polygon',
  'SOLANA': 'Solana',
  'BITCOIN': 'Bitcoin',
};

/// Which coin can be received on which network.
const networksByCurrency = {
  'USDT': ['TRC20', 'ERC20', 'BEP20', 'POLYGON', 'SOLANA'],
  'USDC': ['ERC20', 'BEP20', 'POLYGON', 'SOLANA'],
  'ETH': ['ERC20'],
  'BTC': ['BITCOIN'],
};

const addressHints = {
  'TRC20': 'T… (34)',
  'ERC20': '0x… (42)',
  'BEP20': '0x… (42)',
  'POLYGON': '0x… (42)',
  'SOLANA': '32–44',
  'BITCOIN': '1… / 3… / bc1…',
};

const _base58 = '[1-9A-HJ-NP-Za-km-z]';
final _formats = {
  'TRC20': RegExp('^T$_base58{33}\$'),
  'ERC20': RegExp(r'^0x[0-9a-fA-F]{40}$'),
  'BEP20': RegExp(r'^0x[0-9a-fA-F]{40}$'),
  'POLYGON': RegExp(r'^0x[0-9a-fA-F]{40}$'),
  'SOLANA': RegExp('^$_base58{32,44}\$'),
  'BITCOIN': RegExp('^((1|3)$_base58{25,34}|(bc1|BC1)[02-9ac-hj-np-zAC-HJ-NP-Z]{11,87})\$'),
};

/// Format error for this network, or null when the address looks right.
String? cryptoAddressError(String network, String address, Translate t) {
  final a = address.trim();
  if (a.isEmpty) return t('Enter your wallet address.', "Saisissez l'adresse de votre portefeuille.", 'Ingresa la dirección de tu billetera.');
  if (_formats[network]?.hasMatch(a) ?? false) return null;
  switch (network) {
    case 'TRC20':
      return t('A TRC20 address starts with T and has 34 characters.', 'Une adresse TRC20 commence par T et contient 34 caractères.', 'Una dirección TRC20 empieza por T y tiene 34 caracteres.');
    case 'SOLANA':
      return t('A Solana address has 32 to 44 characters, without 0, O, I or l.', 'Une adresse Solana contient 32 à 44 caractères, sans 0, O, I ni l.', 'Una dirección Solana tiene de 32 a 44 caracteres, sin 0, O, I ni l.');
    case 'BITCOIN':
      return t('A Bitcoin address starts with 1, 3 or bc1.', 'Une adresse Bitcoin commence par 1, 3 ou bc1.', 'Una dirección Bitcoin empieza por 1, 3 o bc1.');
    default:
      final name = cryptoNetworks[network];
      return t(
        'A $name address starts with 0x followed by 40 characters (0-9, a-f).',
        'Une adresse $name commence par 0x suivi de 40 caractères (0-9, a-f).',
        'Una dirección $name empieza por 0x seguido de 40 caracteres (0-9, a-f).',
      );
  }
}
