#!/usr/bin/env python3

import sys
import os
import time
import signal
from PyQt5.QtWidgets import QApplication, QSystemTrayIcon, QMenu, QAction
from PyQt5.QtGui import QIcon
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtCore import QTimer, QThread, pyqtSignal, QObject, pyqtProperty, Qt
from ewmh import EWMH
import Xlib
import Xlib.display

disp = Xlib.display.Display()
Xroot = disp.screen().root
NET_ACTIVE_WINDOW = disp.intern_atom('_NET_ACTIVE_WINDOW')


def setup_interrupt_handling():
    # Make sure Ctrl-C quits
    # https://coldfix.de/2016/11/08/pyqt-boilerplate/
    # This is bullshit that I have to do this, to be clear, Qt people.
    # You are horrible and you should feel guilty every day.
    # Doing this also stops Qt swallowing redirected stdout.
    signal.signal(signal.SIGINT, _interrupt_handler)
    safe_timer(50, lambda: None)


def _interrupt_handler(signum, frame):
    QApplication.quit()


def safe_timer(timeout, func, *args, **kwargs):
    def timer_event():
        try:
            func(*args, **kwargs)
        finally:
            QTimer.singleShot(timeout, timer_event)
    QTimer.singleShot(timeout, timer_event)


class ActiveWindowMonitor(QThread):
    output = pyqtSignal(int, int, int, int, int)

    def __init__(self, parent=None):
        QThread.__init__(self, parent)
        self.exiting = False
        self.ewmh = EWMH()
        self.active_window_id_tree = []

    def run(self):
        Xroot.change_attributes(event_mask=Xlib.X.PropertyChangeMask |
                                Xlib.X.SubstructureNotifyMask)
        self.notify_about_active_window()
        while True:
            event = disp.next_event()
            if (event.type == Xlib.X.PropertyNotify and
                    event.atom == NET_ACTIVE_WINDOW):
                self.notify_about_active_window()
            elif event.type == Xlib.X.ConfigureNotify:
                if event.window.id in self.active_window_id_tree:
                    self.notify_about_active_window()

    def notify_about_active_window(self):
        # the active window has changed; get it and emit its details
        cur = self.ewmh.getActiveWindow()
        # and store its window tree so we can trap ConfigureNotify events
        # on our window, which might actually be a bunch of X windows
        # created invisibly by the window manager as a frame
        pointer = cur
        self.active_window_id_tree = []
        while pointer.id != Xroot.id:
            self.active_window_id_tree.append(pointer.id)
            pointer = pointer.query_tree().parent

        # dsk = self.ewmh.getCurrentDesktop()
        # wdsk = self.ewmh.getWmDesktop(cur)
        geo = cur.get_geometry()
        (x, y) = (geo.x, geo.y)
        frame = cur
        while True:
            parent = frame.query_tree().parent
            pgeom = parent.get_geometry()
            x += pgeom.x
            y += pgeom.y
            if parent.id == self.ewmh.root.id:
                break
            frame = parent
        print("------------- Window", cur.get_wm_class()[1],
              x, y, geo.width, geo.height, "-------------")
        self.output.emit(x, y, geo.width, geo.height, cur.id)

    def __del__(self):
        self.exiting = True
        self.wait()


class ActiveWindowProperties(QObject):
    xChanged = pyqtSignal(int)
    yChanged = pyqtSignal(int)
    wChanged = pyqtSignal(int)
    hChanged = pyqtSignal(int)
    widChanged = pyqtSignal(int)

    def __init__(self, parent=None):
        super(ActiveWindowProperties, self).__init__(parent)
        self._w = 0
        self._h = 0
        self._x = 0
        self._y = 0
        self._wid = 0

    @pyqtProperty(int, notify=hChanged)
    def h(self):
        return self._h

    @h.setter
    def h(self, h):
        if self._h != h:
            self._h = h
            self.hChanged.emit(h)

    @pyqtProperty(int, notify=wChanged)
    def w(self):
        return self._w

    @w.setter
    def w(self, w):
        if self._w != w:
            self._w = w
            self.wChanged.emit(w)

    @pyqtProperty(int, notify=xChanged)
    def x(self):
        return self._x

    @x.setter
    def x(self, x):
        if self._x != x:
            self._x = x
            self.xChanged.emit(x)

    @pyqtProperty(int, notify=yChanged)
    def y(self):
        return self._y

    @y.setter
    def y(self, y):
        if self._y != y:
            self._y = y
            self.yChanged.emit(y)

    @pyqtProperty(int, notify=widChanged)
    def wid(self):
        return self._wid

    @wid.setter
    def wid(self, wid):
        if self._wid != wid:
            self._wid = wid
            self.widChanged.emit(wid)


def create_thread_results_handler(act, win):
    def actual_thread_results_handler(x, y, w, h, wid):
        act.x = x
        act.y = y
        act.w = w
        act.h = h
        act.wid = wid
    return actual_thread_results_handler


def tray_icon(app):
    icon = QIcon("icon.png")
    tray = QSystemTrayIcon()
    tray.setIcon(icon)
    tray.setVisible(True)
    menu = QMenu()
    action = QAction("Quit")
    action.triggered.connect(app.quit)
    menu.addAction(action)
    tray.setContextMenu(menu)


def main():
    print("Cute Ninja startup", time.asctime())

    app = QApplication(sys.argv)
    setup_interrupt_handling()
    tray_icon(app)
    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    act = ActiveWindowProperties()
    context.setContextProperty("active_xwindow", act)
    engine.load(os.path.join(os.path.split(__file__)[0], 'cuteninja.qml'))
    win = engine.rootObjects()[0]
    win.showNormal()

    bgthread = ActiveWindowMonitor()
    bgthread.start()
    bgthread.output.connect(create_thread_results_handler(act, win))

    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
