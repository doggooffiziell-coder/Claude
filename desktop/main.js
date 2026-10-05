// Ragpit as a desktop app: one window that shows the PC version of the game.
// The game page lives in app/ (built by build.sh from pc/ and web/).
const { app, BrowserWindow, Menu, shell } = require("electron");
const path = require("path");

// Sound and music may start without a click first.
app.commandLine.appendSwitch("autoplay-policy", "no-user-gesture-required");

// Only one Ragpit at a time: a second start brings the open window forward.
if (!app.requestSingleInstanceLock()) app.quit();

let win = null;
function createWindow() {
  win = new BrowserWindow({
    width: 1600,
    height: 900,
    minWidth: 960,
    minHeight: 600,
    fullscreen: true,
    backgroundColor: "#0b0b0e",
    title: "Ragpit",
    icon: path.join(__dirname, "app", "icon.png"),
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, spellcheck: false },
  });
  Menu.setApplicationMenu(null);
  win.loadFile(path.join(__dirname, "app", "Ragpit.html"));
  // F11 switches full screen, Alt+F4 or Cmd+Q closes, Ctrl+R reloads.
  win.webContents.on("before-input-event", (ev, input) => {
    if (input.type !== "keyDown") return;
    if (input.key === "F11") { win.setFullScreen(!win.isFullScreen()); ev.preventDefault(); }
    else if ((input.control || input.meta) && input.key.toLowerCase() === "q") app.quit();
    else if ((input.control || input.meta) && input.key.toLowerCase() === "r") win.reload();
  });
  // Links out of the game open in the normal browser.
  win.webContents.setWindowOpenHandler(({ url }) => { shell.openExternal(url); return { action: "deny" }; });
  win.on("closed", () => { win = null; });
}

app.on("second-instance", () => { if (win) { if (win.isMinimized()) win.restore(); win.focus(); } });
app.whenReady().then(createWindow);
app.on("window-all-closed", () => app.quit());
app.on("activate", () => { if (!win) createWindow(); });
