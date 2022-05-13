# xdired
pseudo directory editor for [xyzzy text editor](https://ja.wikipedia.org/wiki/Xyzzy).

# 使い方
require して`xdired`関数を呼び出します。操作方法は凡そ[dired](https://en.wikipedia.org/wiki/Dired)のようなものですが、一部筆者の設定を追加しています。
昔のファイラのようにコマンドを登録して使うには`*xdired-send-to-list*`変数に`'("呼出名称" "コマンドライン")`を追加してください。diredのコマンド実行と同様、`?`を選択項目に置換して実行します。`xdired-read-send-to-folder`関数でユーザの送るフォルダの内容から起こすことができます。

書庫用の[xtared](https://github.com/EXCWSM/xtared)と組み合わせて使うことができます。

## 設定例

    (require "xdired")
    (global-set-key '(#\C-x #\d) 'xdired)
    (setq *xdired-send-to-list*
          (append '(("notepad" "notepad.exe ?")
                    ("recycle" "explorer.exe ::{645FF040-5081-101B-9F08-00AA002F954E} ,"))
                   (xdired::xdired-read-send-to-folder)
                   ))

## 既定の操作

| キー | 内容 |
| ---- | ---- |
| B    | バイトコンパイル |
| c    | 圧縮 |
| C    | 複写 |
| d    | 削除フラグ |
| D    | カーソル行の項目を削除 |
| e    | 訪問 |
| f    | 訪問 |
| g    | 再読み込み |
| l    | 再読み込み |
| m    | マーク |
| M    | 属性変更 |
| S    | ショートカット作成 |
| o    | 他のウィンドウで訪問 |
| q    | バッファを閉じる |
| R    | 名前の変更 |
| s    | ソート変更 |
| t    | マークの反転 |
| T    | touch |
| u    | マーク解除 |
| U    | すべてのマークを解除 |
| v    | 読み取り専用で訪問 |
| x    | 削除実行 |
| X    | コマンド実行 |
| Z    | 圧縮 |
| !    | コマンド実行 |
| ^    | 上のディレクトリを訪問 |
| +    | ディレクトリ作成 |
| =    | diff |
| ESC = | マーク済項目の数と合計ファイルサイズ |
| \    | ルートディレクトリを訪問 |
| ｜   | コマンド実行 |
| * .  | 拡張子指定でマーク |
| * /  | ディレクトリをマーク |
| * *  | 実行ファイルをマーク |
| * c  | マークを変更 |
| % m  | 正規表現でマーク |
| C-c C-h | 上のディレクトリを訪問 |
| C-c C-c | 標準の関連付けで実行 |
| C-c C-e | 標準の関連付け(通常はExplorer)で現在のディレクトリを開く |
| C-c C-x | 登録コマンドを実行 |
| C-c z   | 解凍 |
| M-g g | xyzzy標準のgrepダイアログを開く |
| M-g M-g | xyzzy標準のgrepダイアログを開く |
| C-h | マークを解除してカーソルを上へ |
| ESC C-h | すべてのマークを解除 |
