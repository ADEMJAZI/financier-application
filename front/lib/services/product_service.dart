import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  // Create a new product
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/products', data: data);
    final responseData = response.data as Map<String, dynamic>;
    // Support both wrapped and unwrapped responses
    final productData = responseData.containsKey('data')
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    return Product.fromJson(productData);
  }

  // Get products by business ID
  Future<List<Product>> getProductsByBusiness(String businessId) async {
    final response = await _apiClient.get('/products/business/$businessId');
    final responseData = response.data;

    List<dynamic> productList;
    if (responseData is List) {
      productList = responseData;
    } else if (responseData is Map && responseData.containsKey('data')) {
      productList = responseData['data'] as List;
    } else {
      productList = [];
    }

    return productList
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get product by ID
  Future<Product> getProductById(String id) async {
    final response = await _apiClient.get('/products/$id');
    final data = response.data as Map<String, dynamic>;
    final productData =
        data.containsKey('data') ? data['data'] as Map<String, dynamic> : data;
    return Product.fromJson(productData);
  }

  // Update product
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/products/$id', data: data);
    final responseData = response.data as Map<String, dynamic>;
    final productData = responseData.containsKey('data')
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    return Product.fromJson(productData);
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/products/$id');
  }

  // Restock product
  Future<Product> restockProduct(
      String id, double quantity, double? unitPrice) async {
    final data = <String, dynamic>{'quantity': quantity};
    if (unitPrice != null) data['unitPrice'] = unitPrice;
    final response = await _apiClient.post('/products/$id/restock', data: data);
    final responseData = response.data as Map<String, dynamic>;
    final productData = responseData.containsKey('data')
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    return Product.fromJson(productData);
  }
}

