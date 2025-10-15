# Microsoft.PowerShell_profile.ps1
# ##############################################################################
# This profile is for the current user
# This profile loads when the current user opens the PowerShell console
#
# To create a profile for all users, create a profile in the $PSHOME directory
# To create a profile for the current user, create a profile in the $PROFILE directory
# To find the $PROFILE directory, run $PROFILE in the PowerShell console
# To find the $PSHOME directory, run $PSHOME in the PowerShell console
#
# ##############################################################################

using namespace System.Management.Automation
using namespace System.Windows
using namespace Microsoft.PowerShell

# Prepare for Windows Powershell 5.1 and below
if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Set the console to use UTF-8 encoding
    # $OutputEncoding = [System.Text.Encoding]::UTF8
    # Set the console to use UTF-8 encoding for input
    # $Host.UI.RawUI.InputEncoding = [System.Text.Encoding]::UTF8

    Set-Variable IsWindows $true -Option Constant, AllScope -Force
    Set-Variable IsMacOS $false -Option Constant, AllScope -Force
    Set-Variable IsLinux $false -Option Constant, AllScope -Force
}

# consts for Color and Style of the prompt
# https://docs.microsoft.com/en-us/dotnet/api/system.consolecolor?view=net-5.0
# ANSI Escape Code
# https://en.wikipedia.org/wiki/ANSI_escape_code
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# https://godoc.org/github.com/whitedevops/colors

Set-Variable -Name "bcolors" -Value (New-Module -AsCustomObject -ScriptBlock {
        # Background Colors
        [string]$BGDEFAULT = "`e[49m"
        [string]$BGBLACK = "`e[40m"
        [string]$BGRED = "`e[41m"
        [string]$BGGREEN = "`e[42m"
        [string]$BGYELLOW = "`e[43m"
        [string]$BGBLUE = "`e[44m"
        [string]$BGMAGENDA = "`e[45m"
        [string]$BGCYAN = "`e[46m"
        [string]$BGWHITE = "`e[47m"

        # Colors
        [string]$DEFAULT = "`e[39m"
        [string]$BLACK = "`e[30m"
        # [string]$DARKRED        = "`e[31m"
        # [string]$DARKGREEN      = "`e[32m"
        # [string]$DARKYELLOW     = "`e[33m"
        # [string]$DARKBLUE       = "`e[34m"
        # [string]$DARKMAGENDA    = "`e[35m"
        # [string]$DARKCYAN       = "`e[36m"
        [string]$GRAY = "`e[37m"
        [string]$RED = "`e[91m"
        [string]$GREEN = "`e[92m"
        [string]$YELLOW = "`e[93m"
        [string]$BLUE = "`e[94m"
        [string]$MAGENDA = "`e[95m"
        [string]$CYAN = "`e[96m"
        [string]$WHITE = "`e[97m"

        # Formatting
        [string]$ENDC = "`e[0m"
        [string]$BOLD = "`e[1m"
        [string]$DIM = "`e[2m"
        [string]$UNDERLINE = "`e[4m"
        [string]$BLINK = "`e[5m"
        [string]$REVERSE = "`e[7m"
        [string]$NEGATIVE = "`e[7m"
        # [string]$HIDDEN         = "`e[8m"
        # [string]$CROSSEDOUT     = "`e[9m"

        Export-ModuleMember -Variable *
    }) -Option ReadOnly



# Set the default prompt
function UserPrompt {
    param (
        [string]$prefix = "PS"
    )

    # ユーザー名を取得
    $username = $env:UserName
    # pc の名前を取得 大文字で取得されるので小文字にする
    $computername = $env:ComputerName.ToLower()

    # ドライブ名を取得 C とか D とか
    # $drive = $PWD.Drive.Name

    # ドライブ名(C:) を除き、ホームディレクトリ(/users/{name}) は ~ に変換したパスを取得
    # 変換後のパス末尾が \ で終わらない場合は、\ を追加
    # $wd = $PWD.path.Replace($HOME, "~").Replace("${drive}:", "")
    $wd = $PWD.path.Replace($HOME, "~").Replace("C:", "")
    if ($wd[-1] -ne '\') {
        $wd += '\'
    }


    # 現在のセッションが管理者権限で実行されているかどうかによってプロンプトの文字を変更
    $isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    $promptChar = if ($isAdmin) { "#" } else { ">" }

    # タイトルバーに表示する文字列
    $host.UI.RawUI.WindowTitle = "${prefix} ${promptChar} ${wd}"

    # プロンプトの表示
    # [ユーザー名@コンピュータ名:カレントディレクトリ] と コマンド入力行に分ける
    Write-Host "$username@$computername" -ForegroundColor "DarkGreen" -NoNewLine
    Write-Host ":" -NoNewLine
    Write-Host "$wd" -ForegroundColor "DarkBlue"

    Write-Host "${prefix} ${promptChar}" -NoNewLine

    return " "
}
# 他のプロファイルからこのプロンプト関数を呼び出すためのエイリアス
Set-Alias -Name Prompt -Value UserPrompt

#region Custom Prompt
#region Reset
function Reset-Session {
    # store this shell's parent PID for later use
    $parentPID = $PID
    # get the the path of this shell's executable
    $thisExePath = (Get-Process -Id $PID).Path
    # start a new shell, same window
    Write-Host "`nOpen New Session" -ForegroundColor Yellow
    Start-Process $thisExePath -NoNewWindow
    # stop this shell if it's still alive
    Stop-Process -Id $parentPID -Force
}
Set-Alias -Name reset -Value Reset-Session

#endregion Reset


#region Invoke-WithVariable
<#
.SYNOPSIS
    Invokes a command with legacy variable format support.

.DESCRIPTION
    This function allows you to invoke a command with support for legacy variable format. It replaces %var% with $Env:var and %cd% with $PWD in the command.

.PARAMETER Command
    Specifies the command to be invoked.

.EXAMPLE
    Invoke-WithLegacyVariableFormat -Command 'echo %USERNAME%'

    This example invokes the 'echo' command with the legacy variable format '%USERNAME%'. It will replace '%USERNAME%' with the value of $Env:USERNAME and execute the command.

#>
function Invoke-WithLegacyVariableFormat {
    param (
        [string]$Command
    )

    # コマンド中の%var%を$Env:varに変換し、%cd%を$PWDに変換する
    $Command = $Command -replace '%(.*?)%', {
        param($match)
        $variable = $match.Groups[1].Value
        if ($variable -eq 'cd') {
            return '$PWD'
        }
        elseif ($ExecutionContext.SessionState.PSVariable.Get($variable, [ScopedItemOptions]::None)) {
            return '$Env:' + $variable
        }
        else {
            return $match.Value
        }
    }

    Write-Host "Invoke-Expression $Command" -ForegroundColor Yellow

    # 別のコマンドを呼び出す
    Invoke-Expression $Command
}
# cmd形式の変数が使えることがわかるエイリアス名
Set-Alias -Name runWithLegacyVars -Value Invoke-WithLegacyVariableFormat
Set-Alias -Name V-Run -Value Invoke-WithLegacyVariableFormat
# ショートカットキー
Set-PSReadLineKeyHandler -Chord Ctrl+Enter `
    -BriefDescription RunWithLegacyVars `
    -LongDescription "Run command with cmd-style variables" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [PSConsoleReadLine]::DeleteLine()
    [PSConsoleReadLine]::Insert('V-Run ' + "'" + $line + "'" )
    [PSConsoleReadLine]::AcceptLine()

    Write-Host "`n$error " -ForegroundColor Red
}
#endregion Invoke-WithVariable

#region Reload-Profile
function Import-Profile($profilePath = $PROFILE) {
    # プロファイルの読み込み
    . $profilePath
}
function Reload-Profile {
    Import-Profile $PROFILE
    Write-Host "`nReloaded PROFILE`n`n" -ForegroundColor Green -NoNewline
}
# bash like import command
Set-Alias -Name .profile -Value Reload-Profile
Set-Alias -Name source -Value Import-Profile
#endregion Reload-Profile

#region Add-Operator
# 呼び出し演算子なしでコマンドを実行する
function Invoke-CommandWithoutCallOperator {
    param (
        [string]$Command
    )

    # コマンドを実行
    Invoke-Expression $Command
}
Set-Alias -Name run -Value Invoke-CommandWithoutCallOperator

#endregion Add-Operator

if ($IsWindows) {
    function VisualStudioShell {
        param (
            [int] $version = 2022,
            [string] $edition = "Community",
            [string] $targetArch = "x64",
            [string] $hostArch = "x64",
            [boolean] $vcpkg = $true
        )

        $VsBasePath = "${ENV:ProgramFiles}\Microsoft Visual Studio\${version}\${edition}"
        $VsInstallationPath = "${VsBasePath}\Common7\Tools"
        $DevShellAssemblyName = "Microsoft.VisualStudio.DevShell.dll"

        function GetSetupConfigurations {
            param (
                [string]
                $whereArgs = "-path `"$VsInstallationPath`"",
                [string]
                $VsWherePath = "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
            )
            $expression = "& `"$VsWherePath`" $whereArgs -format json"
            Invoke-Expression $expression | ConvertFrom-Json
        }

        $vsModulePath = "${VsInstallationPath}\vsdevshell\$DevShellAssemblyName"
        $vsModulePath = if (Test-Path $vsModulePath) { $vsModulePath } else { "${VsInstallationPath}\$DevShellAssemblyName" }

        if (-not (Test-Path $vsModulePath)) {
            # Write-Error "Visual Studio $edition $version is not installed."
            Write-Error "Visual Studio Developer Shell module not found.`n    $vsModulePath"
            return
        }

        try {
            Import-Module -Name $vsModulePath
        }
        catch [System.IO.FileLoadException] {
            Write-Verbose "The module has already been imported from a different installation of Visual Studio:"
            (Get-Module Microsoft.VisualStudio.DevShell).Path | Write-Verbose
        }

        $config = GetSetupConfigurations
        $vsInstanceId = $config.instanceId
        Enter-VsDevShell $vsInstanceId -SkipAutomaticLocation -DevCmdArguments "-arch=${targetArch} -host_arch=${hostArch}"

        if ($vcpkg) {
            $vcpkgModulePath = "${VsBasePath}\VC\vcpkg\scripts\posh-vcpkg"
            Import-Module -Name $vcpkgModulePath
        }

        # プロンプトを変更
        function VSPrompt {return UserPrompt -prefix ($bcolors.CYAN + "VS${edition}${version} PWSH" + $bcolors.ENDC)}
        set-alias Prompt VSPrompt
    }
}

#endregion Custom Prompt



#region PSReadLine


#region PSReadLine settings
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadlineOption -AddToHistoryHandler {
    param ($command)
    switch -regex ($command) {
        "SKIPHISTORY" { return $false } # SKIPHISTORY is a special command that will not be added to history
        "^[a-z]$" { return $false }
        "exit" { return $false }
    }
    return $true
}

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadlineOption -HistorySaveStyle SaveIncrementally
Set-PSReadlineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineOption -EditMode Windows # Emacs
#endregion PSReadLine settings


#region PSReadLine keybindings
# Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function Undo

# Session Reset Shortcut Key
Set-PSReadLineKeyHandler -Key Ctrl+n `
    -BriefDescription ResetSession `
    -LongDescription "Reset and Start New Session" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [PSConsoleReadLine]::DeleteLine()
    [PSConsoleReadLine]::Insert('<#SKIPHISTORY#> reset')
    [PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Alt+Backspace `
    -BriefDescription RemoveFromHistory `
    -LongDescription "Removes the content of the current line from history" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $toRemove = [Regex]::Escape(($line -replace "\n", "```n"))
    $history = Get-Content (Get-PSReadLineOption).HistorySavePath -Raw
    $history = $history -replace "(?m)^$toRemove\r\n", ""
    # 成功したか否かで分岐させる (try-catch)
    try {
        Set-Content (Get-PSReadLineOption).HistorySavePath $history -NoNewline
    }
    catch {
        Write-Host "`nFailed to remove the line from history." -ForegroundColor Red -NoNewline
        return
    }
    # Get-PSReadLineOption | ForEach-Object { Set-PSReadLineOption -HistorySavePath $_.HistorySavePath }
    Write-Host "`nRemoved the line from history. Please run Reset-Session (Ctrl+N) to apply the changes." -ForegroundColor Green -NoNewline
}

Set-PSReadLineKeyHandler -Key Ctrl+Shift+R `
    -BriefDescription "Reload PROFILE" `
    -LongDescription "Reload PROFILE" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    [PSConsoleReadLine]::DeleteLine()
    Write-Host "" -NoNewline
    [PSConsoleReadLine]::Insert('<#SKIPHISTORY#> . $PROFILE')
    [PSConsoleReadLine]::AcceptLine()
    Write-Host "`nReloaded PROFILE`n`n" -ForegroundColor Green -NoNewline
}
Set-PSReadLineKeyHandler -Key Alt+v `
    -BriefDescription SkipFromHistory `
    -LongDescription "Skip the current line from history" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [PSConsoleReadLine]::DeleteLine()
    [PSConsoleReadLine]::Insert('<#SKIPHISTORY#> ' + $line)
}

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.
Set-PSReadLineKeyHandler -Key Alt+w `
    -BriefDescription SaveInHistory `
    -LongDescription "Save current line in history but do not execute" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [PSConsoleReadLine]::AddToHistory($line)
    [PSConsoleReadLine]::RevertLine()
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
    -BriefDescription PasteAsHereString `
    -LongDescription "Paste the clipboard text as a here string" `
    -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([Clipboard]::ContainsText()) {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
        [PSConsoleReadLine]::Insert("@'`n$text`n'@")
    }
    else {
        [PSConsoleReadLine]::Ding()
    }
}

# F1 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F1 `
    -BriefDescription CommandHelp `
    -LongDescription "Open the help window for the current command" `
    -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
            $node = $args[0]
            $node -is [Language.CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null) {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null) {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [AliasInfo]) {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null) {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}
#endregion PSReadLine keybindings


#endregion PSReadLine


################################
### BEGIN: 3rd Party Modules ###
################################

# uv Completion
if (Get-Command uv -ErrorAction SilentlyContinue) {
    (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
}
else{
    Write-Host (
        $bcolors.MAGENDA +
        "  uv is not installed. Install it from https://astral.sh/`n" +
        $bcolors.CYAN +
        '    ➤  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"' +
        $bcolors.ENDC + "`n"
    )
}

if (Get-Command dsc -ErrorAction SilentlyContinue) {
    # dsc Completion
    (& dsc completer powershell) | Out-String | Invoke-Expression
}

# carapace Completion
if (Get-Command carapace -ErrorAction SilentlyContinue) {
    # ~/.config/powershell/Microsoft.PowerShell_profile.ps1
    $env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
    Set-PSReadLineOption -Colors @{ "Selection" = $bcolors.NEGATIVE }
    # All Completions
    carapace _carapace | Out-String | Invoke-Expression
    # Specific Completions Example: git, docker, kubectl, etc.
    # carapace git completion | Out-String | Invoke-Expression
}
else {
    Write-Host (
        $bcolors.MAGENDA +
        "  Carapace is not installed. Install it from https://carapace.sh or WinGet. `n" +
        $bcolors.CYAN +
        "    ➤  winget install -e --id rsteube.Carapace" + $bcolors.ENDC + "`n"
    )
}
