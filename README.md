# kumogata-template

    git clone https://github.com/labocho/kumogata-template.git REPOSITORY_NAME
    cd REPOSITORY_NAME
    direnv allow
    git remote remove origin
    bundle install

# 概要

## スタック定義ファイル

`stacks/[STACK_NAME].yml` を作成することでスタックを定義します。
内容は下記のとおりです。

```yaml
name: test # スタック名
profile: socioart # AWS Profile
region: ap-northeast-1 # AWS のリージョン
variables: {} # リソース記述ファイルで参照できる変数 (ネスト可)
states: # state 定義
  A: {} # state が A の時の変数 (variables と deep_merge します)
  B: {} # state が B の時の変数 (variables と deep_merge します)
```

下記の rake タスクが定義されます

```
rake [STACK_NAME]:create # 現在の state で stack を作成
rake [STACK_NAME]:update # 現在の state で stack を更新 (確認あり)
rake [STACK_NAME]:show # 現在の state で template を表示
rake [STACK_NAME]:state:[STATE_NAME] # state を変更
```

## resources

`resources/**/*.yml` をすべてロードして、CloudFormation テンプレートの Resources に merge します。

## state

スタック定義ファイルで複数の state を定義できます。
state によって variables を定義・上書きできます。
典型的には正常系と待機系の切り替えなどに使用します。

## !Var

リソース定義ファイルで `!Var foo.bar` などと書く事で、スタック定義ファイルの `variables.foo.bar` の値が参照できます。
現在の state に同じ変数が定義されている場合は、そちらが優先されます。
