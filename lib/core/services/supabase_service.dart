import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client;
  }
}
