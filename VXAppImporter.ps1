
function global:ImportVXApps{
    # Ask for our VXApp Root
    $vxapp_root = $PlayniteApi.Dialogs.SelectFolder()
    # Check for the VXApp Emulator Entry
    $VXAppLoader = $PlayniteApi.Database.Emulators | Where { $_.Name -eq "VXApp" } | Select-Object -First 1
    if(!$VXAppLoader){
        $PlayniteApi.Dialogs.ShowMessage("Couldn't find VXApp emulator configuration in Playnite. Make sure you have VXApp emulator configured.")
        return
    }
    # Pull Current DB to Check for existing games
    $games = $PlayniteApi.Database.Games
    # Iterate each .vxapp directory and generate entries.
    $items = Get-ChildItem -Path $vxapp_root -Directory -Force -ErrorAction SilentlyContinue
    foreach ($item in $items){
        # We'll skip a directory if it doesn't look like a VXApp or if our vxapp.info doesn't exist
        if(!$item.FullName.EndsWith(".vxapp")){continue}
        $appinfo_path = $item.FullName + "\" + "vxapp.info"
        if(-not (Test-Path -LiteralPath $appinfo_path)){continue}

        # Read our VXApp Info file to get some config specifics
        try{
            $appinfo = Get-Content -LiteralPath $appinfo_path -Encoding UTF8 | ConvertFrom-Json
        }catch{
            $PlayniteApi.Dialogs.ShowMessage("Could not Parse VXApp.Info File at " + $appinfo_path)
            continue
        }

        # Skip importing duplicates
        $is_duplicate= 0
        foreach($g in $games){
            if($appinfo.name -eq $g.Name){
                $is_duplicate = 1
            }
        }
        if($is_duplicate){continue}


        # Set up our predefined asset paths and add them if we have them.
        $icon_jpg = $item.FullName + "\" + "icon.jpg"
        $icon_png = $item.FullName + "\" + "icon.png"
        $coverimage_jpg = $item.FullName + "\" + "cover.jpg"
        $coverimage_png = $item.FullName + "\" + "cover.png"
        $backgroundimage_jpg = $item.FullName + "\" + "background.jpg"
        $backgroundimage_png = $item.FullName + "\" + "background.png"

        $game = New-Object "Playnite.SDK.Models.Game" $appinfo.name

        if(Test-Path -LiteralPath $icon_jpg){
            $game.Icon = $PlayniteApi.Database.AddFile($icon_jpg, $game.Id)
        }
        if(Test-Path -LiteralPath $icon_png){
            $game.Icon = $PlayniteApi.Database.AddFile($icon_png, $game.Id)
        }

        if(Test-Path -LiteralPath $coverimage_jpg){
            $game.CoverImage = $PlayniteApi.Database.AddFile($coverimage_jpg, $game.Id)
        }
        if(Test-Path -LiteralPath $coverimage_png){
            $game.CoverImage = $PlayniteApi.Database.AddFile($coverimage_png, $game.Id)
        }

        if(Test-Path -LiteralPath $backgroundimage_jpg){
            $game.BackgroundImage = $PlayniteApi.Database.AddFile($backgroundimage_jpg, $game.Id)
        }
        if(Test-Path -LiteralPath $backgroundimage_png){
            $game.BackgroundImage = $PlayniteApi.Database.AddFile($backgroundimage_png, $game.Id)
        }

        # Add our vxapp location and set up the "Play" and "Close" actions.
        $game.GameImagePath = $item.FullName
        $game.IsInstalled = $true
 
        

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

        # Finally, Parse the vxapp.info and read out all other entrypoints to add as actions.
        foreach ($config in $appinfo.configuration){
            if($config.name -ne "default"){
                $addlplayTask = New-Object "Playnite.SDK.Models.GameAction"
                $addlplayTask.Type = "Emulator"
                $addlplayTask.AdditionalArguments = "config="+$config.name
                $addlplayTask.Name = $config.name
                $addlplayTask.EmulatorId = $VXAppLoader.Id
                $addlplayTask.EmulatorProfileId = $VXAppLoader.Profiles[0].Id
                $game.OtherActions.Add($addlplayTask)
            }
        }
     
    }
}
