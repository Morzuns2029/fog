#Requires AutoHotkey v2.0
#SingleInstance Force

; === Настройки ===
clickerScriptURL := "https://raw.githubusercontent.com/Morzuns2029/clic/main/privatscript.ahk"
clickerScriptFile := "clicker.ahk"
hwidFile := "activated_hwid.txt"
settingsFile := "settings.ini"
keyListURL := "https://raw.githubusercontent.com/Morzuns2029/fog/main/valid_keys.txt"

global thisHWID := GetHWID()

; === Интерфейс ===
ShowMainPanel() {
    panel := Gui("+AlwaysOnTop", "Панель пользователя")

    if !IsActivated() {
        panel.AddText(, "Введите ключ активации:")
        keyInput := panel.AddEdit("w200")
        panel.AddButton("w200", "✅ Активировать").OnEvent("Click", (*) => ActivateKey(keyInput.Value, panel))
    }

    panel.AddButton("w200", "🚀 Запустить кликер").OnEvent("Click", (*) => LaunchClicker(panel))
    panel.AddButton("w200", "♻ Сбросить активацию").OnEvent("Click", (*) => (panel.Destroy(), ResetActivation(), ShowMainPanel()))
    panel.AddButton("w200", "❌ Выход").OnEvent("Click", (*) => ExitApp())
    panel.Show("w250")
}

; === Активация ===
ActivateKey(key, gui) {
    key := Trim(key)
    if key = "" {
        MsgBox "Введите ключ."
        return
    }

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", keyListURL, false)
        http.Send()
        if (http.Status != 200) {
            MsgBox "Ошибка загрузки списка ключей! Код: " http.Status
            return
        }
        keyList := http.ResponseText
    } catch {
        MsgBox "Не удалось загрузить ключи."
        return
    }

    validLines := StrSplit(keyList, "`n")
    found := false
    updatedLines := []

    for line in validLines {
        parts := StrSplit(Trim(line), "|")
        if parts.Length >= 2 {
            keyPart := parts[1]
            statusPart := parts.Length >= 3 ? parts[2] : ""
            if Trim(keyPart) = key && Trim(statusPart) = "unused" {
                found := true
                updatedLines.Push(keyPart "|" thisHWID)
            } else {
                updatedLines.Push(Trim(line))
            }
        } else {
            updatedLines.Push(Trim(line))
        }
    }

    if !found {
        MsgBox "❌ Неверный или использованный ключ."
        return
    }

    FileAppend(thisHWID "`n", hwidFile)
    MsgBox "✅ Активация прошла успешно!"
    gui.Destroy()
    ShowMainPanel()
}

; === Проверка активации ===
IsActivated() {
    return FileExist(hwidFile) && InStr(FileRead(hwidFile), thisHWID)
}

; === Сброс HWID ===
ResetActivation() {
    if !FileExist(hwidFile)
        return
    lines := StrSplit(FileRead(hwidFile), "`n")
    newLines := []
    for line in lines {
        if Trim(line) != thisHWID
            newLines.Push(line)
    }
    FileDelete(hwidFile)
    FileAppend(Join(newLines, "`n"), hwidFile)
    MsgBox "Активация сброшена."
}

; === Скачивание и запуск кликера ===
LaunchClicker(gui) {
    if !IsActivated() {
        MsgBox "Сначала активируйте продукт!"
        return
    }

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", clickerScriptURL, false)
        http.Send()
        if (http.Status != 200) {
            MsgBox "Ошибка загрузки кликера. Код: " http.Status
            return
        }
        file := FileOpen(clickerScriptFile, "w")
        file.Write(http.ResponseText)
        file.Close()
        Run clickerScriptFile
        ExitApp
    } catch {
        MsgBox "Не удалось скачать или запустить кликер."
    }
}

; === HWID ===
GetHWID() {
    RunWait("cmd /c wmic csproduct get uuid > hwid.tmp", , "Hide")
    hwid := Trim(FileRead("hwid.tmp"))
    FileDelete("hwid.tmp")
    return Trim(StrReplace(hwid, "UUID", ""))
}

; === Утилиты ===
Join(arr, sep) {
    result := ""
    for i, v in arr {
        result .= (i > 1 ? sep : "") v
    }
    return result
}

; === Запуск ===
ShowMainPanel()
