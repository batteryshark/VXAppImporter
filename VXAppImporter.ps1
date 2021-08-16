
function global:ImportVXApps{
    $vxapp_root = "c:\apps"
    $VXAppLoader = $PlayniteApi.Database.Emulators | Where { $_.Name -eq "VXApp" } | Select-Object -First 1
    if(!$VXAppLoader){
        $PlayniteApi.Dialogs.ShowMessage("Couldn't find VXApp emulator configuration in Playnite. Make sure you have VXApp emulator configured.")
        return
    }
    $items = Get-ChildItem -Path $vxapp_root -Directory -Force -ErrorAction SilentlyContinue
    # Check for existing game
    $games = $PlayniteApi.Database.Games
    foreach ($item in $items){
        $appinfo_path = $item.FullName + "\" + "vxapp.info"
        $icon_path = $item.FullName + "\" + "icon.png"
        
        $appinfo_path = $appinfo_path.replace("[", "``[").replace("]", "``]")
        $appinfo = Get-Content $appinfo_path -Encoding UTF8 | ConvertFrom-Json
        Write-Output("Processing " + $appinfo.name + "...")
        $game = New-Object "Playnite.SDK.Models.Game" $appinfo.name
        $is_duplicate= 0
        foreach($g in $games){
            if($appinfo.name -eq $g.Name){
                $is_duplicate = 1
            }
        }
        if($is_duplicate){continue}

        $game.GameImagePath = $item.FullName
        $game.IsInstalled = $true
        if(Test-Path -LiteralPath $icon_path){
            $game.Icon = $PlayniteApi.Database.AddFile($icon_path, $game.Id)
        }
        

        $playTask = New-Object "Playnite.SDK.Models.GameAction"
        $playTask.Type = "Emulator"
        $playTask.Name = "Play"
        $playTask.EmulatorId = $VXAppLoader.Id
        $playTask.EmulatorProfileId = $VXAppLoader.Profiles[0].Id
        $game.PlayAction =  $playTask
        $PlayniteApi.Database.Games.Add($game)

        $closeTask = New-Object "Playnite.SDK.Models.GameAction"
        $closeTask.Name = "Close App"
        $closeTask.Type = "Emulator"
        $closeTask.EmulatorId = $VXAppLoader.Id
        $closeTask.EmulatorProfileId = $VXAppLoader.Profiles[1].Id
        
        $game.OtherActions = [Playnite.SDK.Models.GameAction]::new()
        $game.OtherActions[0] = $closeTask
        $default_tag = "default"
        foreach ($config in $appinfo.configuration){
            if($config.name -ne $default_tag){
                $playTask.AdditionalArguments = "config="+$config.name
                $playTask.Name = $config.name
                $game.OtherActions.Add($playTask)
            }
        }
     
    }
}
