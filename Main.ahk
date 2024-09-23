#Requires AutoHotkey v2.0
FileEncoding "UTF-8"
#include IME.ahk

global pressedKeys := Map()
global lastKeyCombo := Map()

modifiersFile := FileOpen("modifiers.txt", "r")
modifiers := modifiersFile.Read()
keysFile := FileOpen("keys.txt", "r")
keys := keysFile.Read()
keymapFile := FileOpen("keymaps.txt", "r")
keymap := Map()

Loop Parse keymapFile.Read(), "`n", "`n"
{
	cleaned := Clean(A_LoopField)
	if (cleaned = "")
	{
		continue
	}
	key := StrSplit(cleaned, ":")
	vks := []
	Loop Parse key[1], ","
	{
		vk := GetKeyVK(A_LoopField)
		if (vk = 0)
		{
			MsgBox("Invalid key: " A_LoopField)
		}
		vks.Push(vk)
	}
	str := ComboToString(vks, false)
	keymap[str] := key[2]
}

Loop Parse, keys, ","
{
    key := Clean(A_LoopField)
	Hotkey(key, KeyDown.Bind(), "B")
	Hotkey(key " up", KeyUp.Bind(key), "B")
}

Loop Parse, modifiers, ","
{
	key := Clean(A_LoopField)
	Hotkey("~" key, SetHotkeysStateKey.Bind(true))
	Hotkey("~" key " up", SetHotkeysStateKey.Bind(false))
}

Clean(str) {
	return StrReplace(StrReplace(StrReplace(Trim(str), " ", ""), "`r", ""), "`n", "")
}

KeyDown(key) {
	global pressedKeys
	if (!pressedKeys.Has(key)) {
		pressedKeys[key] := true
		AddToCombo(GetKeyVK(key))
	}
}

KeyUp(key, name) {
	global pressedKeys, lastKeyCombo
	if (pressedKeys.Has(key))
	{
		pressedKeys.Delete(key)
	}
	if (pressedKeys.Count == 0) {
		TriggerAction(lastKeyCombo)
		lastKeyCombo.Clear()
	}
}

AddToCombo(key) {
	global lastKeyCombo
	if (!lastKeyCombo.Has(key)) {
		lastKeyCombo[key] := true
	}
}

TriggerAction(combo) {
	global keymap
	str := ComboToString(combo, true)
	if (keymap.Has(str)) {
		action := keymap[str]
		SendAction(action)
	}
}

ComboToString(combo, useKey) {
	str := ""
	For key, val in combo
	{
		app := useKey ? key : val
		str .= (A_Index=1) ? app : "," app
	}
	return Sort(str, "N D,")
}

IsKatakana(str) {
    return RegExMatch(str, "^[\x{30A0}-\x{30FF}]+$")
}

SendAction(action) {
	if (IsKatakana(action)) {
		IME_SetConvMode(27)
		SendInput(action)
	} else {
		IME_SetConvMode(25)
		SendInput(action)
	}
}

SetHotkeysState(on) {
	global keys
	str := on ? "On" : "Off"
	Loop Parse, keys, ","
	{
		key := Clean(A_LoopField)
		Hotkey(key, str)
		Hotkey(key " up", str)
	}
}

SetHotkeysStateIME() {
	global keys
	if(IME_GET()) {
		SetHotkeysState(true)
	} else {
		SetHotkeysState(false)
	}
}

SetHotkeysStateKey(on, key) {
	SetHotkeysState(on)
}

SetTimer(SetHotkeysStateIME, 500)
