import 'dart:convert';

import 'package:win32_registry/win32_registry.dart';

import '_app.dart' as app;
import '_menu.dart' as menu;
import '_tray.dart' as tray;
import '_window.dart' as window;
import 'app_info.dart';

void main() {
  print("Starting Updater");
  final hWnd = window.createHidden();
  tray.addIcon(hWndParent: hWnd);
  app.registerWndProc(menu.wndProc);
  try {
    updater();
  } catch (e) {
    print("exception $e");
  }
  tray.showBalloon("Updater", "You have 2 new updates and 1 beta update", 5000);
  app.exec();
}

const String registryPath = "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall";
const String registryPath6432 = "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall";

List<AppInfo> apps = [];
String? buildNumber, productName;
int? majorVersion, minorVersion;
bool? win64;

void updater() {
  checkRegistryKey(hive: RegistryHive.localMachine);
  checkRegistryKey(hive: RegistryHive.currentUser);
  try {
    //var key6432 = Registry.openPath(RegistryHive.localMachine, path: registryPath6432);
    checkRegistryKey(hive: RegistryHive.localMachine, wow6432: true);
    try {
      //key6432 = Registry.openPath(RegistryHive.currentUser, path: registryPath6432);
      checkRegistryKey(hive: RegistryHive.currentUser, wow6432: true);
    } catch (_) {}
    win64 = true;
  } catch (e) {
    print(e);
    win64 = false;
  }
  checkBuild();
  makeOutput();
  //print("win64 $win64");
}

void checkBuild() {
  final key = Registry.openPath(RegistryHive.localMachine, path: "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion");
  buildNumber = key.getValueAsString("CurrentBuild");
  majorVersion = key.getValueAsInt("CurrentMajorVersionNumber");
  minorVersion = key.getValueAsInt("CurrentMinorVersionNumber");
  productName = key.getValueAsString("ProductName");
  //print("$buildNumber $majorVersion $minorVersion $productName");
}

void checkRegistryKey({required RegistryHive hive, bool wow6432 = false}) {
  RegistryKey registryKey = Registry.openPath(hive, path: wow6432 ? registryPath6432 : registryPath);
  for (final name in registryKey.subkeyNames) {
    final key = Registry.openPath(hive, path: wow6432 ? "$registryPath6432\\$name" : "$registryPath\\$name");
    final softwareName = key.getValueAsString("DisplayName");
    if (softwareName == null || softwareName.isEmpty) continue;
    final softwareVersion = key.getValueAsString("DisplayVersion");
    if (softwareName.contains(" (KB")) continue;
    final systemComponent = key.getValue("SystemComponent");
    if (systemComponent != null) {
      if (systemComponent.type == RegistryValueType.string) {
        if (systemComponent.data as String != "") continue;
      } else if (systemComponent.type == RegistryValueType.int32 || systemComponent.type == RegistryValueType.int64) {
        if (systemComponent.data as int != 0) continue;
      }
    }
    apps.add(AppInfo(softwareName, softwareVersion ?? ""));
  }
}

void makeOutput() {
  final buffer = StringBuffer();
  //buffer.write(
  //    "${buildNumber ?? ''};${majorVersion ?? 0};${minorVersion ?? 0};${productName ?? ''};${win64 ?? false}\r\n");
  for (final app in apps) {
    buffer.write("${app.name};;${app.version}\r\n");
  }
  final str = buffer.toString();
  //print(str);
  //print("");
  final bytes = utf8.encode(str);
  final base64Str = base64.encode(bytes);
  final encoded = Uri.encodeComponent(base64Str);
  print(encoded);
}
