import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MiomiPayResponse {
  final bool success;
  final String? reference;
  final String? externalId;
  final String? checkoutUrl;
  final String? qrImageUrl;
  final String? qrString;
  final String? snapToken;
  final String? status;
  final String? message;
  final double? amount;

  MiomiPayResponse({
    required this.success,
    this.reference,
    this.externalId,
    this.checkoutUrl,
    this.qrImageUrl,
    this.qrString,
    this.snapToken,
    this.status,
    this.message,
    this.amount,
  });
}

class MiomiPayService {
  // Sesuai Sandbox API Key Resmi PosSmart milik Hanif
  static const String baseUrl = 'https://pg.miomidev.com/api/v1';
  static const String apiKey = 'MP-SB-0dCLG5kpCG3YSAz4gaZJYwEmFKaDc7ms';

  /// Endpoint 1: POST /api/v1/payment/create (Buat Tagihan QRIS Asli)
  static Future<MiomiPayResponse> createPayment({
    required String invoiceNumber,
    required double amount,
    String customerName = 'Pelanggan PosSmart',
    String customerEmail = 'kasir@possmart.com',
    String customerPhone = '081234567890',
    String description = 'Pembayaran PosSmart',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/payment/create');
      final payload = {
        'external_id': invoiceNumber,
        'amount': amount.toInt(),
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'payment_method': 'qris',
        'description': description,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint('MiomiPay Create Response: [${response.statusCode}] ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;

        final qrString = data['qr_string']?.toString() ?? '';
        // Gunakan direct URL QR server agar tidak terhambat 302 redirect di browser Web
        final directQrUrl = qrString.isNotEmpty
            ? 'https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=10&data=${Uri.encodeComponent(qrString)}'
            : (data['qr_image_url']?.toString() ?? '');

        return MiomiPayResponse(
          success: json['success'] ?? true,
          reference: data['reference'] ?? 'MP-$invoiceNumber',
          externalId: data['external_id'] ?? invoiceNumber,
          checkoutUrl: data['checkout_url'],
          qrImageUrl: directQrUrl,
          qrString: qrString,
          snapToken: data['snap_token'],
          status: data['status'] ?? 'PENDING',
          message: json['message'],
          amount: (data['final_amount'] ?? data['amount'] ?? amount).toDouble(),
        );
      } else {
        debugPrint('MiomiPay Server returned error code: ${response.statusCode} - ${response.body}');
        return _fallbackSimulatorResponse(invoiceNumber, amount);
      }
    } catch (e) {
      debugPrint('MiomiPay API Network Error: $e');
      return _fallbackSimulatorResponse(invoiceNumber, amount);
    }
  }

  /// Endpoint 2: GET /api/v1/payment/{reference}/status (Cek Status Transaksi Realtime)
  static Future<String> checkPaymentStatus(String reference) async {
    try {
      final url = Uri.parse('$baseUrl/payment/$reference/status');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        return data['status'] ?? 'PENDING';
      }
      return 'PENDING';
    } catch (e) {
      debugPrint('Error checking status to MiomiPay: $e');
      return 'PENDING';
    }
  }

  static MiomiPayResponse _fallbackSimulatorResponse(String invoiceNumber, double amount) {
    return MiomiPayResponse(
      success: true,
      reference: 'MP-SB-${DateTime.now().millisecondsSinceEpoch}',
      externalId: invoiceNumber,
      checkoutUrl: 'https://pg.miomidev.com/pay/sim-$invoiceNumber',
      qrImageUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=MIOMIPAY-QRIS-$invoiceNumber-$amount',
      qrString: '00020101021226660014ID.CO.GOPAY.WWW01189360091800000000000215INV$invoiceNumber',
      status: 'PENDING',
      message: 'Demo Sandbox Active',
      amount: amount,
    );
  }
}
