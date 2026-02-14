#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Lib\OCR.ahk
#Include Lib\JSON.ahk
CoordMode "Mouse", "Client"

if A_IsCompiled {
    mainTemp := A_AppData "\Superforest"
    if not DirExist(mainTemp)
       DirCreate (mainTemp)

    if not DirExist(mainTemp "\Assets")
       DirCreate (mainTemp "\Assets")

    if not DirExist(mainTemp "\Lib")
       DirCreate(mainTemp "\Lib")

    if not FileExist(mainTemp "\Assets\ps to deeplink.txt") {
       FileInstall "Assets\ps to deeplink.txt", mainTemp "\Assets\ps to deeplink.txt", true
    }
    
    if not FileExist(mainTemp "\Assets\splash.png") {
       FileInstall "Assets\splash.png", mainTemp "\Assets\splash.png", true
    }

    if not FileExist(mainTemp "\Lib\config.ini") {
       FileInstall "Lib\config.ini", mainTemp "\Lib\config.ini", true
    }

    if not FileExist(mainTemp "\Lib\OCR.ahk") {
       FileInstall "Lib\OCR.ahk", mainTemp "\Lib\OCR.ahk", true
    }

    if not FileExist(mainTemp "\Lib\JSON.ahk") {
        FileInstall "Lib\JSON.ahk", mainTemp "\Lib\JSON.ahk", true
    }

    global configIni := mainTemp "\Lib\config.ini"
    global splashImage := mainTemp "\Assets\splash.png"    

} else {
    global configIni := A_ScriptDir "\Lib\config.ini"
    global splashImage := A_ScriptDir "\Assets\splash.png"
}

$F5::Pause -1
$F7::ExitApp

DeepLink := IniRead(configIni, "UserConfig", "DeepLink")
DelayMultiplier := IniRead(configIni, "UserConfig", "DelayMultiplier")
ReconnectionDelay := IniRead(configIni, "UserConfig", "ReconnectionDelay")
WebHookUrl := IniRead(configIni, "UserConfig", "WebHookUrl")

potionSlot := 0
deepLinkRun := false

maxW := A_ScreenWidth * 0.5
maxH := A_ScreenHeight * 0.5

w := Round(Min(maxW, maxH * (16/9)))
h := Round(w * 9 / 16)

SplashGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Splash")
SplashGui.Add("Picture", Format("x0 y0 w{} h{}", w, h), SplashImage)
SplashGui.Show(Format("w{} h{} Center", w, h))
Sleep(3000)

hWnd := SplashGui.Hwnd
Loop 30 {
    level := Round(255 - A_Index * 8.5)
    WinSetTransparent(level, "ahk_id " hWnd)
    Sleep(15)
}
SplashGui.Destroy()

global MainGui := Gui("+Owner", "Superforest Macro v1.0")
Tabs := MainGui.Add("Tab3",, ["Config", "Updates", "Info"])

Tabs.UseTab(1)
MainGui.Add("Text", "x20 y40", "Private Server Deeplink")
DeepLinkControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll" , DeepLink)

MainGui.Add("Text", "x20 y70", "Delay Multiplier")
DelayMultiplierControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right" , DelayMultiplier)

MainGui.Add("Text", "x20 y100", "Reconnection Delay (sec)")
ReconnectionDelayControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right" , ReconnectionDelay)

MainGui.Add("Text", "x20 y130", "Discord Webhook URL")
WebHookUrlControl := MainGui.Add("Edit", "x175 yp-3 h20 w150 -VScroll +Right +Disabled" , WebHookUrl)

MainGui.Add("Button", "x20 y160 w305 h30", "Run Macro").OnEvent("Click", RunMacro)
MainGui.Add("Button", "x20 y195 w305 h30", "Save Settings").OnEvent("Click", SaveSettings)
MainGui.Add("Text", "x20 y235", "Save the config after changing settings before running the macro.")

Tabs.UseTab(2)
MainGui.Add("Text", "x20 y40", "Updates")
MainGui.Add("Text", "x20 y60", "v1.0 (2/15/26)")
MainGui.Add("Text", "x20 y80", "- Initial release with core functionality.")
MainGui.Add("Text", "x20 y110", "v1.1 (Coming Soon)")
MainGui.Add("Text", "x20 y130", "- Auto rejoin character if disconnected")
MainGui.Add("Text", "x20 y150", "- Discord Webhook integration for notifications")

MainGui.Add("Text", "x20 y240 +Right", "Made with love from allyqnts ❤️")

Tabs.UseTab(3)
MainGui.Add("Text", "x20 y40 w305 +Center", "Welcome to Superforest Macro!")
MainGui.Add("Text", "x20 y60 w305 +Center", "Automation macro for potion farming and reconnection handling.")

MainGui.Add("Text", "x20 y90", "Core Funtions:")
MainGui.Add("Text", "x20 y110", "- Detects environment using OCR")
MainGui.Add("Text", "x20 y130", "- Moves character automatically")
MainGui.Add("Text", "x20 y150", "- Buys and uses potions in sequence")
MainGui.Add("Text", "x20 y170", "- Rejoins server if required using deep link")

MainGui.Add("Text", "x20 y200", "Important:")
MainGui.Add("Text", "x20 y220", "Always save config before running.")
MainGui.Add("Text", "x20 y240", "Do not interact with Roblox while macro is running.")

SaveSettings(*) {
    global MainGui, configIni
    MainGui.Submit()

    IniWrite(DeepLinkControl.Text, configIni, "UserConfig", "DeepLink")
    IniWrite(DelayMultiplierControl.Text, configIni, "UserConfig", "DelayMultiplier")
    IniWrite(ReconnectionDelayControl.Text, configIni, "UserConfig", "ReconnectionDelay")
    IniWrite(WebHookUrlControl.Text, configIni, "UserConfig", "WebHookUrl")

    MsgBox "Settings saved successfully!"
    ExitApp
}

MainGui.Show()
MainGui.OnEvent("Close", (*) => ExitApp())

RunMacro(*) {
    global MainGui

    MainGui.Destroy()
    CheckRobloxWindow()
}

CheckRobloxWindow() {
   global potionSlot, deepLinkRun, DeepLink, DelayMultiplier, ReconnectionDelay

   Loop {
        rblxWindows := WinGetList("ahk_exe RobloxPlayerBeta.exe")

        if (rblxWindows.Length = 0) {
            MsgBox "No Roblox windows found."
            ExitApp
        } else if (rblxWindows.Length > 1) {
            MsgBox "Multiple Roblox windows found. Please close other Roblox windows."
            ExitApp
        }

        hwnd := rblxWindows[1]
        WinActivate(hwnd)
        WinWaitActive(hwnd)
        WinRestore(hwnd)
        WinMove(, , 800, 600, hwnd)
        Tooltip "Roblox found and resized"
        Sleep (1000 * DelayMultiplier)
        SendEvent "{Click 305 38}"
        Sleep (1000 * DelayMultiplier)

        findCharFacing := OCR.FromWindow(hwnd, {scale:4})
        fullText := findCharFacing.Text

        words := ["Witch", "Cottage", "Rare", "Cloud", "Boosts"]

        found := false
        for word in words {
            if InStr(fullText, word) {
                found := true
                break
            }
        }

        if found {
            Tooltip "Word found in window, going to Potions."
            Sleep (1000 * DelayMultiplier)
            SendEvent "{Click 305 38}"
            Sleep (1000 * DelayMultiplier)
            Tooltip
            MoveChars()
            Loop {
               BuyPotions()
               UsePotions(potionSlot)

                potionSlot++
                if (potionSlot > 9) {
                    potionSlot := 0
                }

               Sleep (1000 * DelayMultiplier)
            }
            deepLinkRun := false
            break
        }

        Tooltip "Word not found in window, Turning character."
        Sleep (1000 * DelayMultiplier)
        TurnCharacter180()
        Sleep (1000 * DelayMultiplier)

        findCharFacing := OCR.FromWindow(hwnd, {scale:4})
        fullText := findCharFacing.Text

        foundAfterTurn := false
        for word in words {
            if InStr(fullText, word) {
                foundAfterTurn := true
                break
            }
        }

        if foundAfterTurn {
            Tooltip "Word found after turn, going to Potions."
            Sleep (1000 * DelayMultiplier)
            SendEvent "{Click 305 38}"
            Sleep (1000 * DelayMultiplier)
            Tooltip
            MoveChars()
            Loop {
               BuyPotions()
               UsePotions(potionSlot)

               potionSlot++
                if (potionSlot > 9) {
                    potionSlot := 0
                }
                
               Sleep (1000 * DelayMultiplier)
            }
            deepLinkRun := false
            break
        }
            
        if !foundAfterTurn && !deepLinkRun {
            Tooltip "Word not found after turn, rejoining via deeplink."
            Run(DeepLink)
            deepLinkRun := true

            totalWait := ReconnectionDelay
            Loop totalWait {
                Tooltip "Rejoining via deeplink, " (totalWait - A_Index + 1) "s left"
                Sleep (1000)
            }
            
            Tooltip
            deepLinkRun := false
        }

        Sleep (2000 * DelayMultiplier)
   }
}

TurnCharacter180() {
   SendInput "{Right down}"
   Sleep (1500)
   SendInput "{Right up}"
   Sleep (500)
}

MoveChars() {
   SendInput "{w down}"
   Sleep (7650)
   SendInput "{w up}"
   Sleep (1000)
   SendInput "{d down}"
   Sleep (1750)
   SendInput "{d up}"
   Sleep (500)
}

BuyPotions() {
   SendInput "{e down}"
   Sleep (2000)
   SendInput "{e up}"
   Sleep (2000)
   Loop 5 {
      SendEvent "{Click 410 504}"
      Sleep (250)
   }
}

UsePotions(slot) {
   SendEvent "{Click 628 102}"
   Sleep (500)
   Send "{" slot "}"
   Sleep (500)
   SendEvent "{Click 303 416}"
   Sleep (500)
}

SendDiscordMessage(message) {
    global configIni, WebHookUrl

    if !WebHookUrl
        return

    time := FormatTime(, "hh:mm:ss tt")
    formatted := time . " - " . message

    payload := JSON.stringify({content: formatted})
    Http := ComObject("WinHttp.WinHttpRequest.5.1")
    Http.Open("POST", WebHookUrl, false)
    Http.SetRequestHeader("Content-Type", "application/json")
    Http.Send(payload)
}