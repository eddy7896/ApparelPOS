; Inno Setup script for the Apparel PoS counter app (ADR-0018).
; Built on the Windows CI runner and by hand: ISCC /DAppVersion=0.9.0 installer\apparel_pos.iss
; Per-user install (no administrator password), unsigned for now, and removing the
; program never touches the shop's data (it lives in the user's AppData folder,
; outside the install folder).
;
; The AppId below must NEVER change: Windows uses it to recognise an earlier install,
; so a newer Setup upgrades in place and keeps the data.
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define AppName "Apparel PoS"
#define AppExe "pos_windows.exe"
#define ReleaseDir "..\apps\pos_windows\build\windows\x64\runner\Release"

[Setup]
AppId={{6CBDBAEB-C0CC-41A8-A29E-12FAF018F721}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Apparel PoS
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\build\installer
OutputBaseFilename=ApparelPoS-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#AppExe}
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "Put a shortcut on the desktop"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "Open {#AppName} now"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    SuppressibleMsgBox(
      'Apparel PoS has been removed from this computer.' + #13#10 + #13#10 +
      'Your shop data and its key were NOT deleted. Installing Apparel PoS again brings everything back.',
      mbInformation, MB_OK, IDOK);
end;
