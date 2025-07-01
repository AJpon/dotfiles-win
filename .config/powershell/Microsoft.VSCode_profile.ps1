# Description: This profile is loaded when using PowerShell extension in Visual Studio Code.

# import Default profile
. (Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1")

if (-not $IsWindows) {
    return
}

function VSCodePrompt {
    return UserPrompt -prefix ($bcolors.CYAN + "Code PS Extention" + $bcolors.ENDC)
}
set-alias Prompt VSCodePrompt
