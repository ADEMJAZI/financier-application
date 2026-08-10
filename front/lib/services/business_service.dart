import '../models/business.dart';
import 'api_client.dart';

class BusinessService {
  final ApiClient _apiClient;
  
  BusinessService(this._apiClient);
  
  // Create a new business
  Future<Business> createBusiness(Business business) async {
    final response = await _apiClient.post(
      '/businesses',
      data: business.toJson(),
    );
    
    final data = response.data as Map<String, dynamic>;
    return Business.fromJson(data['data'] as Map<String, dynamic>);
  }
  
  // Get all businesses
  Future<List<Business>> getBusinesses() async {
    final response = await _apiClient.get('/businesses');
    
    final data = response.data as Map<String, dynamic>;
    final businessList = data['data'] as List;
    
    return businessList
        .map((json) => Business.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  // Get business by ID
  Future<Business> getBusinessById(String id) async {
    final response = await _apiClient.get('/businesses/$id');
    
    final data = response.data as Map<String, dynamic>;
    return Business.fromJson(data['data'] as Map<String, dynamic>);
  }
  
  // Update business
  Future<Business> updateBusiness(String id, Business business) async {
    final response = await _apiClient.put(
      '/businesses/$id',
      data: business.toJson(),
    );
    
    final data = response.data as Map<String, dynamic>;
    return Business.fromJson(data['data'] as Map<String, dynamic>);
  }
  
  // Delete business
  Future<void> deleteBusiness(String id) async {
    await _apiClient.delete('/businesses/$id');
  }
}
