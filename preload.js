// 预加载脚本：以最小权限向页面暴露应用信息（当前页面不需要，留作扩展）
const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('xuechengDesktop', {
  isDesktop: true,
  platform: process.platform,
  version: '1.0.0'
});
