#Requires AutoHotkey v2.0
#include IME.ahk

global pressedKeys := Map()
global lastKeyCombo := Map()

keysFile := FileOpen("steno_keys.txt", "r")
keys := keysFile.Read()
keymapFile := FileOpen("steno_keymap_converted.txt", "r")
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

SendAction(action) {
	SendInput(action)
}


SetHotkeysState() {
	global keys
	if(IME_GET()) {
		Loop Parse, keys, ","
		{
			key := Clean(A_LoopField)
			Hotkey(key, "On")
			Hotkey(key " up", "On")
		}
	} else {
		Loop Parse, keys, ","
		{
			key := Clean(A_LoopField)
			Hotkey(key, "Off")
			Hotkey(key " up", "Off")
		}
	}
}

SetTimer(SetHotkeysState, 500)
