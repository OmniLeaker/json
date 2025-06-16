#include <windows.h> // Core Windows API functions
#include <tchar.h>   // For _TCHAR, _tcscpy_s, _stprintf_s (wide character support)
#include <strsafe.h> // For StringCchPrintf (safer string handling)
#include <commdlg.h> // For OPENFILENAME structure and GetOpenFileName function
#include <shlwapi.h> // For PathCombine (useful for combining paths safely) - requires linking with shlwapi.lib

/*
 * python_gui_launcher.c
 *
 * This C program serves as a simple Windows GUI launcher specifically designed
 * to execute Python scripts using a portable Python interpreter.
 *
 * It provides a basic window with a button that, when clicked, opens a
 * standard Windows file dialog. The user can then select a Python script (.py)
 * or any other executable (.exe, .bat, etc.) to launch.
 *
 * This design aims to significantly reduce false positives from Machine Learning (ML)
 * based antivirus engines (like "Trojan:Win32/Wacatac.B!ml") by:
 *
 * 1.  Requiring Explicit User Interaction: The core "launch" action is initiated
 * by the user clicking a button and selecting a file, not automatically.
 * This breaks the pattern of silent, automated malware execution.
 * 2.  Using Standard Windows UI Elements: The file dialog (GetOpenFileName) is a
 * well-known and trusted Windows API, which is a strong signal of legitimate behavior.
 * 3.  Clear Intent: The GUI clearly indicates its purpose (launching files),
 * making its behavior transparent to both users and security software analysis.
 * 4.  Relative Paths: The launcher intelligently finds its own directory to locate
 * the portable Python installation, making the distribution self-contained.
 *
 * While this approach significantly improves the behavioral profile, remember that:
 *
 * ->  DIGITAL CODE SIGNING IS STILL THE MOST CRITICAL FACTOR for executables.
 * A valid digital signature from a trusted Certificate Authority provides
 * verifiable proof of origin and integrity, drastically improving reputation.
 * ->  The launched script/application itself is still subject to antivirus scrutiny.
 * If the selected file is malicious, it will be detected upon its execution.
 * ->  You should still submit your digitally signed launcher to antivirus vendors
 * (especially Microsoft) as a false positive to help train their models.
 *
 * Portable Python Structure Assumption:
 * The launcher expects 'PortablePython\python.exe' to be located
 * relative to the launcher's own executable.
 *
 * COMPILATION INSTRUCTIONS (using Microsoft Visual C++ - MSVC):
 * Open a "Developer Command Prompt for VS" and navigate to this file's directory.
 * Compile with:
 * cl /EHsc python_gui_launcher.c /link /SUBSYSTEM:WINDOWS user32.lib comdlg32.lib shlwapi.lib
 *
 * This will create 'python_gui_launcher.exe'.
 */

// Window Class Name
#define IDC_LAUNCH_BUTTON 101 // ID for our launch button

// Global handle for the main window
HWND g_hMainWnd = NULL;

// Function to launch a selected file
void LaunchSelectedFile(HWND hWndParent) {
    OPENFILENAME ofn;       // Common dialog box structure
    TCHAR szFile[MAX_PATH] = {0}; // Buffer for selected file name

    // Initialize OPENFILENAME structure
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = hWndParent; // Parent window handle
    ofn.lpstrFile = szFile;     // Buffer for the file name
    ofn.nMaxFile = sizeof(szFile) / sizeof(TCHAR); // Size of the buffer
    ofn.lpstrFilter = _T("Python Scripts (*.py)\0*.py\0")
                      _T("Executable Files (*.exe;*.bat;*.cmd)\0*.exe;*.bat;*.cmd\0")
                      _T("All Files (*.*)\0*.*\0"); // Filter for file types
    ofn.nFilterIndex = 1;       // Default filter (Python Scripts)
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_NOCHANGEDIR; // Flags for the dialog

    // Display the Open dialog box.
    if (GetOpenFileName(&ofn) == TRUE) {
        // User selected a file. Now try to launch it.
        STARTUPINFO si;
        PROCESS_INFORMATION pi;

        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        ZeroMemory(&pi, sizeof(pi));

        TCHAR szCommandLine[MAX_PATH * 2]; // Buffer for the command line to execute
        LPCTSTR applicationToExecute = NULL; // Pointer to the executable (e.g., python.exe or selected .exe)

        // Get the full path to the launcher's own executable
        TCHAR szLauncherPath[MAX_PATH];
        GetModuleFileName(NULL, szLauncherPath, MAX_PATH);
        // Extract the directory of the launcher
        PathRemoveFileSpec(szLauncherPath); // szLauncherPath now contains the directory (e.g., C:\YourProjectFolder)

        // Construct the full path to the portable Python interpreter
        TCHAR szPythonExePath[MAX_PATH];
        StringCchPrintf(szPythonExePath, _countof(szPythonExePath), _T("%s\\PortablePython\\python.exe"), szLauncherPath);

        // Determine if the selected file is a Python script and needs an interpreter
        LPTSTR pszExtension = _tcsrchr(ofn.lpstrFile, _T('.'));
        BOOL bIsPythonScript = FALSE;
        if (pszExtension != NULL && _tcsicmp(pszExtension, _T(".py")) == 0) {
            bIsPythonScript = TRUE;
        }

        if (bIsPythonScript) {
            // For Python scripts, launch python.exe with the script as an argument
            // Ensure python.exe exists
            if (!PathFileExists(szPythonExePath)) {
                TCHAR errorMsg[MAX_PATH + 100];
                StringCchPrintf(errorMsg, _countof(errorMsg), _T("Portable Python interpreter not found:\n%s\n\nEnsure 'PortablePython\\python.exe' exists next to the launcher."), szPythonExePath);
                MessageBox(hWndParent, errorMsg, _T("Launch Error"), MB_ICONERROR | MB_OK);
                return;
            }
            // Command line: "C:\path\to\launcher\PortablePython\python.exe" "C:\path\to\selected\script.py"
            StringCchPrintf(szCommandLine, _countof(szCommandLine), _T("\"%s\" \"%s\""), szPythonExePath, ofn.lpstrFile);
            applicationToExecute = NULL; // Let lpCommandLine specify the executable and its args
        } else {
            // It's an executable (.exe, .bat, .cmd) or unrecognized script type, launch directly.
            // CreateProcess needs a mutable buffer for lpCommandLine, even if just the path.
            StringCchCopy(szCommandLine, _countof(szCommandLine), ofn.lpstrFile);
            applicationToExecute = NULL; // Let lpCommandLine specify the executable (path and name)
        }

        // Attempt to create the process.
        // We set bInheritHandles to FALSE as we're not redirecting I/O via pipes.
        // CREATE_NEW_CONSOLE for a new independent console window if a console app is launched.
        if (!CreateProcess(
                applicationToExecute, // Application name (NULL means commandLine contains full path)
                szCommandLine,        // Command line (mutable, contains executable path and args)
                NULL,                 // Process handle not inheritable
                NULL,                 // Thread handle not inheritable
                FALSE,                // Set handle inheritance to FALSE
                CREATE_NEW_CONSOLE,   // Create a new console window if the target is a console app
                NULL,                 // Use parent's environment block
                NULL,                 // Use parent's starting directory
                &si,                  // Pointer to STARTUPINFO structure
                &pi                   // Pointer to PROCESS_INFORMATION structure
            )) {
            // Launch failed. Display error.
            TCHAR errorMessage[512];
            StringCchPrintf(errorMessage, _countof(errorMessage),
                            _T("Failed to launch '%s'. Error Code: %lu\n\n")
                            _T("Possible reasons:\n")
                            _T("- File not found or path is incorrect.\n")
                            _T("- Insufficient permissions to execute.\n")
                            _T("- Antivirus blocking the selected file/interpreter.\n"),
                            ofn.lpstrFile, GetLastError());
            MessageBox(hWndParent, errorMessage, _T("Launcher Error"), MB_ICONERROR | MB_OK);
            return;
        }

        // Launch successful. Display confirmation.
        TCHAR successMessage[512];
        StringCchPrintf(successMessage, _countof(successMessage),
                        _T("Successfully launched:\n'%s'\n\n")
                        _T("Please check if the application started as expected."),
                        ofn.lpstrFile);
        MessageBox(hWndParent, successMessage, _T("Launcher Success"), MB_ICONINFORMATION | MB_OK);

        // Close process and thread handles.
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    } else {
        // User cancelled the dialog, or an error occurred with the dialog.
        // CommDlgExtendedError() can give more info on dialog errors if needed.
        // MessageBox(hWndParent, _T("File selection cancelled or failed."), _T("Launcher Info"), MB_ICONINFORMATION | MB_OK);
    }
}

// Window Procedure for handling messages
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
        case WM_CREATE: {
            // Create the "Launch Script/Executable" button
            CreateWindow(
                _T("BUTTON"),                  // Predefined class name for a button
                _T("Select & Launch Script/Executable"), // Button text
                WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON, // Styles
                80, 80, // x, y position
                240, 60,  // width, height
                hWnd,    // Parent window
                (HMENU)IDC_LAUNCH_BUTTON, // Button ID
                (HINSTANCE)GetWindowLongPtr(hWnd, GWLP_HINSTANCE), // Instance handle
                NULL);   // No creation data
            break;
        }
        case WM_COMMAND: {
            // Handle button clicks
            if (LOWORD(wParam) == IDC_LAUNCH_BUTTON) {
                LaunchSelectedFile(hWnd); // Call our file launching function
            }
            break;
        }
        case WM_CLOSE:
            DestroyWindow(hWnd);
            break;
        case WM_DESTROY:
            PostQuitMessage(0); // Terminate the application when window is closed
            break;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam); // Default message processing
    }
    return 0;
}

// WinMain: The entry point for all Windows GUI applications
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    WNDCLASSEX wc;    // Window class structure
    HWND hWnd;        // Window handle
    MSG Msg;          // Message structure

    // Step 1: Registering the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;      // Pointer to the Window Procedure
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;    // Handle to the instance
    wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION); // Default application icon
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);      // Default arrow cursor
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1); // Default window background
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = _T("PythonGuiLauncherClass"); // Class name
    wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION); // Small icon for taskbar

    if (!RegisterClassEx(&wc)) {
        MessageBox(NULL, _T("Window Registration Failed!"), _T("Error!"), MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    // Step 2: Creating the Window
    hWnd = CreateWindowEx(
        WS_EX_CLIENTEDGE,           // Extended window style
        _T("PythonGuiLauncherClass"), // Class name
        _T("Python Script Launcher"), // Window title
        WS_OVERLAPPEDWINDOW,        // Window style
        CW_USEDEFAULT, CW_USEDEFAULT, // x, y position
        400, 250,                   // width, height
        NULL,                       // Parent window handle
        NULL,                       // Menu handle
        hInstance,                  // Instance handle
        NULL);                      // Creation parameters

    if (hWnd == NULL) {
        MessageBox(NULL, _T("Window Creation Failed!"), _T("Error!"), MB_ICONEXCLAMATION | MB_OK);
        return 0;
    }

    g_hMainWnd = hWnd; // Store main window handle

    // Step 3: Displaying the Window
    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);

    // Step 4: The Message Loop
    while (GetMessage(&Msg, NULL, 0, 0) > 0) {
        TranslateMessage(&Msg);
        DispatchMessage(&Msg);
    }

    return (int)Msg.wParam;
}
