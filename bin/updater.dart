import 'package:win32_registry/win32_registry.dart';

import '_app.dart' as app;
import '_menu.dart' as menu;
import '_tray.dart' as tray;
import '_window.dart' as window;

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

void updater() {
  checkRegistryKey(Registry.openPath(RegistryHive.localMachine, path: registryPath));
  bool win64;
  try {
    final key6432 = Registry.openPath(RegistryHive.localMachine, path: registryPath6432);
    checkRegistryKey(key6432, wow6432: true);
    win64 = true;
  } catch (e) {
    print(e);
    win64 = false;
  }
  checkBuild();
  print("win64 $win64");
}

void checkBuild() {
  final key = Registry.openPath(RegistryHive.localMachine, path: "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion");
  final buildNumber = key.getValueAsString("CurrentBuild");
  final majorVersion = key.getValueAsInt("CurrentMajorVersionNumber");
  final minorVersion = key.getValueAsInt("CurrentMinorVersionNumber");
  final productName = key.getValueAsString("ProductName");
  print("$buildNumber $majorVersion $minorVersion $productName");
}

void checkRegistryKey(RegistryKey registryKey, {bool wow6432 = false}) {
  for (final name in registryKey.subkeyNames) {
    final key = Registry.openPath(RegistryHive.localMachine,
        path: wow6432 ? "$registryPath6432\\$name" : "$registryPath\\$name");
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
    print("$softwareName version: $softwareVersion");
  }
}
