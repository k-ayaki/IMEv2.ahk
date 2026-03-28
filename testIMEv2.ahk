#Requires AutoHotkey v2.0
#include .\IMEv2.ahk

MsgBox("This script will run only on v2.0, keyboard language is " . Get_language_name())
	SetTimer(InterruptTimer,100)
return


;=======================================================================
;	IME 状態のセット
F1::IME_SET(!IME_GET())

;=======================================================================
;	IME 入力モードの設定
F2::
{
	mode := IME_GetConvMode()
    nextMode := (mode == 9) ? 11 
              : (mode == 11) ? 0 
              : (mode == 0) ? 3 
              : (mode == 3) ? 8 
              : 9
	IME_SetConvMode(nextMode)
	return
}
;=======================================================================
;	タイマー割込み
;	所定時間ごとにIME関数を呼び出す
;-----------------------------------------------------------------------

InterruptTimer()
{
	global g_debugout
	
	vImeMode := IME_GET()
	vImeConvMode := IME_GetConvMode()
	vImeGetSentenceMode := IME_GetSentenceMode()
	szConverting := IME_GetConverting()	
	g_debugout := vImeMode . ":" . vImeConvMode . ":" . szConverting . ":" . vImeGetSentenceMode ; . ":" . g_stGTI . ":" . g_stGTI2
	Tooltip(g_debugout, 0, 0, 2) ; debug
	return
}
