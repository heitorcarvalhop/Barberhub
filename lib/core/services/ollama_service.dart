import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OllamaService {
  String host;
  String model;

  // Web/Desktop: localhost. Emulador Android: 10.0.2.2. Dispositivo físico: IP LAN do PC.
  static String get defaultHost {
    if (kIsWeb) return 'http://localhost:11434';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 funciona apenas no emulador Android.
      // Em dispositivo físico, configure o IP LAN do PC nas ⚙️ Configurações.
      return 'http://10.0.2.2:11434';
    }
    return 'http://localhost:11434';
  }

  static const defaultModel = 'llama3.2';

  static const _systemPrompt =
      'Você é o "Barber IA", assistente virtual exclusivo do Barber Hub — um app de barbearia. '
      'Responda APENAS perguntas relacionadas a barbearia e ao app Barber Hub. '
      'Tópicos permitidos: cortes de cabelo, barba, degradê, estilos masculinos, cuidados capilares, '
      'produtos para cabelo/barba, agendamentos, barbearias, barbeiros, preços e serviços do app. '
      'Se a pergunta não tiver NENHUMA relação com barbearia ou o app, recuse educadamente com uma '
      'frase curta e redirecione para tópicos de barbearia. Exemplos de recusa: '
      '"Só consigo ajudar com temas de barbearia! Posso te indicar um corte ou te ajudar com seu agendamento?" '
      'Nunca responda perguntas de matemática, programação, política, culinária, ou qualquer outro tema fora de barbearia. '
      'Responda sempre em português brasileiro, de forma concisa (máximo 4 frases). '
      'Quando mencionar agendamentos, preços ou barbeiros, use apenas os dados do contexto fornecido — '
      'nunca invente informações.';

  /// Contexto dinâmico com dados reais do Supabase (agendamentos, barbearias, etc.).
  String context = '';

  OllamaService({required this.host, required this.model});

  final http.Client _client = http.Client();

  Stream<String> chat(List<Map<String, String>> history) async* {
    if (kIsWeb) {
      // Browsers não suportam streaming HTTP via XHR da mesma forma;
      // usa chamada única e emite o texto em blocos para simular digitação.
      yield* _chatWeb(history);
    } else {
      yield* _chatStreaming(history);
    }
  }

  String get _fullSystemPrompt {
    if (context.isEmpty) {
      return '$_systemPrompt\n\n'
          'AVISO CRÍTICO: Os dados do banco de dados não foram carregados. '
          'Se o usuário perguntar sobre barbearias, barbeiros, serviços ou produtos específicos, '
          'responda EXATAMENTE: "Não consegui carregar os dados do app no momento. '
          'Tente atualizar tocando no botão ↺ no topo da tela." '
          'Nunca invente nomes de barbearias, barbeiros, serviços ou produtos.';
    }
    return '$_systemPrompt\n\n$context';
  }

  Stream<String> _chatStreaming(List<Map<String, String>> history) async* {
    final request = http.Request('POST', Uri.parse('$host/api/chat'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': _fullSystemPrompt},
        ...history,
      ],
      'stream': true,
    });

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw Exception('Ollama retornou status ${response.statusCode}');
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty) continue;
      final data = jsonDecode(line) as Map<String, dynamic>;
      final content =
          (data['message'] as Map<String, dynamic>?)?['content'] as String? ?? '';
      if (content.isNotEmpty) yield content;
      if (data['done'] == true) break;
    }
  }

  Stream<String> _chatWeb(List<Map<String, String>> history) async* {
    late http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$host/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': _fullSystemPrompt},
            ...history,
          ],
          'stream': false,
        }),
      );
    } catch (_) {
      throw Exception(
        'Não foi possível conectar a $host.\n'
        'Verifique se o Ollama está rodando:\n'
        '  1. Abra $host no navegador\n'
        '  2. Deve aparecer "Ollama is running"\n'
        '  3. Se não abrir: execute "ollama serve" no terminal',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Modelo "$model" não encontrado.\n'
        'Baixe-o no terminal: ollama pull $model',
      );
    }
    if (response.statusCode != 200) {
      final body = response.body.isNotEmpty ? response.body : '—';
      throw Exception('Ollama retornou erro ${response.statusCode}:\n$body');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (data['message'] as Map<String, dynamic>?)?['content'] as String? ?? '';

    // Emite em blocos de ~15 caracteres para dar efeito de digitação
    const chunkSize = 15;
    for (int i = 0; i < content.length; i += chunkSize) {
      yield content.substring(i, (i + chunkSize).clamp(0, content.length));
      if (i + chunkSize < content.length) {
        await Future.delayed(const Duration(milliseconds: 18));
      }
    }
  }

  Future<bool> isAvailable() async {
    try {
      final response = await _client
          .get(Uri.parse('$host/api/tags'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
