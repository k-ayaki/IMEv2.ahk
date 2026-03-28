#Requires AutoHotkey v2.0
#Include .\IMEv2.ahk

; ==============================================================================
; IME_GetConverting テストツール
; 終了するには Esc キーを押してください
; ==============================================================================

; 50ミリ秒ごとにチェック関数を実行
SetTimer(CheckConvertingState, 50)

; 状態監視用関数
CheckConvertingState() {
    ; IME_GetConverting の戻り値を取得
    state := IME_GetConverting()
    
    ; 戻り値に応じたメッセージを作成
    switch state {
        case 0:
            statusText := "0: 通常状態 (入力なし)"
        case 1:
            statusText := "1: 文字入力中 / 変換中"
        case 2:
            statusText := "2: 変換候補窓 表示中"
        default:
            statusText := state . ": 不明な状態"
    }
    
    ; 画面の左上に常に状態を表示 (座標 10, 10)
    ; マウスに追従させたい場合は引数の 10, 10 を消してください
    ToolTip("=== IME_GetConverting テスト ===" . "`n" . statusText, 10, 10)
}

; Escキーでスクリプトを終了
Esc:: {
    ToolTip() ; ツールチップを消去
    ExitApp()
}