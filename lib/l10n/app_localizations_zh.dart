// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get auto => '自动';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get retry => '重试';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get navHome => '家';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAccounts => '小米账号';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionLanguage => '语言';

  @override
  String get sectionRegions => '要查询的地区';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get regionsHint => '更改将在下次刷新列表时生效。';

  @override
  String get addAccount => '添加账号';

  @override
  String get removeAccount => '移除账号';

  @override
  String get removeAccountTitle => '移除账号？';

  @override
  String removeAccountBody(Object account) {
    return '$account\n\n该账号的设备将从列表中消失。设备本身和小米账号不会改变。';
  }

  @override
  String get remove => '移除';

  @override
  String get logoutDemo => '退出演示';

  @override
  String get logoutAll => '退出所有账号';

  @override
  String get logoutAccount => '退出账号';

  @override
  String get demoAccount => '演示';

  @override
  String get uiScale => '界面缩放';

  @override
  String get zoomOut => '缩小 (Ctrl + −)';

  @override
  String get zoomIn => '放大 (Ctrl + +)';

  @override
  String regionName(String region) {
    String _temp0 = intl.Intl.selectLogic(region, {
      'cn': '中国大陆',
      'ru': '俄罗斯',
      'de': '欧洲',
      'us': '美国',
      'sg': '新加坡',
      'i2': '印度',
      'tw': '台湾',
      'other': '$region',
    });
    return '$_temp0';
  }

  @override
  String get greetingNight => '晚安';

  @override
  String get greetingMorning => '早上好';

  @override
  String get greetingDay => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String devicesSummary(Object online, Object total, Object regions) {
    return '在线 $online/$total · 地区：$regions';
  }

  @override
  String get refreshList => '刷新列表';

  @override
  String regionUnavailable(Object error) {
    return '不可用：$error';
  }

  @override
  String get filterAll => '全部';

  @override
  String get noDevices => '未找到设备';

  @override
  String get statusOffline => '离线';

  @override
  String get statusOn => '已开启';

  @override
  String get statusOff => '已关闭';

  @override
  String get statusOnline => '在线';

  @override
  String get infoModel => '型号';

  @override
  String get infoRegion => '地区';

  @override
  String get infoAccount => '账号';

  @override
  String get exploreDevice => '探测设备';

  @override
  String get direction => '方向';

  @override
  String get turnOnToRotate => '请先打开风扇，才能调整方向。';

  @override
  String get noSpec => '该型号没有公开的规格说明，暂时无法控制。';

  @override
  String get loadingSpec => '正在加载设备描述…';

  @override
  String get slower => '减速';

  @override
  String get faster => '加速';

  @override
  String get speed => '风速';

  @override
  String get unitSeconds => '秒';

  @override
  String get unitMinutes => '分钟';

  @override
  String get unitHours => '小时';

  @override
  String get unitWatt => '瓦';

  @override
  String get unitLux => '勒克斯';

  @override
  String get calibrate => '校准';

  @override
  String get swingRecalibrate => '方向不对——重新计算';

  @override
  String get swingHoldTooltip => '风扇停在这一侧时按住';

  @override
  String swingRelease(Object seconds) {
    return '风扇一离开边缘就松开… $seconds 秒';
  }

  @override
  String get swingNotCounted => '未计入：风扇一停在另一侧就要按住那一侧的按钮，并在它停留期间一直按住。';

  @override
  String get swingOtherEdge => '现在，风扇一停在另一侧就按住那一侧的按钮，风扇开始移动时松开。';

  @override
  String get swingCalibrationIntro =>
      '校准。风扇停在某一侧时，按住该侧的按钮，风扇一开始移动就松开。然后在另一侧重复一次。';

  @override
  String get swingLost => '位置已丢失：摆头是在应用之外开启的。请点击“校准”并标记一侧。';

  @override
  String get swingTurning => '正在转动…';

  @override
  String swingReady(Object sweep, Object dwell) {
    return '点击弧线即可转动风扇。单程 $sweep 秒，边缘停顿 $dwell 秒。';
  }

  @override
  String get swingStatusHolding => '停在边缘';

  @override
  String get swingStatusWaitingEdge => '等待边缘';

  @override
  String get swingStatusNoData => '无数据';

  @override
  String get swingStatusTurning => '转动中';

  @override
  String get swingStatusSwinging => '摆头中';

  @override
  String get swingStatusStill => '静止';

  @override
  String probeTitle(Object device) {
    return '探测：$device';
  }

  @override
  String probeIntro(Object maxSiid, Object maxPiid) {
    return '应用会向设备查询属性 siid 1–$maxSiid × piid 1–$maxPiid，包括规格中没有的属性。只读：设备不会有任何改变。';
  }

  @override
  String get probeWatch => '监视变化';

  @override
  String get probeWatchHint => '每 2 秒一次。在设备上或米家中按下按钮，看看哪些值发生了变化。';

  @override
  String probeScanning(Object siid, Object maxSiid) {
    return '正在查询 siid $siid/$maxSiid…';
  }

  @override
  String get probeScan => '扫描';

  @override
  String get probeRescan => '重新扫描';

  @override
  String probeFound(Object count, Object hidden) {
    return '找到属性：$count 个，其中规格中没有的：$hidden 个。';
  }

  @override
  String probeFailedSiids(Object siids) {
    return '查询 siid 出错：$siids';
  }

  @override
  String get probeChanges => '变化';

  @override
  String get probeNotInSpec => '规格中没有';

  @override
  String probeReadFailed(Object error) {
    return '读取失败：$error';
  }

  @override
  String get probeCopy => '复制报告';

  @override
  String get probeCopied => '报告已复制';

  @override
  String probeReportTitle(Object device, Object model, Object region) {
    return '$device · $model · 地区 $region';
  }

  @override
  String get loginTitle => '全屋设备，一个列表';

  @override
  String get loginSubtitle => '来自所有地区的小米设备。不会保存密码。';

  @override
  String get loginUser => '邮箱、手机号或小米 ID';

  @override
  String get loginPassword => '密码';

  @override
  String get loginCaptcha => '图片中的文字';

  @override
  String get loginCodeEmail => '邮件中的验证码';

  @override
  String get loginCodeSms => '短信验证码';

  @override
  String get loginSubmit => '登录';

  @override
  String get loginContinue => '继续';

  @override
  String get loginBusy => '正在登录…';

  @override
  String get loginWithQr => '扫码登录';

  @override
  String get loginDemo => '无需账号，查看演示';

  @override
  String get backToSettings => '返回设置';

  @override
  String get qrInstructions => '请在米家应用或小米手机上（设置 → 小米账号）扫描二维码并确认登录。';

  @override
  String get qrNewCode => '获取新二维码';

  @override
  String get qrUsePassword => '使用账号密码登录';

  @override
  String get qrLoading => '正在获取二维码…';

  @override
  String get qrWaiting => '等待在手机上确认…';

  @override
  String get qrLinkHint => '无法扫码？请在手机上打开此链接：';

  @override
  String errorConnection(Object error) {
    return '无法连接服务器：$error';
  }

  @override
  String get errorSessionExpired => '会话已过期，请重新登录';

  @override
  String errorCloud(Object details) {
    return '小米云错误：$details';
  }

  @override
  String errorCommandRejected(Object code) {
    return '设备拒绝了该命令（$code）';
  }

  @override
  String get errorNoQr => '小米服务器未返回二维码';

  @override
  String get errorQrFailed => '扫码登录失败，请获取新二维码';

  @override
  String get errorQrExpired => '二维码已过期，请获取新二维码';

  @override
  String get errorCodeNotRequested => '未请求验证码';

  @override
  String get errorWrongCode => '验证码错误';

  @override
  String get errorNoSession => '小米服务器未返回会话数据';

  @override
  String get errorNoServiceToken => '小米服务器未返回 serviceToken';

  @override
  String get errorWrongCredentials => '账号或密码错误';

  @override
  String errorLoginRejected(Object code, Object details) {
    return '登录错误 $code：$details';
  }

  @override
  String get errorUnexpectedResponse => '小米服务器返回了意外的响应';

  @override
  String demoDeviceName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'fan': '风扇',
      'lamp': '床头灯',
      'humidifier': '加湿器',
      'purifier': '空气净化器',
      'plug': '书桌插座',
      'heater': '取暖器',
      'vacuum': '扫地机器人',
      'other': '$id',
    });
    return '$_temp0';
  }
}
