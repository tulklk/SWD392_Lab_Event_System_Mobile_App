import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/report.dart';

class ReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Get all reports (Admin only)
  Future<Result<List<Report>>> getAllReports() async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .order('ReportedDate', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e) {
      return Failure('Failed to fetch reports: $e');
    }
  }

  // Get reports by user ID (own reports)
  Future<Result<List<Report>>> getReportsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .eq('ReporterId', userId)
          .order('ReportedDate', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e) {
      return Failure('Failed to fetch user reports: $e');
    }
  }

  // Get pending reports (Admin only)
  Future<Result<List<Report>>> getPendingReports() async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .eq('Status', 0)
          .order('ReportedDate', ascending: true);

      final reports = (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e) {
      return Failure('Failed to fetch pending reports: $e');
    }
  }

  // Get report by ID
  Future<Result<Report>> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .eq('Id', reportId)
          .single();

      final report = Report.fromJson(response as Map<String, dynamic>);
      return Success(report);
    } catch (e) {
      return Failure('Failed to fetch report: $e');
    }
  }

  // Create new report (All users)
  Future<Result<Report>> createReport({
    required String title,
    String? description,
    required int type,
    String? imageUrl,
    required String reporterId,
  }) async {
    try {
      final now = DateTime.now();
      final reportId = _uuid.v4(); // Generate UUID for report
      
      final response = await _supabase
          .from('tbl_reports')
          .insert({
            'Id': reportId, // Add the generated UUID
            'Title': title,
            'Description': description,
            'Type': type,
            'ImageUrl': imageUrl,
            'ReportedDate': now.toIso8601String(),
            'Status': 0,
            'ReporterId': reporterId,
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final report = Report.fromJson(response as Map<String, dynamic>);
      return Success(report);
    } catch (e) {
      return Failure('Failed to create report: $e');
    }
  }

  // Update report status (Admin only)
  Future<Result<Report>> updateReportStatus({
    required String reportId,
    required int status,
    required String resolvedBy,
    String? adminResponse,
  }) async {
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'Status': status,
        'ResolvedBy': resolvedBy,
        'ResolvedAt': now.toIso8601String(),
        'LastUpdatedAt': now.toIso8601String(),
      };

      if (adminResponse != null) {
        updateData['AdminResponse'] = adminResponse;
      }

      final response = await _supabase
          .from('tbl_reports')
          .update(updateData)
          .eq('Id', reportId)
          .select()
          .single();

      final report = Report.fromJson(response as Map<String, dynamic>);
      return Success(report);
    } catch (e) {
      return Failure('Failed to update report status: $e');
    }
  }

  // Update report (Reporter can update if still pending)
  Future<Result<Report>> updateReport({
    required String reportId,
    String? title,
    String? description,
    int? type,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'LastUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['Title'] = title;
      if (description != null) updateData['Description'] = description;
      if (type != null) updateData['Type'] = type;
      if (imageUrl != null) updateData['ImageUrl'] = imageUrl;

      final response = await _supabase
          .from('tbl_reports')
          .update(updateData)
          .eq('Id', reportId)
          .select()
          .single();

      final report = Report.fromJson(response as Map<String, dynamic>);
      return Success(report);
    } catch (e) {
      return Failure('Failed to update report: $e');
    }
  }

  // Delete report (Admin only)
  Future<Result<void>> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('tbl_reports')
          .delete()
          .eq('Id', reportId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete report: $e');
    }
  }

  // Get reports by type
  Future<Result<List<Report>>> getReportsByType(int type) async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .eq('Type', type)
          .order('ReportedDate', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e) {
      return Failure('Failed to fetch reports by type: $e');
    }
  }

  // Get reports by status
  Future<Result<List<Report>>> getReportsByStatus(int status) async {
    try {
      final response = await _supabase
          .from('tbl_reports')
          .select()
          .eq('Status', status)
          .order('ReportedDate', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e) {
      return Failure('Failed to fetch reports by status: $e');
    }
  }
}

// Provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

