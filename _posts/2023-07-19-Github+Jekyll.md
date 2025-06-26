---
title: 杂记 —— Github + Jekyll
authors: fanventory
date: 2023-07-19 15:34:00 +0800
categories: [other]
tags: [jekyll]
---

# jekyll
> 如何使用jekyll和GitHub搭建一个免费博客。

<br>
<br>

## 创建github账号和仓库

1. 创建github账号

2. 建立一个仓库，仓库名是访问地址，一般格式为: XXX.github.io

## 安装ruby环境

1. 下载ruby+Devkit (www.ruby-lang.org)
2. 安装 Ruby+Devkit 3.2.2-1(x86).exe

## 安装RubyGems

1. 下载RubyGems ([www.ruby-lang.org](https://rubygems.org/pages/download))
2. 解压
3. 运行命令

```shell
# 进入你解压的文件夹
cd D:\rubyGems\rubygems-3.4.17
ruby setup.rb
gem install jekyll
```

## 创建博客

1. 创建博客模板

```shell
cd XXX # 进入你放置博客文件的位置
jekyll new testblog
cd testblog
jekyll server # 测试博客是否能创建
```

2. 选择主题

默认创建的博客模板比较简单，可以挑选一个自己喜欢的博客模板。主题官网：http://jekyllthemes.org/

3. 下载主题源码
4. 解压下载的文件，该目录就是一个博客模板(之前创建的博客模板不要了)
5. 运行模板  

```shell
jekyll build --incremental
# 启动
jekyll serve
# jekyll serve -H 0.0.0.0 -P 18888 --detach --incremental
# 关闭
pkill -f jekyll
```

执行的时候可能会报错，比如：  

```shell
[!] There was an error parsing `Gemfile`:
[!] There was an error while loading `jekyll-theme-chirpy.gemspec`: No such file or directory - git ls-files -z. Bundler cannot continue.

 #  from E:/笔记/myblog/jekyll-theme-chirpy.gemspec:13
 #  -------------------------------------------
 #
 >  end
 #  # frozen_string_literal: true
 #  -------------------------------------------
. Bundler cannot continue.

 #  from E:/笔记/myblog/Gemfile:5
 #  -------------------------------------------
 #  # Jekyll <= 4.2.0 compatibility with Ruby 3.0
 >  gem "webrick", "~> 1.7"
 #  # frozen_string_literal: true
 #  -------------------------------------------
```

因为windows上不支持git命令，所以报错了，建议通过git bash来执行这些命令。

然后打开网址 127.0.0.1:4000 就可以访问博客了

## 上传到github

1. 进入_site目录

该目录保存所有生成的网站，所以只需要把_site目录上的所有文件上传到github就可以了。

2. 删除模板的git信息

```shell
rm -rf .git
```

3. 初始化本地git仓库

```shell
git init
```

4. 添加git仓库的远程信息

```shell
git remote add origin https://xxxx.git
```

5. 将当前目录文件添加到git本地仓库

```shell
git add .
```

6. 将当前目录文件提交到本git地仓库

```shell
git commit -m "first commit"
```

7. 推送到远程仓库

```shell
git push -u origin "master"
```

如果出现“fatal: Could not read from remote repository.”的错误，参考以下解决方法：

[Git问题 “fatal: Could not read from remote repository.”](https://blog.csdn.net/m0_51495585/article/details/127105565)

## 创建github pages

1. 打开github仓库地址
2. 选择setting选项卡->pages
3. 找到Branch，选择master，然后点save
4. 可以在actions选项卡查看页面构建进度。
5. 构建完成就可以通过 https://username.github.io 访问了

## Jekyll 目录结构

```
_posts 博客内容
_pages 其他需要生成的网页，如About页
_layouts 网页排版模板
_includes 被模板包含的HTML片段，可在_config.yml中修改位置
assets 辅助资源 css布局 js脚本 图片等
_data 动态数据
_sites 最终生成的静态网页
_config.yml 网站的一些配置信息
index.html 网站的入口
```

# Reference
[1] [Github+Jekyll 搭建个人网站详细教程](https://www.jianshu.com/p/9f71e260925d)  
[2] [【Git】本地项目代码上传到git仓库](https://blog.csdn.net/z_xiao_qiang/article/details/131214353)  
[3] [Git问题 “fatal: Could not read from remote repository.”](https://blog.csdn.net/m0_51495585/article/details/127105565)