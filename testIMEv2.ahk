#Requires AutoHotkey v2.0


MsgBox "This script will run only on v2.0, keyboard language is " . Get_languege_name()
	SetTimer(Interrupt16,16)
return


;=======================================================================
;	IME 状態のセット
F1::
{
	vImeMode := IME_GET()
	if vImeMode == 0
		IME_SET(1)
	else
		IME_SET(0)
	return
}

;=======================================================================
;	IME 入力モードの設定
F2::
{
	vImeConvMode := IME_GetConvMode()
	if vImeConvMode == 9
		IME_SetConvMode(11)
	else
	if vImeConvMode == 11
		IME_SetConvMode(0)
	else
	if vImeConvMode == 0
		IME_SetConvMode(3)
	else
	if vImeConvMode == 3
		IME_SetConvMode(8)
	if vImeConvMode == 8
		IME_SetConvMode(9)
		
	return
}
#include .\IMEv2.ahk
;=======================================================================
;	タイマー割込み
;	16ミリ秒ごとにIME関数を呼び出す
;-----------------------------------------------------------------------

Interrupt16()
{
	global
	
	vImeMode := IME_GET()
	vImeConvMode := IME_GetConvMode()
	vImeGetSentenceMode := IME_GetSentenceMode()
	szConverting := IME_GetConverting()	
	g_debugout := vImeMode . ":" . vImeConvMode . ":" . szConverting . ":" . vImeGetSentenceMode ; . ":" . g_stGTI . ":" . g_stGTI2
	Tooltip(g_debugout, 0, 0, 2) ; debug
	return
}