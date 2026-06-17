import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  String apiKey;
  String model;

  static const defaultModel = 'llama-3.1-8b-instant';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

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

  String context = '';

  GroqService({required this.apiKey, required this.model});

  final http.Client _client = http.Client();

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

  Stream<String> chat(List<Map<String, String>> history) async* {
    if (apiKey.isEmpty) {
      throw Exception(
        'API Key não configurada.\n'
        'Toque em ⚙️ e insira sua chave da Groq.\n'
        'Crie uma gratuitamente em console.groq.com/keys',
      );
    }

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': _fullSystemPrompt},
        ...history,
      ],
      'stream': true,
    });

    final response = await _client.send(request);
    if (response.statusCode == 401) {
      throw Exception(
        'API Key inválida ou expirada.\n'
        'Toque em ⚙️ e verifique sua chave da Groq.',
      );
    }
    if (response.statusCode == 429) {
      throw Exception(
        'Limite de requisições atingido.\n'
        'Aguarde alguns segundos e tente novamente.',
      );
    }
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Groq retornou erro ${response.statusCode}:\n$body');
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final jsonStr = line.substring(6).trim();
      if (jsonStr == '[DONE]') break;
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;
        final delta = (choices[0] as Map<String, dynamic>)['delta']
            as Map<String, dynamic>?;
        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
      } catch (_) {
        continue;
      }
    }
  }

  Future<bool> isAvailable() async {
    if (apiKey.isEmpty) return false;
    try {
      final response = await _client
          .get(
            Uri.parse('https://api.groq.com/openai/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
