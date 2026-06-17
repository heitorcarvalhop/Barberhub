import 'package:flutter/services.dart';

/// Validadores reutilizáveis para campos de formulário.
class Validators {
  static final RegExp _nonDigits = RegExp(r'[^0-9]');
  static final RegExp _allSameDigit = RegExp(r'^(\d)\1*$');

  /// Formatters para campos de telefone: aceita só dígitos e limita ao
  /// tamanho máximo de um número brasileiro com DDD (11 dígitos).
  static List<TextInputFormatter> phoneInputFormatters({int maxDigits = 11}) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxDigits),
      ];

  /// Valida número de telefone brasileiro (fixo: 10 dígitos, celular: 11),
  /// aceitando formatação livre — parênteses, espaços, hífen — e DDI +55
  /// opcional. Use [required] para exigir preenchimento; por padrão o campo
  /// vazio é considerado válido (telefone opcional). Rejeita números com
  /// dígitos repetidos ou em sequência (ex: 99999999999, 11987654321... não,
  /// mas 99912345678 ou 99911111111 sim).
  static String? phone(String? value, {bool required = false}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return required ? 'Telefone é obrigatório' : null;
    }

    var digits = raw.replaceAll(_nonDigits, '');
    if (digits.length > 11 && digits.startsWith('55')) {
      digits = digits.substring(digits.length - 11);
    }

    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido';
    }

    final ddd = int.tryParse(digits.substring(0, 2));
    if (ddd == null || ddd < 11 || ddd > 99) {
      return 'DDD inválido';
    }

    if (digits.length == 11 && digits[2] != '9') {
      return 'Celular deve começar com 9 após o DDD';
    }

    final local = digits.substring(2);
    if (_allSameDigit.hasMatch(local) || _isSequential(local)) {
      return 'Número inválido (dígitos repetidos ou em sequência)';
    }

    return null;
  }

  /// Detecta sequências crescentes ou decrescentes de passo 1 (ex: 91234567,
  /// 98765432) ao longo de todo o número local (após o DDD).
  static bool _isSequential(String s) {
    if (s.length < 4) return false;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < s.length; i++) {
      final diff = s.codeUnitAt(i) - s.codeUnitAt(i - 1);
      if (diff != 1) ascending = false;
      if (diff != -1) descending = false;
    }
    return ascending || descending;
  }

  static bool isValidPhone(String? value) => phone(value) == null;
}
