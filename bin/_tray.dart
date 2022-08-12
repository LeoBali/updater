import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '_app.dart' as app;
import '_menu.dart' as menu;

final _nid = calloc<NOTIFYICONDATA>()..ref.cbSize = sizeOf<NOTIFYICONDATA>();

bool _trayWndProc(int hWnd, int msg, int wParam, int lParam) {
  final hWnd = _nid.ref.hWnd;
  switch (msg) {
    case app.EVENT_TRAY_NOTIFY:
      switch (LOWORD(lParam)) {
        case NIN_SELECT:
          ShowWindow(hWnd, IsWindowVisible(hWnd) == 1 ? SW_HIDE : SW_SHOW);
          SetForegroundWindow(hWnd);
          return true;

        case WM_CONTEXTMENU:
          menu.show(hWndParent: hWnd);
          return true;
      }
  }
  return false;
}

late NOTIFYICONDATA nid;

void addIcon({required int hWndParent}) {
  nid = _nid.ref
    ..hWnd = hWndParent
    ..uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP | NIF_GUID
    ..szTip = "Updater"
    ..uCallbackMessage = app.EVENT_TRAY_NOTIFY
    ..hIcon = app.loadDartIcon();
  Shell_NotifyIcon(NIM_ADD, _nid);
  nid.uVersion = 4;
  Shell_NotifyIcon(NIM_SETVERSION, _nid);
  app.registerWndProc(_trayWndProc);
}

void showBalloon(String title, String info, int timeout) {
  nid.uFlags |= NIF_INFO;
  nid.uTimeout = timeout;
  nid.szInfoTitle = title;
  nid.szInfo = info;
  Shell_NotifyIcon(NIM_MODIFY, _nid);
  /*
      m_NID.uFlags |= NIF_INFO;
    m_NID.uTimeout = unTimeout;
    m_NID.dwInfoFlags = dwInfoFlags;

    if (StringCchCopy(m_NID.szInfoTitle, sizeof(m_NID.szInfoTitle), pszTitle) != S_OK)
        return FALSE;

    if (StringCchCopy(m_NID.szInfo, sizeof(m_NID.szInfo), pszText) != S_OK)
        return FALSE;

    return Shell_NotifyIcon(NIM_MODIFY, &m_NID);
   */
}

void removeIcon() {
  Shell_NotifyIcon(NIM_DELETE, _nid);
  free(_nid);
  app.deregisterWndProc(_trayWndProc);
}
