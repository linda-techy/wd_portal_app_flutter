import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_template_picker_dialog.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/providers/permission_provider.dart';

/// Drives the post-project-creation B9 template-picker flow:
///
/// 1. If the user lacks `PROJECT_WBS_CLONE`, returns silently (no dialog).
/// 2. If the project's type doesn't map to any [WbsProjectType], returns silently.
/// 3. Shows [WbsTemplatePickerDialog]; on **Skip**, returns silently.
/// 4. On **Materialize**, calls
///    `POST /api/projects/{id}/wbs/clone-from-template` and surfaces a toast
///    with the cloner summary, or a clear message on 409 / generic on other
///    errors.
///
/// Caller is responsible for any post-creation navigation; this helper does
/// not change routes.
Future<void> runWbsTemplatePickerFlow({
  required BuildContext context,
  required CustomerProject project,
  required PermissionProvider perms,
  WbsTemplateService? serviceOverride,
}) async {
  if (!perms.canCloneProjectWbs) return;
  if (project.id == null) return;

  final wbsType = mapCustomerProjectTypeToWbs(project.projectType);
  if (wbsType == null) return;

  final result = await WbsTemplatePickerDialog.show(
    context,
    projectType: wbsType,
    defaultFloors: project.floors,
    serviceOverride: serviceOverride,
  );
  if (result == null) return; // user skipped
  if (!context.mounted) return;

  final service = serviceOverride ?? WbsTemplateService();
  try {
    final summary = await service.cloneIntoProject(
      projectId: project.id!,
      templateId: result.templateId,
      floorCount: result.floorCount,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WBS materialized: '
          '${summary.milestonesCreated} phases, '
          '${summary.tasksCreated} tasks created.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  } on DioException catch (e) {
    if (!context.mounted) return;
    final status = e.response?.statusCode;
    final msg = status == 409
        ? 'Project already has a WBS — nothing was changed.'
        : 'Failed to materialize WBS: ${e.message ?? 'Network error.'}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to materialize WBS: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
