import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/barberhub_context_service.dart';
import '../../core/services/groq_service.dart';
import '../../data/supabase_ai_settings_datasource.dart';
import '../../theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  /// Só o ADM pode configurar (API key/modelo) — o cliente apenas conversa.
  final bool canConfigure;

  /// false quando a tela é embutida como aba (ex: dentro do AdminShell),
  /// onde "voltar" não deve fechar a seção inteira.
  final bool showBackButton;

  const AiAssistantScreen({
    super.key,
    this.canConfigure = false,
    this.showBackButton = true,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String _apiKey = '';
  String _model = GroqService.defaultModel;
  late final GroqService _ollama = GroqService(apiKey: _apiKey, model: _model);

  bool _isTyping = false;
  bool _isStreaming = false;
  bool _isSendActive = false;
  bool _contextLoaded = false;
  bool _contextHasData = false;
  String? _contextError;
  StreamSubscription<String>? _currentStream;

  final List<Map<String, String>> _history = [];
  final List<_ChatMessage> _messages = [
    _ChatMessage.assistant(
      'Olá! Sou o Barber IA, seu assistente do Barber Hub. '
      'Posso ajudar com dicas de corte, barba, produtos e como usar o app. O que você precisa?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final active = _controller.text.trim().isNotEmpty;
      if (active != _isSendActive) setState(() => _isSendActive = active);
    });
    _loadSettings();
    _loadContext();
  }

  Future<void> _loadContext() async {
    if (!mounted) return;
    setState(() {
      _contextLoaded = false;
      _contextHasData = false;
      _contextError = null;
    });
    final result = await BarberhubContextService.build();
    if (!mounted) return;
    setState(() {
      _ollama.context = result.context;
      _contextLoaded = true;
      _contextHasData = result.context.isNotEmpty;
      _contextError = result.error;
    });
  }

  final _aiSettingsDatasource = SupabaseAiSettingsDatasource();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var apiKey = prefs.getString('groq_api_key') ?? '';
    var model = prefs.getString('groq_model') ?? GroqService.defaultModel;

    if (_aiSettingsDatasource.isConfigured) {
      try {
        final remote = await _aiSettingsDatasource.load();
        if (remote != null && remote.apiKey.isNotEmpty) {
          apiKey = remote.apiKey;
          model = remote.model.isEmpty ? model : remote.model;
          await prefs.setString('groq_api_key', apiKey);
          await prefs.setString('groq_model', model);
        }
      } catch (_) {
        // mantém o cache local em caso de falha de rede
      }
    }

    if (!mounted) return;
    setState(() {
      _apiKey = apiKey;
      _model = model;
      _ollama.apiKey = apiKey;
      _ollama.model = model;
    });
  }

  Future<void> _saveSettings(String apiKey, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', apiKey);
    await prefs.setString('groq_model', model);
    if (_aiSettingsDatasource.isConfigured) {
      try {
        await _aiSettingsDatasource.save(apiKey: apiKey, model: model);
      } catch (_) {
        // configuração local já foi salva; tenta novamente na próxima sincronização
      }
    }
    setState(() {
      _apiKey = apiKey;
      _model = model;
      _ollama.apiKey = apiKey;
      _ollama.model = model;
    });
  }

  @override
  void dispose() {
    _currentStream?.cancel();
    _ollama.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? shortcut]) async {
    if (_isTyping || _isStreaming) return;
    final text = (shortcut ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isTyping = true;
    });
    _history.add({'role': 'user', 'content': text});
    _scrollToBottom();

    final assistantMsg = _ChatMessage.assistant('');
    bool isFirstChunk = true;
    final buffer = StringBuffer();

    try {
      _currentStream = _ollama.chat(List.from(_history)).listen(
        (chunk) {
          buffer.write(chunk);
          if (isFirstChunk) {
            isFirstChunk = false;
            setState(() {
              _isTyping = false;
              _isStreaming = true;
              _messages.add(assistantMsg);
            });
          }
          setState(() => assistantMsg.text = buffer.toString());
          _scrollToBottom();
        },
        onDone: () {
          if (isFirstChunk) {
            setState(() {
              _isTyping = false;
              _isStreaming = false;
              _messages.add(_ChatMessage.assistant('(Sem resposta do modelo)'));
            });
            return;
          }
          _history.add({'role': 'assistant', 'content': buffer.toString()});
          if (_history.length > 20) _history.removeRange(0, _history.length - 20);
          setState(() => _isStreaming = false);
        },
        onError: (error) {
          final msg = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : 'Erro de conexão. Toque em ⚙️ e use "Testar conexão".';
          setState(() {
            _isTyping = false;
            _isStreaming = false;
            if (isFirstChunk) {
              _messages.add(_ChatMessage.assistant(msg));
            }
          });
        },
        cancelOnError: true,
      );
    } catch (_) {
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _messages.add(_ChatMessage.assistant(
          'Erro ao conectar ao Ollama. Toque no ⚙️ para verificar as configurações.',
        ));
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: _SettingsSheet(
            initialApiKey: _apiKey,
            initialModel: _model,
            onSave: (apiKey, model) async {
              await _saveSettings(apiKey, model);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isTyping || _isStreaming;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildChips(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  return _Bubble(message: _messages[index]);
                },
              ),
            ),
            _InputBar(
              controller: _controller,
              isSendActive: _isSendActive && !busy,
              isTyping: busy,
              onSend: () => _send(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.textPrimary,
            ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.background, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barber IA',
                  style: GoogleFonts.jost(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Groq · $_model',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jost(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!_contextLoaded)
                      const SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.gold,
                        ),
                      )
                    else if (_contextHasData)
                      const Tooltip(
                        message: 'Dados do app carregados',
                        child: Icon(
                          Icons.storage_rounded,
                          size: 11,
                          color: AppTheme.gold,
                        ),
                      )
                    else
                      Tooltip(
                        message: _contextError ?? 'Sem dados do banco',
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _contextLoaded ? _loadContext : null,
            icon: const Icon(Icons.sync_rounded),
            color: _contextLoaded ? AppTheme.textSecondary : AppTheme.inputBorder,
            tooltip: 'Atualizar dados do app',
          ),
          if (widget.canConfigure)
            IconButton(
              onPressed: _showSettings,
              icon: const Icon(Icons.settings_outlined),
              color: AppTheme.textSecondary,
              tooltip: 'Configurações da IA',
            ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _PromptChip(
            label: 'Entrevista',
            icon: Icons.work_outline_rounded,
            onTap: () => _send('Qual estilo de cabelo combina para uma entrevista de emprego?'),
          ),
          _PromptChip(
            label: 'Degradê',
            icon: Icons.content_cut_rounded,
            onTap: () => _send('Me explica os tipos de degradê e qual combina mais com rosto redondo'),
          ),
          _PromptChip(
            label: 'Barba',
            icon: Icons.face_rounded,
            onTap: () => _send('Dicas para cuidar e hidratar a barba'),
          ),
          _PromptChip(
            label: 'Produtos',
            icon: Icons.shopping_bag_outlined,
            onTap: () => _send('Que produtos masculinos usar no cabelo e barba?'),
          ),
          _PromptChip(
            label: 'Agendar',
            icon: Icons.calendar_month_outlined,
            onTap: () => _send('Como faço para agendar um serviço no Barber Hub?'),
          ),
          _PromptChip(
            label: 'Tendências',
            icon: Icons.trending_up_rounded,
            onTap: () => _send('Quais são as tendências de corte masculino em 2025?'),
          ),
        ],
      ),
    );
  }
}

// ─── Message Model ─────────────────────────────────────────────────────────────

class _ChatMessage {
  final bool isUser;
  String text;

  _ChatMessage.user(this.text) : isUser = true;
  _ChatMessage.assistant(this.text) : isUser = false;
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  final String initialApiKey;
  final String initialModel;
  final Future<void> Function(String apiKey, String model) onSave;

  const _SettingsSheet({
    required this.initialApiKey,
    required this.initialModel,
    required this.onSave,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _modelCtrl;
  bool _saving = false;
  bool _testing = false;
  bool? _testResult;
  bool _tutorialExpanded = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController(text: widget.initialApiKey);
    _modelCtrl = TextEditingController(text: widget.initialModel);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final apiKey = _apiKeyCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (model.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(apiKey, model);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final tmp = GroqService(
      apiKey: _apiKeyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
    );
    final ok = await tmp.isAvailable();
    tmp.dispose();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Configurações da IA',
            style: GoogleFonts.jost(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('API Key da Groq'),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: _obscureKey,
            style: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              prefixIcon: const Icon(Icons.key_rounded,
                  color: AppTheme.textSecondary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          _fieldLabel('Modelo'),
          const SizedBox(height: 6),
          _textField(_modelCtrl, 'llama-3.1-8b-instant', Icons.psychology_outlined),
          const SizedBox(height: 8),
          Text(
            'Outros modelos: llama-3.3-70b-versatile, gemma2-9b-it',
            style: GoogleFonts.jost(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? 'Salvando...' : 'Salvar configurações'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find_rounded, size: 16),
                  label: Text(_testing ? 'Testando...' : 'Testar conexão'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.gold,
                    side: const BorderSide(color: AppTheme.gold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(width: 12),
                Icon(
                  _testResult! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _testResult! ? const Color(0xFF4CAF50) : Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  _testResult! ? 'Conectado!' : 'Chave inválida',
                  style: GoogleFonts.jost(
                    color: _testResult!
                        ? const Color(0xFF4CAF50)
                        : Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://console.groq.com/keys'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Criar API Key gratuita no Groq'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.gold,
              textStyle: GoogleFonts.jost(fontSize: 12),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _tutorialExpanded = !_tutorialExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Como obter sua API Key gratuita',
                      style: GoogleFonts.jost(
                        color: AppTheme.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _tutorialExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.gold,
                  ),
                ],
              ),
            ),
          ),
          if (_tutorialExpanded) ...[
            const SizedBox(height: 16),
            _tutorialStep(
              '1',
              'Acesse o Groq',
              'Toque em "Criar API Key gratuita no Groq" acima\nou acesse console.groq.com',
            ),
            _tutorialStep(
              '2',
              'Crie uma conta gratuita',
              'Faça login com Google ou crie uma conta.\nNenhum cartão de crédito necessário.',
            ),
            _tutorialStep(
              '3',
              'Gere a API Key',
              'Vá em "API Keys" → "Create API Key".\nCopie a chave (começa com gsk_...).',
            ),
            _tutorialStep(
              '4',
              'Cole no campo acima',
              'Cole a chave no campo "API Key da Groq"\ne toque em "Salvar configurações".',
            ),
            const SizedBox(height: 4),
            _tipBox(
              'Gratuito e sem cartão',
              'O plano gratuito permite até 30 req/min e 14.400 req/dia — mais que suficiente para uso normal do app.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.jost(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _textField(
      TextEditingController ctrl, String hint, IconData prefixIcon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _tutorialStep(String num, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.jost(
                  color: AppTheme.background,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jost(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.jost(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipBox(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppTheme.gold, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.jost(
                  color: AppTheme.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.jost(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.gold
                          .withValues(alpha: 0.35 + _animations[i].value * 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _Bubble extends StatefulWidget {
  final _ChatMessage message;

  const _Bubble({required this.message});

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.12 : -0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.message.isUser ? _userBubble() : _assistantBubble(),
      ),
    );
  }

  Widget _userBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(2),
          ),
        ),
        child: Text(
          widget.message.text,
          style: GoogleFonts.jost(
            color: AppTheme.background,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _assistantBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: AppTheme.inputBorder),
              ),
              child: Text(
                widget.message.text,
                style: GoogleFonts.jost(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _AssistantAvatar extends StatelessWidget {
  final double size;
  const _AssistantAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        color: AppTheme.gold,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: AppTheme.background, size: size * 0.5),
    );
  }
}

// ─── Prompt Chip ──────────────────────────────────────────────────────────────

class _PromptChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PromptChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: onTap,
        label: Text(label),
        avatar: Icon(icon, size: 15),
        backgroundColor: AppTheme.surfaceElevated,
        side: const BorderSide(color: AppTheme.inputBorder),
        labelStyle: GoogleFonts.jost(color: AppTheme.textPrimary, fontSize: 12),
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSendActive;
  final bool isTyping;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSendActive,
    required this.isTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              enabled: !isTyping,
              style: GoogleFonts.jost(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: isTyping
                    ? 'Aguarde...'
                    : 'Pergunte sobre corte, barba, produtos...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedOpacity(
            opacity: isSendActive ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: 46,
              height: 46,
              child: ElevatedButton(
                onPressed: isSendActive ? onSend : null,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
