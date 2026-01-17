import '../core/constants/api_constants.dart';
import '../models/monetization.dart';
import 'api_client.dart';

class MonetizationService {
  final ApiClient _apiClient = ApiClient();

  Future<MonetizationOverview> getOverview() async {
    final response = await _apiClient.get(ApiConstants.monetizationOverview);
    return MonetizationOverview.fromJson(response.data);
  }

  Future<List<MonetizationPayout>> getPayouts({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.monetizationPayouts,
      queryParameters: {'page': page.toString()},
    );
    final data = response.data['payouts'] ?? response.data['data'] ?? [];
    return (data as List).map((item) => MonetizationPayout.fromJson(item)).toList();
  }
}
