import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://bmpfpvxprhazwuhogkcf.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtcGZwdnhwcmhhend1aG9na2NmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgyMDc1MCwiZXhwIjoyMDg1Mzk2NzUwfQ.VgFeGNGL51R3WyC1jrvMU86YaqxEp_voyKOoIY-psLg',
  );

  try {
    print('Trying to insert a test profile without user_id (since RLS is disabled)');
    final response = await supabase.from('sub_profiles').insert({
      'name': 'Test Profile',
    }).select().single();
    
    print('Success: $response');
  } catch (e) {
    print('Error: $e');
  }
}
