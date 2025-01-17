#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Get the work area dimensions (excluding the taskbar)
  RECT workAreaRect;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &workAreaRect, 0);
  int screenWidth = workAreaRect.right - workAreaRect.left;
  int screenHeight = workAreaRect.bottom - workAreaRect.top;

  FlutterWindow window(project);
  Win32Window::Point origin(workAreaRect.left, workAreaRect.top); // Top-left corner of the work area
  Win32Window::Size size(screenWidth, screenHeight);              // Full work area size

  if (!window.Create(L"fond_check", origin, size)) {
    return EXIT_FAILURE;
  }

  // Configure the window style
  HWND hwnd = window.GetHandle();
  LONG style = GetWindowLong(hwnd, GWL_STYLE);
  style &= ~WS_SIZEBOX;         // Disable resizing
  style |= WS_OVERLAPPEDWINDOW; // Keep minimize, maximize, and close buttons
  SetWindowLong(hwnd, GWL_STYLE, style);

  // Center the window
  SetWindowPos(hwnd, HWND_TOP, workAreaRect.left, workAreaRect.top, screenWidth, screenHeight, SWP_FRAMECHANGED);

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
