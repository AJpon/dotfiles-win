param(
    [switch]$Debug
)

$PSReadLineHistorySaveStyle = "Never"

# $VerbosePreference = "Continue"
if ($PSBoundParameters['Debug']) {
    $DebugPreference = "Continue"
}
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")

if ($PSVersionTable.PSVersion.Major -ge 6 -or -not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath, "-Debug:$($PSBoundParameters['Debug'])" -Verb RunAs;
    $EXITCODE = $?
    if ($EXITCODE -ne 0) {
        Write-Error "Failed to run the script as administrator. Please try again."
    }
    exit $EXITCODE
}

& powershell -NoProfile -ExecutionPolicy Bypass -c "Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force" >> $null

& winget configure -f https://raw.githubusercontent.com/AJpon/dotfiles-win/refs/heads/main/setup.windows.winget --verbose
& winget configure -f https://raw.githubusercontent.com/AJpon/dotfiles-win/refs/heads/main/setup.software.winget --verbose


& winget install --accept-source-agreements --accept-package-agreements --ignore-security-hash -s winget -h --installer-type inno -e --id Microsoft.VisualStudioCode --scope user --custom "/NoIcons=0 /Tasks=addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
& winget install --accept-source-agreements --accept-package-agreements --ignore-security-hash -s winget -h --installer-type inno -e --id Git.Git --scope machine --custom "/NoIcons=0 /Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,windowsterminal,scalar /EditorOption=VisualStudioCode /DefaultBranchOption=main /PathOption=Cmd /SSHOption=OpenSSH /TortoiseOption=false /CURLOption=WinSSL /CRLFOption=LFOnly /BashTerminalOption=MinTTY /GitPullBehaviorOption=Merge /UseCredentialManager=Enabled /PerformanceTweaksFSCache=Enabled /EnableSymlinks=Enabled /EnableFSMonitor=Disabled"
& powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"


& winget install --accept-source-agreements --accept-package-agreements --ignore-security-hash -s winget -h --installer-type inno -e --id MPC-BE.MPC-BE --scope machine --custom "/NoIcons=0 /SetupType=custom /Components=main,mpciconlib,mpcresources,mpcbeshellext,mpcvr,mpcscriptsrc"
& winget install --accept-source-agreements --accept-package-agreements --ignore-security-hash -s winget -h -e --id WiresharkFoundation.Wireshark -custom "/S /EXTRACOMPONENTS=udpdump /desktopicon=no"

& winget install --accept-source-agreements --accept-package-agreements --ignore-security-hash -s winget -h -e Adobe.CreativeCloud 7zip.7zip voidtools.Everything Unity.UnityHub Gyan.FFmpeg Microsoft.DotNet.SDK.9 Notion.Notion DevToys-app.DevToys Fork.Fork dnSpyEx.dnSpy rsteube.Carapace SlackTechnologies.Slack CoreyButler.NVMforWindows MediaArea.MediaInfo.GUI AntibodySoftware.WizTree Insecure.Npcap

if (Get-Command sudo -ErrorAction SilentlyContinue)
{
    & sudo config --enable normal
}

Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3","NetFx4-AdvSrvs","Microsoft-RemoteDesktopConnection","Microsoft-Hyper-V-All","HypervisorPlatform","VirtualMachinePlatform","Microsoft-Windows-Subsystem-Linux"

if (Get-Command git -ErrorAction SilentlyContinue) {
    $homeDir = [Environment]::GetFolderPath("UserProfile")
    git clone https://github.com/AJpon/dotfiles-win.git "$homeDir/dotfiles-win"
}
