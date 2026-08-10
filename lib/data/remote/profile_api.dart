import 'api_client.dart';
import '../../models/profile_model.dart';

class ProfileApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<ProfileModel>> getProfiles() async {
    final res = await _client.get('/profiles');
    final list = res.data as List;
    return list.map((m) => ProfileModel.fromMap(m)).toList();
  }

  Future<ProfileModel> createProfile(ProfileModel profile) async {
    final res = await _client.post('/profiles', data: {
      'name': profile.name,
      'dob': profile.dob,
      'gender': profile.gender,
      'relationship': profile.relationship,
      'profile_type': profile.profileType,
      'prescription_type': profile.prescriptionType,
      'blurred_vision_type': profile.blurredVisionType,
      'symptoms': profile.symptoms,
    });
    return ProfileModel.fromMap(res.data);
  }

  Future<void> deleteProfile(String id) async {
    await _client.delete('/profiles/$id');
  }
}
