# 学丞桌面版（xuecheng-desktop）

把学丞教育官网（www.ixuecheng.cn）网页版封装成 Windows 桌面应用的第三方壳工程。做法和红果短剧桌面版这类 GitHub 项目一致：用 Electron 加载官方网页，套一个原生窗口，比浏览器标签页更接近"App"的体验。

## 功能

- 独立桌面窗口，记住登录状态（Cookie 本地持久化，下次打开免登录）
- 窗口内导航：后退 / 前进 / 刷新 / 主页
- 快捷键：
  - `Alt+←` / `Alt+→`：后退 / 前进
  - `Ctrl+R`：刷新
  - `Ctrl+Home`：回到首页
  - `Ctrl+=` / `Ctrl+-` / `Ctrl+0`：放大 / 缩小 / 实际大小
- 讲义、课程资料下载默认保存到系统"下载"文件夹
- 单实例运行，重复打开会聚焦已有窗口

## 下载安装

到本仓库 [Releases](../../releases) 页面下载 `学丞桌面版-Setup-x.x.x.exe`，双击安装即可。

## 从源码构建

需要 Node.js 18+。

```bash
npm install
npm start        # 开发模式运行
npm run dist     # 打包 Windows 安装包（输出到 dist/ 目录）
```

## 目录结构

```
xuecheng-desktop/
├── main.js               # Electron 主进程：窗口、菜单、导航、下载
├── preload.js            # 预加载脚本
├── icon.ico              # 应用图标
├── scripts/
│   └── make-icon.ps1     # 图标生成脚本（PowerShell，可重复执行）
└── package.json
```

## 说明与免责声明

- 本项目**不是学丞教育官方出品**，只是一个网页套壳，不修改、不破解任何官方功能。
- 课程内容、账号体系、商城及版权均归济南学丞教育科技有限公司（ixuecheng.cn）所有。
- 请使用自己的账号登录，并遵守官方用户协议；本项目按 MIT 协议开源，仅供学习交流。

## License

[MIT](LICENSE)
