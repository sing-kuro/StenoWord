#Requires AutoHotkey v2.0
FileEncoding "UTF-8"
#include IME.ahk

global pressedKeys := Map()
global lastKeyCombo := Map()

modifiersFile := FileOpen("modifiers.txt", "r")
modifiers := modifiersFile.Read()
keymapFile := FileOpen("keymaps.txt", "r")
keymap := Map()
dictFile := FileOpen("dict.txt", "r")
dict := Map()

Loop Parse dictFile.Read(), "`n", "`n"
{
	cleaned := Clean(A_LoopField)
	if (cleaned = "")
	{
		continue
	}
	mapping := StrSplit(cleaned, ":")
	key := ""
	Loop Parse mapping[1]
	{
		key .= (A_Index=1) ? Clean(A_LoopField) : "," Clean(A_LoopField)
	}
	key := Sort(key, "D,")
	dict[key] := mapping[2]
}

Loop Parse keymapFile.Read(), "`n", "`n"
{
	cleaned := Clean(A_LoopField)
	if (cleaned = "")
	{
		continue
	}
	mapping := StrSplit(cleaned, ":")
	keymap[mapping[2]] := mapping[1]
}

for key, _ in keymap
{
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
		AddToCombo(key)
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
	global dict
	str := ApplyKeymap(combo)
	if (dict.Has(str)) {
		action := dict[str]
		SendAction(action)
	}
}

ApplyKeymap(combo) {
	global keymap
	str := ""
	for key, _ in combo {
		if (keymap.Has(key)) {
			str .= keymap[key] ","
		}
	}
	str := SubStr(str, 1, StrLen(str) - 1)
	str := Sort(str, "D,")
	return str
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
	str := on ? "On" : "Off"
	for key, _ in keymap
	{
		Hotkey(key, str)
		Hotkey(key " up", str)
	}
}

SetHotkeysStateIME() {
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
