IME制御用 関数群 (IMEv2.ahk)  
AutoHotkey v2.0 上で日本語入力の制御を可能にするための関数群、IMM32 API使用  

内容
説明書　README.txt  
ソース　IMEv2.ahk  
テストコード　testIMEv2.ahk  
使用方法  
　・#Includeで組み込む  
　・Libフォルダにコピーして関数ライブラリスクリプトとして  
　・必要部分だけコピペで切り出す、等  
関数一覧  
IME_GET( )	IMEのON/OFF 状態の取得  
IME_SET( )	IMEのON/OFF 状態の制御  
IME_GetConvMode( )	IME 入力モードの取得 (あアｱＡA)  
IME_SetConvMode( )	IME 入力モードの制御  
IME_GetSentenceMode( )	IME 変換モードの取得(人名/一般/話し言葉など)  
IME_SetSentenceMode( )	IME 変換モードの制御  
IME_GetConverting( )	IME 文字入力の状態を返す(入力・変換中/変換候補ウィンドウ表示中 など)  
