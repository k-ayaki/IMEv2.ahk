#Requires AutoHotkey v2.0
;;; IME.ahk NYSL <http://www.kmonos.net/nysl/>
;;; AutoHotokeyを流行らせるアップローダ <http://lukewarm.s101.xrea.com/up/> の 089.zip [Shift&Space + IME.ahk] (2008/09/21 20:18)

;;; Index of /_pub/eamat/MyScript の IME20091203.zip (IME.ahk)
;;; http://www6.atwiki.jp/eamat/pub/MyScript/

;;; IME20121110.zip (本家,A32/U32/U64 同梱)
;; http://www6.atwiki.jp/_pub/eamat/MyScript/Lib/IME20121110.zip

;; AutoHotkey_L (unicode binaries) に準拠した
;; レジストリから使用中のimeの情報を取得できるようにした
;; 推測変換(atok)や予想入力(msime)中は変換候補窓が出ていないものとして取り扱うようにした

/*****************************************************************************
  IME制御用 関数群 (IME.ahk)

    グローバル変数 : なし
    各関数の依存性 : なし(必要関数だけ切出してコピペでも使えます)

    AutoHotkey:     v 2.0
    Language:       Japanease
    Platform:       NT系
    Author:         v 1.1 eamat.      http://www6.atwiki.jp/eamat/
    				v 2.0 Ken'ichiro Ayaki
*****************************************************************************
履歴
    2008.07.11 v1.0.47以降の 関数ライブラリスクリプト対応用にファイル名を変更
    2008.12.10 コメント修正
    2009.07.03 IME_GetConverting() 追加 
               Last Found Windowが有効にならない問題修正、他。
    2009.12.03
      ・IME 状態チェック GUIThreadInfo 利用版 入れ込み
       （IEや秀丸8βでもIME状態が取れるように）
        http://blechmusik.xrea.jp/resources/keyboard_layout/DvorakJ/inc/IME.ahk
      ・Google日本語入力β 向け調整
        入力モード 及び 変換モードは取れないっぽい
        IME_GET/SET() と IME_GetConverting()は有効

    2012.11.10 x64 & Unicode対応
      実行環境を AHK_L U64に (本家およびA32,U32版との互換性は維持したつもり)
      ・LongPtr対策：ポインタサイズをA_PtrSizeで見るようにした

                ;==================================
                ;  GUIThreadInfo 
                ;=================================
                ; 構造体 GUITreadInfo
                ;typedef struct tagGUITHREADINFO {(x86) (x64)
                ;   DWORD   cbSize;                 0    0
                ;   DWORD   flags;                  4    4   ※
                ;   HWND    hwndActive;             8    8
                ;   HWND    hwndFocus;             12    16  ※
                ;   HWND    hwndCapture;           16    24
                ;   HWND    hwndMenuOwner;         20    32
                ;   HWND    hwndMoveSize;          24    40
                ;   HWND    hwndCaret;             28    48
                ;   RECT    rcCaret;               32    56
                ;} GUITHREADINFO, *PGUITHREADINFO;

      ・WinTitleパラメータが実質無意味化していたのを修正
        対象がアクティブウィンドウの時のみ GetGUIThreadInfoを使い
        そうでないときはControlハンドルを使用
        一応バックグラウンドのIME情報も取れるように戻した
        (取得ハンドルをWindowからControlに変えたことでブラウザ以外の大半の
        アプリではバックグラウンドでも正しく値が取れるようになった。
        ※ブラウザ系でもアクティブ窓のみでの使用なら問題ないと思う、たぶん)

    2025.03.28
      実行環境を Autohotkey v2.0 とする。
      ファイル名を IMEv2.ahk に変更。
*/
; ==============================================================================
; 内部用：ターゲットとなるGUIスレッドのHWNDを取得する
; ==============================================================================
_IME_GetFocusHwnd(WinTitle := "A") {
    hwnd := WinExist(WinTitle)
    if WinActive(WinTitle) {
        stGTI := Buffer(24 + (A_PtrSize * 6), 0)
        NumPut("UInt", stGTI.Size, stGTI)
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI, "Int")
            return NumGet(stGTI, 8 + A_PtrSize, "Ptr") || hwnd
    }
    return hwnd
}
; ==============================================================================
; 内部用共通関数：フォーカスのあるHWNDを取得し、IMEへメッセージを送信する
; ==============================================================================
_IME_SendMessage(WinTitle, wParam, lParam := 0) {
    hwnd := _IME_GetFocusHwnd(WinTitle)
    if !hwnd
    	return 0

    imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
    if !imeWnd
        return 0
    
    return DllCall("SendMessage"
        , "Ptr", imeWnd
        , "UInt", 0x0283    ; WM_IME_CONTROL
        , "Ptr", wParam
        , "Ptr", lParam)
}

; ==============================================================================
; IME 制御関数群 (すべて1行で記述可能になります)
; ==============================================================================
;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle := "A")                     => _IME_SendMessage(WinTitle, 0x0005)
;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle := "A")             => _IME_SendMessage(WinTitle, 0x0006, SetSts)
;===========================================================================
; IME 入力モード 取得 / セット
;
;    0000xxxx    かな入力
;    0001xxxx    ローマ字入力
;    xxxx0xxx    半角
;    xxxx1xxx    全角
;    xxxxx000    英数
;    xxxxx001    ひらがな
;    xxxxx011    ｶﾅ/カナ
;
;     0 (0x00  0000 0000) かな    半英数
;     3 (0x03  0000 0011)         半ｶﾅ
;     8 (0x08  0000 1000)         全英数
;     9 (0x09  0000 1001)         ひらがな
;    11 (0x0B  0000 1011)         全カタカナ
;    16 (0x10  0001 0000) ローマ字半英数
;    19 (0x13  0001 0011)         半ｶﾅ
;    24 (0x18  0001 1000)         全英数
;    25 (0x19  0001 1001)         ひらがな
;    27 (0x1B  0001 1011)         全カタカナ

;  1025 中国語？

;===========================================================================
; IME 入力モード (どの IMEでも共通っぽい)
;   DEC  HEX    BIN
;     0 (0x00  0000 0000) かな    半英数
;     3 (0x03  0000 0011)         半ｶﾅ
;     8 (0x08  0000 1000)         全英数
;     9 (0x09  0000 1001)         ひらがな
;    11 (0x0B  0000 1011)         全カタカナ
;    16 (0x10  0001 0000) ローマ字半英数
;    19 (0x13  0001 0011)         半ｶﾅ
;    24 (0x18  0001 1000)         全英数
;    25 (0x19  0001 1001)         ひらがな
;    27 (0x1B  0001 1011)         全カタカナ

;  ※ 地域と言語のオプション - [詳細] - 詳細設定
;     - 詳細なテキストサービスのサポートをプログラムのすべてに拡張する
;    が ONになってると値が取れない模様 
;    (Google日本語入力βはここをONにしないと駄目なので値が取れないっぽい)

;-------------------------------------------------------
; IME 入力モード取得
;   WinTitle="A"    対象Window
;   戻り値          入力モード
;--------------------------------------------------------
IME_GetConvMode(WinTitle := "A")             => _IME_SendMessage(WinTitle, 0x0001)
;-------------------------------------------------------
; IME 入力モードセット
;   ConvMode        入力モード
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;--------------------------------------------------------
IME_SetConvMode(ConvMode, WinTitle := "A")   => _IME_SendMessage(WinTitle, 0x0002, ConvMode)
;===========================================================================
; IME 変換モード (ATOKはver.16で調査、バージョンで多少違うかも)

;   MS-IME  0:無変換 / 1:人名/地名                    / 8:一般    /16:話し言葉
;   ATOK系  0:固定   / 1:複合語              / 4:自動 / 8:連文節
;   WXG              / 1:複合語  / 2:無変換  / 4:自動 / 8:連文節
;   SKK系            / 1:ノーマル (他のモードは存在しない？)
;   Googleβ                                          / 8:ノーマル
;------------------------------------------------------------------
; IME 変換モード取得
;   WinTitle="A"    対象Window
;   戻り値 MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;          ATOK系  0:固定   1:複合語           4:自動 8:連文節
;          WXG4             1:複合語  2:無変換 4:自動 8:連文節
;------------------------------------------------------------------
IME_GetSentenceMode(WinTitle := "A")         => _IME_SendMessage(WinTitle, 0x0003)

;----------------------------------------------------------------
; IME 変換モードセット
;   SentenceMode
;       MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;       ATOK系  0:固定   1:複合語           4:自動 8:連文節
;       WXG              1:複合語  2:無変換 4:自動 8:連文節
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------------
IME_SetSentenceMode(SentenceMode, WinTitle:="A") => _IME_SendMessage(WinTitle, 0x0004, SentenceMode)


;;; software / AutoHotkey スレッド part8
;;; http://p2.chbox.jp/read.php?url=http%3A//pc12.2ch.net/test/read.cgi/software/1243005818/787

;;; IMEの変換状態を見る
;;; http://sites.google.com/site/agkh6mze/scripts#TOC-IME-

;;; software / AutoHotkey スレッド part9
;;; http://p2.chbox.jp/read.php?url=http%3A//pc12.2ch.net/test/read.cgi/software/1253888736/400


;---------------------------------------------------------------------------
;  IMEの種類を選ぶかもしれない関数
;==========================================================================
;  IME 文字入力の状態を返す
;  (パクリ元 : http://sites.google.com/site/agkh6mze/scripts#TOC-IME- )
;    標準対応IME : ATOK系 / MS-IME2002 2007 / WXG / SKKIME
;    その他のIMEは 入力窓/変換窓を追加指定することで対応可能
;
;       WinTitle="A"   対象Window
;       ConvCls=""     入力窓のクラス名 (正規表現表記)
;       CandCls=""     候補窓のクラス名 (正規表現表記)
;       戻り値      1 : 文字入力中 or 変換中
;                   2 : 変換候補窓が出ている
;                   0 : その他の状態
;
;   ※ MS-Office系で 入力窓のクラス名 を正しく取得するにはIMEのシームレス表示を
;      OFFにする必要がある
;      オプション-編集と日本語入力-編集中の文字列を文書に挿入モードで入力する
;      のチェックを外す
;==========================================================================
IME_GetConverting(WinTitle := "A", ConvCls := "", CandCls := "") {
	; 候補数が取れる＝変換候補窓
	if IME_HasCandidateList(WinTitle)
	    return 2
    ; 1. 正規表現文字列を static で定義（関数呼び出し毎の文字列結合を回避し高速化）
    static DefConv := "ATOK\d+CompStr|imejpstcnv\d+|WXGIMEConv|SKKIME\d+\.*\d+UCompStr|MSCTFIME Composition"
    static DefCand := "ATOK\d+Cand|imejpstCandList\d+|imejpstcand\d+|mscandui\d+\.candidate|WXGIMECand|SKKIME\d+\.*\d+UCand"
    static GoogleCand := "GoogleJapaneseInputCandidateWindow"

    ; 引数で追加指定されたクラスがあれば結合
    RegConv := ConvCls ? ConvCls "|" DefConv : DefConv
    RegCand := CandCls ? CandCls "|" DefCand : DefCand

    hwnd := _IME_GetFocusHwnd(WinTitle)
    if !hwnd
        return 0

    pid := WinGetPID("ahk_id " hwnd)
    ret := 0

    ; 環境の退避
    oldTitleMode := A_TitleMatchMode
    try {
        SetTitleMatchMode("RegEx")
        
        ; 予測窓・変換窓の存在判定のみを行う（色判定は破棄）
        if WinExist("ahk_class " RegCand " ahk_pid " pid) || WinExist("ahk_class " GoogleCand) {
            ret := 2
        } else if WinExist("ahk_class " RegConv " ahk_pid " pid) {
            ret := 1
        }
    } finally {
        SetTitleMatchMode(oldTitleMode)
    }
    return ret
}
;-----------------------------------------------------------
;候補リスト件数をみる
;-----------------------------------------------------------
IME_HasCandidateList(WinTitle := "A") {
	; 共通関数を使って1行でHWNDを取得
    hwnd := _IME_GetFocusHwnd(WinTitle)
    if !hwnd
        return false

    himc := DllCall("imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
    if !himc
        return false

    count := 0
    ok := DllCall("imm32\ImmGetCandidateListCountW", "Ptr", himc, "UInt*", &count, "UInt")
    DllCall("imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", himc)

    return (ok != 0 && count > 0)
}
;-----------------------------------------------------------
; 使用中のキーボード配列の取得
;-----------------------------------------------------------
Get_Keyboard_Layout(WinTitle:="A")  {
    hwnd := _IME_GetFocusHwnd(WinTitle)
    if !hwnd
    	return 0
    	
    ThreadID := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", 0, "UInt")
    return DllCall("GetKeyboardLayout", "UInt", ThreadID, "Ptr")
}

Get_language_id(hKL) {
    return Mod(hKL, 0x10000)
}


Get_primary_language_identifier(local_identifier){
    return Format("0x{:X}", mod(local_identifier, 0x100))
}

Get_sublanguage_identifier(local_identifier){
    return Format("0x{:X}", Floor(local_identifier / 0x100))
}


Get_language_name() {
    locale_id := Get_language_id(Get_Keyboard_Layout())
    ;; ロケール ID (LCID) の一覧
    ;; http://msdn.microsoft.com/ja-jp/library/ie/cc392381.aspx
    
    ;; Language Identifier Constants and Strings
    ;; http://msdn.microsoft.com/en-us/library/windows/desktop/dd318693(v=vs.85).aspx
    
    ;; [AHK 1.1.02.00 U32] Error: Expression too long
    ;; http://www.autohotkey.com/forum/topic75335.html
    static LangMap := Map(
    	"0x0436", "af",
        "0x041C", "sq",
        "0x3801", "ar-ae",
        "0x3C01", "ar-bh",
        "0x1401", "ar-dz",
        "0x0C01", "ar-eg",
        "0x0801", "ar-iq",
        "0x2C01", "ar-jo",
        "0x3401", "ar-kw",
        "0x3001", "ar-lb",
        "0x1001", "ar-ly",
        "0x1801", "ar-ma",
        "0x2001", "ar-om",
        "0x4001", "ar-qa",
        "0x0401", "ar-sa",
        "0x2801", "ar-sy",
        "0x1C01", "ar-tn",
        "0x2401", "ar-ye",
        "0x042D", "eu",
        "0x0423", "be",
        "0x0402", "bg",
        "0x0403", "ca",
        "0x0804", "zh-cn",
        "0x0C04", "zh-hk",
        "0x1004", "zh-sg",
        "0x0404", "zh-tw",
        "0x041A", "hr",
        "0x0405", "cs",
        "0x0406", "da",
        "0x0413", "nl",
        "0x0813", "nl-be",
        "0x0C09", "en-au",
        "0x2809", "en-bz",
        "0x1009", "en-ca",
        "0x1809", "en-ie",
        "0x2009", "en-jm",
        "0x1409", "en-nz",
        "0x1C09", "en-za",
        "0x2C09", "en-tt",
        "0x0809", "en-gb",
        "0x0409", "en-us",
        "0x0425", "et",
        "0x0429", "fa",
        "0x040B", "fi",
        "0x0438", "fo",
        "0x040C", "fr",
        "0x080C", "fr-be",
        "0x0C0C", "fr-ca",
        "0x140C", "fr-lu",
        "0x100C", "fr-ch",
        "0x043C", "gd",
        "0x0407", "de",
        "0x0C07", "de-at",
        "0x1407", "de-li",
        "0x1007", "de-lu",
        "0x0807", "de-ch",
        "0x0408", "el",
        "0x040D", "he",
        "0x0439", "hi",
        "0x040E", "hu",
        "0x040F", "is",
        "0x0421", "in",
        "0x0410", "it",
        "0x0810", "it-ch",
        "0x0411", "ja",
        "0x0412", "ko",
        "0x0426", "lv",
        "0x0427", "lt",
        "0x042F", "mk",
        "0x043E", "ms",
        "0x043A", "mt",
        "0x0414", "no",
        "0x0415", "pl",
        "0x0816", "pt",
        "0x0416", "pt-br",
        "0x0417", "rm",
        "0x0418", "ro",
        "0x0818", "ro-mo",
        "0x0419", "ru",
        "0x0819", "ru-mo",
        "0x0C1A", "sr",
        "0x0432", "tn",
        "0x0424", "sl",
        "0x041B", "sk",
        "0x042E", "sb",
        "0x040A", "es",
        "0x2C0A", "es-ar",
        "0x400A", "es-bo",
        "0x340A", "es-cl",
        "0x240A", "es-co",
        "0x140A", "es-cr",
        "0x1C0A", "es-do",
        "0x300A", "es-ec",
        "0x100A", "es-gt",
        "0x480A", "es-hn",
        "0x080A", "es-mx",
        "0x4C0A", "es-ni",
        "0x180A", "es-pa",
        "0x280A", "es-pe",
        "0x500A", "es-pr",
        "0x3C0A", "es-py",
        "0x440A", "es-sv",
        "0x380A", "es-uy",
        "0x200A", "es-ve",
        "0x0430", "sx",
        "0x041D", "sv",
        "0x081D", "sv-fi",
        "0x041E", "th",
        "0x041F", "tr",
        "0x0431", "ts",
        "0x0422", "uk",
        "0x0420", "ur",
        "0x042A", "vi",
        "0x0434", "xh",
        "0x043D", "ji",
        "0x0435", "zu",
        "0xF3FC", "zh-yue" ; http://cpime.hk/ 広東語ピンインIME
    )
    locale_id := Format("0x{:04X}", Get_language_id(Get_Keyboard_Layout()))
    return LangMap.Has(locale_id) ? LangMap[locale_id] : "unknown"
}

Get_ime_file()  => RegRead("HKEY_LOCAL_MACHINE\" . Get_reg_Keyboard_Layouts(), "Ime File")

Get_Layout_Text() => RegRead("HKEY_LOCAL_MACHINE\" . Get_reg_Keyboard_Layouts(), "Layout Text")

Get_reg_Keyboard_Layouts() {
    klid := Format("{:08X}", Get_Keyboard_Layout() & 0xFFFFFFFF)
    return "SYSTEM\CurrentControlSet\Control\Keyboard Layouts\" . klid
}
