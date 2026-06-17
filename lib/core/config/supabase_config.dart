class SupabaseConfig {
  static const url = 'https://sxeiaobyzvhdgqjstycr.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4ZWlhb2J5enZoZGdxanN0eWNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NDg0NzYsImV4cCI6MjA5NDEyNDQ3Nn0.l79s2-O5T3EAB3_o-DP4lj3GmawAu63lO9pF7nqYLjM';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
