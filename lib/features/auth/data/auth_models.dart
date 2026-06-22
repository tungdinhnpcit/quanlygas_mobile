// lib/features/auth/data/auth_models.dart

class RightInfo {
  final String rightCode;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;

  const RightInfo({
    required this.rightCode,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
    required this.canApprove,
  });

  factory RightInfo.fromJson(Map<String, dynamic> json) => RightInfo(
        rightCode:  json['rightCode'] as String,
        canAdd:     json['canAdd'] as bool,
        canEdit:    json['canEdit'] as bool,
        canDelete:  json['canDelete'] as bool,
        canApprove: json['canApprove'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'rightCode':  rightCode,
        'canAdd':     canAdd,
        'canEdit':    canEdit,
        'canDelete':  canDelete,
        'canApprove': canApprove,
      };
}

class MenuInfo {
  final String menuCode;
  final String menuName;
  final String? webUrl;
  final String? mobileRoute;
  final String? icon;
  final int sortOrder;
  final String? parentCode;
  final String platform;

  const MenuInfo({
    required this.menuCode,
    required this.menuName,
    this.webUrl,
    this.mobileRoute,
    this.icon,
    required this.sortOrder,
    this.parentCode,
    required this.platform,
  });

  factory MenuInfo.fromJson(Map<String, dynamic> json) => MenuInfo(
        menuCode:     json['menuCode'] as String,
        menuName:     json['menuName'] as String,
        webUrl:       json['webUrl'] as String?,
        mobileRoute:  json['mobileRoute'] as String?,
        icon:         json['icon'] as String?,
        sortOrder:    json['sortOrder'] as int,
        parentCode:   json['parentCode'] as String?,
        platform:     json['platform'] as String,
      );

  Map<String, dynamic> toJson() => {
        'menuCode':    menuCode,
        'menuName':    menuName,
        'webUrl':      webUrl,
        'mobileRoute': mobileRoute,
        'icon':        icon,
        'sortOrder':   sortOrder,
        'parentCode':  parentCode,
        'platform':    platform,
      };
}

class LoginResponse {
  final int userId;
  final String username;
  final String? fullName;
  final String? email;
  final String roleCode;
  final String roleName;
  final List<RightInfo> rights;
  final List<MenuInfo> menus;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int? nhanVienId;
  final String? avatarUrl;

  const LoginResponse({
    required this.userId,
    required this.username,
    this.fullName,
    this.email,
    required this.roleCode,
    required this.roleName,
    required this.rights,
    required this.menus,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.nhanVienId,
    this.avatarUrl,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        userId:       json['userId'] as int,
        username:     json['username'] as String,
        fullName:     json['fullName'] as String?,
        email:        json['email'] as String?,
        roleCode:     json['roleCode'] as String,
        roleName:     json['roleName'] as String,
        rights:       (json['rights'] as List).map((e) => RightInfo.fromJson(e)).toList(),
        menus:        (json['menus'] as List).map((e) => MenuInfo.fromJson(e)).toList(),
        accessToken:  json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn:    json['expiresIn'] as int,
        nhanVienId:   json['nhanVienId'] as int?,
        avatarUrl:    json['avatarUrl'] as String?,
      );
}
