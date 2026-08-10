import '../models/supplier.dart';
import 'api_client.dart';

class SupplierService {
  final ApiClient _client;

  SupplierService(this._client);

  Future<List<Supplier>> getSuppliers(String businessId) async {
    final response = await _client.get<Map<String, dynamic>>(
        '/suppliers/business/$businessId');
    final body = response.data as Map<String, dynamic>? ?? {};
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final response =
        await _client.post<Map<String, dynamic>>('/suppliers', data: data);
    final body = response.data as Map<String, dynamic>;
    return Supplier.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Supplier> updateSupplier(
      String supplierId, Map<String, dynamic> data) async {
    final response = await _client.put<Map<String, dynamic>>(
        '/suppliers/$supplierId',
        data: data);
    final body = response.data as Map<String, dynamic>;
    return Supplier.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _client.delete('/suppliers/$supplierId');
  }

  Future<List<SupplierPurchase>> getSupplierPurchases(
      String supplierId) async {
    final response = await _client
        .get<Map<String, dynamic>>('/suppliers/$supplierId/purchases');
    final body = response.data as Map<String, dynamic>? ?? {};
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((json) => SupplierPurchase.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier> recordPurchase(
      String supplierId, Map<String, dynamic> data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/suppliers/$supplierId/purchases',
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    return Supplier.fromJson(body['data'] as Map<String, dynamic>);
  }
}
