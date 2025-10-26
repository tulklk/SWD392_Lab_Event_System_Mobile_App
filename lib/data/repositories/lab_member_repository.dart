import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/result.dart';
import '../../domain/models/lab_member.dart';

class LabMemberRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all lab members
  Future<Result<List<LabMember>>> getAllLabMembers() async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .select()
          .order('JoinedAt', ascending: false);

      final members = (response as List)
          .map((json) => LabMember.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(members);
    } catch (e) {
      return Failure('Failed to fetch lab members: $e');
    }
  }

  // Get members by lab ID
  Future<Result<List<LabMember>>> getMembersByLabId(String labId) async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .select()
          .eq('LabId', labId)
          .eq('Status', 1)
          .order('Role', ascending: false); // Leaders first

      final members = (response as List)
          .map((json) => LabMember.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(members);
    } catch (e) {
      return Failure('Failed to fetch lab members: $e');
    }
  }

  // Get labs by user ID
  Future<Result<List<LabMember>>> getLabsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .select()
          .eq('UserId', userId)
          .eq('Status', 1)
          .order('JoinedAt', ascending: false);

      final members = (response as List)
          .map((json) => LabMember.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(members);
    } catch (e) {
      return Failure('Failed to fetch user labs: $e');
    }
  }

  // Get lab member by ID
  Future<Result<LabMember>> getMemberById(String memberId) async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .select()
          .eq('Id', memberId)
          .single();

      final member = LabMember.fromJson(response as Map<String, dynamic>);
      return Success(member);
    } catch (e) {
      return Failure('Failed to fetch lab member: $e');
    }
  }

  // Add member to lab (Lecturer/Admin only)
  Future<Result<LabMember>> addMember({
    required String labId,
    required String userId,
    int role = 0,
  }) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_lab_members')
          .insert({
            'LabId': labId,
            'UserId': userId,
            'Role': role,
            'Status': 1,
            'JoinedAt': now.toIso8601String(),
            'CreatedAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .select()
          .single();

      final member = LabMember.fromJson(response as Map<String, dynamic>);
      return Success(member);
    } catch (e) {
      return Failure('Failed to add lab member: $e');
    }
  }

  // Update member role (Lecturer/Admin only)
  Future<Result<LabMember>> updateMemberRole({
    required String memberId,
    required int role,
  }) async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .update({
            'Role': role,
            'LastUpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('Id', memberId)
          .select()
          .single();

      final member = LabMember.fromJson(response as Map<String, dynamic>);
      return Success(member);
    } catch (e) {
      return Failure('Failed to update member role: $e');
    }
  }

  // Remove member from lab (Lecturer/Admin only)
  Future<Result<LabMember>> removeMember(String memberId) async {
    try {
      final now = DateTime.now();
      
      final response = await _supabase
          .from('tbl_lab_members')
          .update({
            'Status': 0,
            'LeftAt': now.toIso8601String(),
            'LastUpdatedAt': now.toIso8601String(),
          })
          .eq('Id', memberId)
          .select()
          .single();

      final member = LabMember.fromJson(response as Map<String, dynamic>);
      return Success(member);
    } catch (e) {
      return Failure('Failed to remove lab member: $e');
    }
  }

  // Delete member permanently (Admin only)
  Future<Result<void>> deleteMember(String memberId) async {
    try {
      await _supabase
          .from('tbl_lab_members')
          .delete()
          .eq('Id', memberId);

      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete lab member: $e');
    }
  }

  // Check if user is member of lab
  Future<Result<bool>> isUserMemberOfLab(String userId, String labId) async {
    try {
      final response = await _supabase
          .from('tbl_lab_members')
          .select('Id')
          .eq('UserId', userId)
          .eq('LabId', labId)
          .eq('Status', 1)
          .maybeSingle();

      return Success(response != null);
    } catch (e) {
      return Failure('Failed to check membership: $e');
    }
  }
}

// Provider for LabMemberRepository
final labMemberRepositoryProvider = Provider<LabMemberRepository>((ref) {
  return LabMemberRepository();
});

