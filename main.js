const { app, BrowserWindow, Menu, dialog } = require('electron');
const path = require('path');

const APP_URL = 'https://www.ixuecheng.cn/';
const APP_NAME = '学丞桌面版';
const APP_VERSION = '1.0.0';

// 单实例：重复启动时聚焦已有窗口
const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
} else {
  let mainWindow = null;

  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  function createWindow() {
    mainWindow = new BrowserWindow({
      width: 1280,
      height: 820,
      minWidth: 980,
      minHeight: 660,
      title: APP_NAME,
      icon: path.join(__dirname, 'icon.ico'),
      backgroundColor: '#f5f7fb',
      show: false,
      webPreferences: {
        preload: path.join(__dirname, 'preload.js'),
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: true,
        spellcheck: false
      }
    });

    mainWindow.once('ready-to-show', () => mainWindow.show());

    mainWindow.loadURL(APP_URL);

    // 页面内 target=_blank 等新窗口请求：都在本窗口内打开，避免弹出空浏览器窗口
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        mainWindow.loadURL(url);
      }
      return { action: 'deny' };
    });

    // 只放行 http/https 跳转，其他协议一律拦截
    mainWindow.webContents.on('will-navigate', (event, url) => {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        event.preventDefault();
      }
    });

    // 下载（讲义、课程资料等）默认保存到系统“下载”文件夹
    mainWindow.webContents.session.on('will-download', (event, item) => {
      item.setSaveDialogOptions({
        title: '保存文件',
        defaultPath: path.join(app.getPath('downloads'), item.getFilename())
      });
    });

    // 窗口标题跟随页面标题
    mainWindow.on('page-title-updated', (event, title) => {
      event.preventDefault();
      mainWindow.setTitle(title && title.trim() ? title : APP_NAME);
    });

    mainWindow.on('closed', () => {
      mainWindow = null;
    });
  }

  app.whenReady().then(() => {
    app.setAppUserModelId('cn.xuecheng.desktop');
    createWindow();
    Menu.setApplicationMenu(buildMenu());

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
  });

  app.on('window-all-closed', () => {
    app.quit();
  });
}

function buildMenu() {
  const isMac = process.platform === 'darwin';
  const template = [
    ...(isMac ? [{ role: 'appMenu' }] : []),
    {
      label: '文件',
      submenu: [isMac ? { role: 'close' } : { role: 'quit', label: '退出' }]
    },
    {
      label: '编辑',
      submenu: [
        { role: 'undo', label: '撤销' },
        { role: 'redo', label: '重做' },
        { type: 'separator' },
        { role: 'cut', label: '剪切' },
        { role: 'copy', label: '复制' },
        { role: 'paste', label: '粘贴' },
        { role: 'selectAll', label: '全选' }
      ]
    },
    {
      label: '导航',
      submenu: [
        {
          label: '后退',
          accelerator: 'Alt+Left',
          click: () => mainWindow && mainWindow.webContents.goBack()
        },
        {
          label: '前进',
          accelerator: 'Alt+Right',
          click: () => mainWindow && mainWindow.webContents.goForward()
        },
        {
          label: '刷新',
          accelerator: 'CmdOrCtrl+R',
          click: () => mainWindow && mainWindow.webContents.reload()
        },
        {
          label: '主页',
          accelerator: 'CmdOrCtrl+Home',
          click: () => mainWindow && mainWindow.loadURL(APP_URL)
        }
      ]
    },
    {
      label: '视图',
      submenu: [
        { role: 'resetZoom', label: '实际大小', accelerator: 'CmdOrCtrl+0' },
        { role: 'zoomIn', label: '放大', accelerator: 'CmdOrCtrl+=' },
        { role: 'zoomOut', label: '缩小', accelerator: 'CmdOrCtrl+-' },
        { type: 'separator' },
        { role: 'togglefullscreen', label: '全屏' },
        { type: 'separator' },
        { role: 'toggleDevTools', label: '开发者工具' }
      ]
    },
    {
      label: '帮助',
      submenu: [
        {
          label: '关于学丞桌面版',
          click: () => {
            dialog.showMessageBox({
              type: 'info',
              title: '关于',
              message: APP_NAME,
              detail:
                `版本 ${APP_VERSION}\n\n非官方客户端：仅将学丞教育官网网页版（ixuecheng.cn）封装为桌面应用。\n课程、账号、内容版权均归济南学丞教育科技有限公司所有。`
            });
          }
        }
      ]
    }
  ];
  return Menu.buildFromTemplate(template);
}
