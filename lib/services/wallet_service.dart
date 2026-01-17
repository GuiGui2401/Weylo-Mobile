import '../core/constants/api_constants.dart';
import '../models/wallet.dart';
import 'api_client.dart';

/// Parse une valeur en double, qu'elle soit String, int, double ou null
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Parse une valeur en List de manière sécurisée
List _safeList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value;
  return [];
}

class WalletService {
  final ApiClient _apiClient = ApiClient();

  Future<double> getBalance() async {
    final response = await _apiClient.get(ApiConstants.wallet);
    return _parseDouble(response.data['balance'] ?? response.data['wallet_balance']);
  }

  // Alias for wallet provider
  Future<Map<String, dynamic>> getWallet() async {
    final response = await _apiClient.get(ApiConstants.wallet);
    return response.data;
  }

  // Alias for withdraw
  Future<Withdrawal> withdraw({
    required double amount,
    required String provider,
    required String phoneNumber,
  }) async {
    return requestWithdrawal(
      amount: amount,
      provider: provider,
      phoneNumber: phoneNumber,
    );
  }

  Future<List<WalletTransaction>> getTransactions({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.walletTransactions,
      queryParameters: {'page': page},
    );
    final data = _safeList(response.data['transactions'] ?? response.data['data']);
    return data.map((t) => WalletTransaction.fromJson(t)).toList();
  }

  Future<WalletStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.walletStats);
    return WalletStats.fromJson(response.data);
  }

  Future<List<WithdrawalMethod>> getWithdrawalMethods() async {
    final response = await _apiClient.get(ApiConstants.walletWithdrawalMethods);
    final data = _safeList(response.data['methods'] ?? response.data['data']);
    return data.map((m) => WithdrawalMethod.fromJson(m)).toList();
  }

  Future<DepositInitResponse> initiateDeposit({
    required double amount,
    String provider = 'ligos',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.walletDeposit,
      data: {
        'amount': amount,
        'provider': provider,
      },
    );
    return DepositInitResponse.fromJson(response.data);
  }

  Future<Withdrawal> requestWithdrawal({
    required double amount,
    required String provider,
    required String phoneNumber,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.walletWithdraw,
      data: {
        'amount': amount,
        'provider': provider,
        'phone_number': phoneNumber,
      },
    );
    return Withdrawal.fromJson(response.data['withdrawal'] ?? response.data);
  }

  Future<List<Withdrawal>> getWithdrawals({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.walletWithdrawals,
      queryParameters: {'page': page},
    );
    final data = _safeList(response.data['withdrawals'] ?? response.data['data']);
    return data.map((w) => Withdrawal.fromJson(w)).toList();
  }

  Future<Withdrawal> getWithdrawal(int id) async {
    final response = await _apiClient.get('${ApiConstants.walletWithdrawals}/$id');
    return Withdrawal.fromJson(response.data['withdrawal'] ?? response.data);
  }

  Future<bool> cancelWithdrawal(int id) async {
    final response = await _apiClient.delete('${ApiConstants.walletWithdrawals}/$id');
    return response.data['success'] ?? true;
  }
}

class DepositInitResponse {
  final String paymentUrl;
  final String reference;
  final double amount;

  DepositInitResponse({
    required this.paymentUrl,
    required this.reference,
    required this.amount,
  });

  factory DepositInitResponse.fromJson(Map<String, dynamic> json) {
    return DepositInitResponse(
      paymentUrl: json['payment_url'] ?? json['paymentUrl'] ?? '',
      reference: json['reference'] ?? '',
      amount: _parseDouble(json['amount']),
    );
  }
}
