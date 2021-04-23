
# 检测Mach-O私有api和权限
使用范围：
1. macho的可执行文件
2. 项目的.app包

如果只有项目的.ipa包，以58tongcheng.ipa为例，请安以下步骤：

1. 先把58tongcheng.ipa后缀改成.zip变成58tongchen.zip
2. 然后在解压，就变成了 58tongcheng （有后缀的话是58tongcheng.app）
3. 此时可以运行项目，【check】选择 58tongcheng 或者 58tongcheng.app

注意：名字58tongcheng.app可以，58tongcheng1.app就不行了。
因为需要拿到58tongcheng这个名字去里面解析东西，所以58tongcheng只能是项目名字，不能带其他的符号，如果有其他符号，请改成项目名字

## 使用

### 按钮【add】

【add】按钮：是在Macho中检测添加的自定义api或者是string，如果有多个以","隔开，然后点击【add】，可以在下面的tableView的最后面看到添加的api，

### 按钮【check】

【check】按钮：可以选择只有macho的可执行文件，也可以选择 xxx.app包，他们都能检测私有api；不同的是前者不能检测项目中的权限

### 按钮【output】
【output】按钮：将结果生成txt文件以便查看，每次点击【output】需要删除上次打开的txt，不然显示还是上次的

## 说明

### 关于权限
如果出现红色：那么需要检测该权限是否在info.plist中申请（定位和健康相关的，不一定准确）

如果出现黑色：代表项目info.plist中申请的权限


### 关于私有api

如果出现红色：代表该api在以前的审核被拒的邮件中被提及，需要格外注意

如果出现黄色：代表该api或者string有一定风险（风险不大）

如果出现黑色：目前问题不大
