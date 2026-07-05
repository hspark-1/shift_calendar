/// API 응답의 템플릿 정보 모델
class ShiftTemplateApiModel {
  final String templateId;
  final String templateName;
  final String ownerUserId;
  final DateTime createdAt;
  final ShiftTemplateVersionApiModel? currentVersion;

  ShiftTemplateApiModel({
    required this.templateId,
    required this.templateName,
    required this.ownerUserId,
    required this.createdAt,
    this.currentVersion,
  });

  factory ShiftTemplateApiModel.fromJson(Map<String, dynamic> json) {
    return ShiftTemplateApiModel(
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      ownerUserId: json['owner_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentVersion: json['current_version'] != null
          ? ShiftTemplateVersionApiModel.fromJson(
              json['current_version'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// 템플릿 버전 정보 모델
class ShiftTemplateVersionApiModel {
  final String templateVersionId;
  final int versionNo;
  final DateTime effectiveFrom;
  final DateTime createdAt;

  ShiftTemplateVersionApiModel({
    required this.templateVersionId,
    required this.versionNo,
    required this.effectiveFrom,
    required this.createdAt,
  });

  factory ShiftTemplateVersionApiModel.fromJson(Map<String, dynamic> json) {
    return ShiftTemplateVersionApiModel(
      templateVersionId: json['template_version_id'] as String,
      versionNo: json['version_no'] as int,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 템플릿 조회 응답
class ShiftTemplateResponse {
  final bool success;
  final ShiftTemplateApiModel data;

  ShiftTemplateResponse({
    required this.success,
    required this.data,
  });

  factory ShiftTemplateResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('success') && json.containsKey('data')) {
      return ShiftTemplateResponse(
        success: json['success'] as bool? ?? true,
        data: ShiftTemplateApiModel.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
      );
    } else {
      return ShiftTemplateResponse(
        success: true,
        data: ShiftTemplateApiModel.fromJson(json),
      );
    }
  }
}

/// 템플릿 이름 변경 요청
class UpdateTemplateNameRequest {
  final String name;

  UpdateTemplateNameRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}

/// 템플릿 이름 변경 응답
class UpdateTemplateNameResponse {
  final bool success;
  final UpdateTemplateNameData data;

  UpdateTemplateNameResponse({
    required this.success,
    required this.data,
  });

  factory UpdateTemplateNameResponse.fromJson(Map<String, dynamic> json) {
    return UpdateTemplateNameResponse(
      success: json['success'] as bool? ?? true,
      data: UpdateTemplateNameData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}

class UpdateTemplateNameData {
  final String templateId;
  final String templateName;
  final DateTime updatedAt;

  UpdateTemplateNameData({
    required this.templateId,
    required this.templateName,
    required this.updatedAt,
  });

  factory UpdateTemplateNameData.fromJson(Map<String, dynamic> json) {
    return UpdateTemplateNameData(
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

