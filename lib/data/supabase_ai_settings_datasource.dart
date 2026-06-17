import 'package:barber_hub/core/services/supabase_service.dart';

class AiSettings {
  final String apiKey;
  final String model;
  const AiSettings({required this.apiKey, required this.model});
}

class SupabaseAiSettingsDatasource {
  bool get isConfigured => SupabaseService.client != null;

  Future<AiSettings?> load() async {
    final client = SupabaseService.client;
    if (client == null) return null;

    final row =
        await client.from('ai_settings').select().eq('id', true).maybeSingle();
    if (row == null) return null;

    return AiSettings(
      apiKey: (row['api_key'] as Object?)?.toString() ?? '',
      model: (row['model'] as Object?)?.toString() ?? '',
    );
  }

  Future<void> save({required String apiKey, required String model}) async {
    final client = SupabaseService.client;
    if (client == null) return;

    await client.from('ai_settings').update({
      'api_key': apiKey,
      'model': model,
      'updated_by': client.auth.currentUser?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', true);
  }
}
