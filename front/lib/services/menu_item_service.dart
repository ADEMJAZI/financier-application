import 'package:dio/dio.dart';
import '../models/menu_item.dart';
import 'api_client.dart';

class MenuItemService {
  final ApiClient _client;

  MenuItemService(this._client);

  // Create a menu item
  Future<MenuItem> createMenuItem({
    required String businessId,
    required String name,
    required double sellingPrice,
    List<Map<String, dynamic>>? recipe,
  }) async {
    try {
      final requestData = {
        'business': businessId,
        'name': name,
        'sellingPrice': sellingPrice,
      };
      
      if (recipe != null && recipe.isNotEmpty) {
        requestData['recipe'] = recipe;
      }

      final response = await _client.post<Map<String, dynamic>>(
        '/menu-items',
        data: requestData,
      );

      return MenuItem.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('A menu item with this name already exists');
      }
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Invalid request';
        throw Exception(message);
      }
      rethrow;
    }
  }

  // Get menu items by business
  Future<List<MenuItem>> getMenuItemsByBusiness(
    String businessId, {
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final response = await _client.get<Map<String, dynamic>>(
        '/menu-items/business/$businessId',
        queryParameters: queryParams,
      );

      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Update a menu item
  Future<MenuItem> updateMenuItem({
    required String id,
    String? name,
    double? sellingPrice,
    bool? isActive,
    List<Map<String, dynamic>>? recipe,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (sellingPrice != null) data['sellingPrice'] = sellingPrice;
      if (isActive != null) data['isActive'] = isActive;
      if (recipe != null) data['recipe'] = recipe;

      final response = await _client.put<Map<String, dynamic>>(
        '/menu-items/$id',
        data: data,
      );

      return MenuItem.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('A menu item with this name already exists');
      }
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Update failed';
        throw Exception(message);
      }
      rethrow;
    }
  }

  // Deactivate a menu item (soft delete)
  Future<MenuItem> deactivateMenuItem(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/menu-items/$id/deactivate',
      );

      return MenuItem.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Menu item not found');
      }
      rethrow;
    }
  }

  // Delete a menu item (hard delete - only if no sales)
  Future<void> deleteMenuItem(String id) async {
    try {
      await _client.delete<Map<String, dynamic>>('/menu-items/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 
            'Cannot delete menu item with recorded sales';
        throw Exception(message);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Menu item not found');
      }
      rethrow;
    }
  }
}
