// Plain Dart unit tests for the new permission getters added in Tier 3.
//
// Each test sets up a `PermissionProvider`, injects a permission list via
// `setPermissions(...)`, and asserts the corresponding boolean getter.
//
// We don't touch any production code — these are pure black-box assertions
// against the existing public API.

import 'package:flutter_test/flutter_test.dart';
import 'package:admin/providers/permission_provider.dart';

/// Build a fresh provider primed with a non-admin role and the given
/// permission codes. We pick a non-admin role on purpose so the
/// `isAdmin → true` short-circuit doesn't mask the per-permission check.
PermissionProvider _withPerms(List<String> perms) {
  final p = PermissionProvider();
  p.setPermissions(perms, 'PROJECT_MANAGER');
  return p;
}

void main() {
  group('PermissionProvider — Tier 3 getters', () {
    // ---- BoQ correction ----
    test('canCorrectBoq is true when BOQ_CORRECT permission present', () {
      expect(_withPerms(['BOQ_CORRECT']).canCorrectBoq, isTrue);
    });

    test('canCorrectBoq is false without BOQ_CORRECT permission', () {
      expect(_withPerms(['BOQ_VIEW']).canCorrectBoq, isFalse);
      expect(_withPerms(const []).canCorrectBoq, isFalse);
    });

    // ---- DPC view ----
    test('canViewDpc is true when DPC_VIEW permission present', () {
      expect(_withPerms(['DPC_VIEW']).canViewDpc, isTrue);
    });

    test('canViewDpc is false without DPC_VIEW permission', () {
      expect(_withPerms(['DPC_EDIT']).canViewDpc, isFalse);
      expect(_withPerms(const []).canViewDpc, isFalse);
    });

    // ---- DPC create ----
    test('canCreateDpc is true when DPC_CREATE permission present', () {
      expect(_withPerms(['DPC_CREATE']).canCreateDpc, isTrue);
    });

    test('canCreateDpc is false without DPC_CREATE permission', () {
      expect(_withPerms(['DPC_VIEW']).canCreateDpc, isFalse);
    });

    // ---- DPC edit ----
    test('canEditDpc is true when DPC_EDIT permission present', () {
      expect(_withPerms(['DPC_EDIT']).canEditDpc, isTrue);
    });

    test('canEditDpc is false without DPC_EDIT permission', () {
      expect(_withPerms(['DPC_VIEW']).canEditDpc, isFalse);
    });

    // ---- DPC issue ----
    test('canIssueDpc is true when DPC_ISSUE permission present', () {
      expect(_withPerms(['DPC_ISSUE']).canIssueDpc, isTrue);
    });

    test('canIssueDpc is false without DPC_ISSUE permission', () {
      expect(_withPerms(['DPC_EDIT']).canIssueDpc, isFalse);
    });

    // ---- DPC template manage ----
    test('canManageDpcTemplates is true when DPC_TEMPLATE_MANAGE present', () {
      expect(
          _withPerms(['DPC_TEMPLATE_MANAGE']).canManageDpcTemplates, isTrue);
    });

    test('canManageDpcTemplates is false without DPC_TEMPLATE_MANAGE', () {
      expect(_withPerms(['DPC_EDIT']).canManageDpcTemplates, isFalse);
    });

    // ---- BoQ submit-doc / customer-approve (both gated on BOQ_APPROVE) ----
    test('canSubmitBoqDoc is true when BOQ_APPROVE permission present', () {
      expect(_withPerms(['BOQ_APPROVE']).canSubmitBoqDoc, isTrue);
    });

    test('canSubmitBoqDoc is false without BOQ_APPROVE permission', () {
      expect(_withPerms(['BOQ_VIEW']).canSubmitBoqDoc, isFalse);
    });

    test('canCustomerApproveBoq is true when BOQ_APPROVE permission present',
        () {
      expect(_withPerms(['BOQ_APPROVE']).canCustomerApproveBoq, isTrue);
    });

    test('canCustomerApproveBoq is false without BOQ_APPROVE permission', () {
      expect(_withPerms(['BOQ_VIEW']).canCustomerApproveBoq, isFalse);
    });

    // ---- ADMIN role bypass — sanity check the existing behaviour still
    //      grants Tier-3 getters even when no explicit code is listed. ----
    test('ADMIN role grants every Tier-3 getter regardless of perms list', () {
      final p = PermissionProvider();
      p.setPermissions(const [], 'ADMIN');

      expect(p.canCorrectBoq, isTrue);
      expect(p.canViewDpc, isTrue);
      expect(p.canCreateDpc, isTrue);
      expect(p.canEditDpc, isTrue);
      expect(p.canIssueDpc, isTrue);
      expect(p.canManageDpcTemplates, isTrue);
      expect(p.canSubmitBoqDoc, isTrue);
      expect(p.canCustomerApproveBoq, isTrue);
    });

    test('clearPermissions revokes every Tier-3 getter', () {
      final p = PermissionProvider();
      p.setPermissions(
        const [
          'BOQ_CORRECT',
          'DPC_VIEW',
          'DPC_CREATE',
          'DPC_EDIT',
          'DPC_ISSUE',
          'DPC_TEMPLATE_MANAGE',
          'BOQ_APPROVE',
        ],
        'PROJECT_MANAGER',
      );
      // Sanity-check primed state
      expect(p.canViewDpc, isTrue);

      p.clearPermissions();

      expect(p.canCorrectBoq, isFalse);
      expect(p.canViewDpc, isFalse);
      expect(p.canCreateDpc, isFalse);
      expect(p.canEditDpc, isFalse);
      expect(p.canIssueDpc, isFalse);
      expect(p.canManageDpcTemplates, isFalse);
      expect(p.canSubmitBoqDoc, isFalse);
      expect(p.canCustomerApproveBoq, isFalse);
    });
  });
}
