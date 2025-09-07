# WOLF RPGエディター 自動ダウンロード＆セットアップスクリプト

このリポジトリは、WOLF RPGエディターの最新版を自動でダウンロード・展開し、初期設定ファイル（Editor.ini）を自動生成するPowerShellスクリプトを提供します。

## 特徴

- 公式サイトから最新バージョンのフルパッケージまたはプログラムのみを自動取得
- zipファイルの展開（7z.exeがあれば日本語ファイル名も安全）
- Editor.iniの自動生成
- .gitignoreの自動コピーとgitリポジトリ初期化
- 設定ファイル（settings.psd1）でURLやディレクトリ名を柔軟に変更可能

## 使い方

1. 必要ファイルを配置
  - `create.ps1`
  - `settings.psd1`
  - `.gitignore`
2. PowerShellを開き、スクリプトのあるディレクトリに移動
3. 実行：
  ```powershell
  .\create.ps1
  ```
1. 画面の指示に従い、ダウンロード種別や保存ファイル名を選択

## 設定ファイル（settings.psd1）例

```powershell
@{
	URL      = 'https://silversecond.com/WolfRPGEditor/Download.shtml'
	DIRNAME  = 'WOLF_RPG_Editor3'
}
```

## 注意事項

- 7z.exe（7-Zip）がインストールされていれば日本語ファイル名の文字化けを防げます。
- スクリプトはコマンドラインから実行してください（ダブルクリック実行は推奨しません）。
- .gitignoreがスクリプトと同じ場所に無い場合、コピーとgit initはスキップされます。
