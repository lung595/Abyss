#!/usr/bin/env python3
# Runs a QML integration test outside of Quickshell. Needs PySide6
# (pip install PySide6-Essentials).
#
#   tests/qml/qmltest.py tests/qml/NetbirdSource.test.qml
#
# DMS and Quickshell singletons are small recording stand-ins (imports/).
# Quickshell.Io's Process, StdioCollector and SplitParser are played by
# QProcess, with
# the same properties and signals Abyss uses; `exited` comes before the
# streams end (the order CliRunner must cope with). The PATH starts with
# a temporary directory where `netbird` is tests/qml/fake-netbird. The test is the
# root object: it calls Qt.exit(failures) when done.
import os, shutil, sys, tempfile

from PySide6.QtCore import QObject, QProcess, QProcessEnvironment, Property, Signal, QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

HERE = os.path.dirname(os.path.abspath(__file__))


class StdioCollector(QObject):
    textChanged = Signal()
    streamFinished = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._text = ""

    def _get(self):
        return self._text

    text = Property(str, _get, notify=textChanged)


class SplitParser(QObject):
    # Lines are handed over once the process ends (enough for the tests:
    # a long-running reader such as `ip monitor` just never reads)
    read = Signal(str)


class IpcHandler(QObject):
    targetChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._target = ""

    def _get(self):
        return self._target

    def _set(self, v):
        self._target = v
        self.targetChanged.emit()

    target = Property(str, _get, _set, notify=targetChanged)


class Process(QObject):
    commandChanged = Signal()
    runningChanged = Signal()
    started = Signal()
    exited = Signal(int, int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._command = []
        self._env = {}
        self._out = None
        self._err = None
        self._p = None

    def _getCommand(self):
        return self._command

    def _setCommand(self, v):
        self._command = list(v)
        self.commandChanged.emit()

    command = Property("QVariantList", _getCommand, _setCommand, notify=commandChanged)

    # Variables added for this process only, over the inherited ones
    def _getEnv(self):
        return self._env

    def _setEnv(self, v):
        self._env = dict(v or {})

    environment = Property("QVariantMap", _getEnv, _setEnv)

    def _getOut(self):
        return self._out

    def _setOut(self, v):
        self._out = v

    stdout = Property(QObject, _getOut, _setOut)

    def _getErr(self):
        return self._err

    def _setErr(self, v):
        self._err = v

    stderr = Property(QObject, _getErr, _setErr)

    def _getRunning(self):
        return self._p is not None

    def _setRunning(self, on):
        if on and self._p is None and self._command:
            p = QProcess(self)
            self._p = p
            p.finished.connect(self._done)
            p.errorOccurred.connect(self._error)
            env = QProcessEnvironment.systemEnvironment()
            for k, v in self._env.items():
                env.insert(k, str(v))
            p.setProcessEnvironment(env)
            # A test makes a program "missing" (even if the system has it) by
            # creating $FAKE_NB/missing.<name>
            gone = os.path.exists(os.path.join(os.environ["FAKE_NB"], "missing." + os.path.basename(self._command[0])))
            prog = None if gone else shutil.which(self._command[0])
            if not prog:
                # Like a missing program: no exit, nothing on the streams
                QTimer.singleShot(0, lambda: self._error(QProcess.ProcessError.FailedToStart))
            else:
                p.start(prog, [str(a) for a in self._command[1:]])
            self.runningChanged.emit()
        elif not on and self._p is not None:
            self._p.kill()

    running = Property(bool, _getRunning, _setRunning, notify=runningChanged)

    def _error(self, err):
        if err == QProcess.ProcessError.FailedToStart and self._p is not None:
            self._p = None
            self.runningChanged.emit()

    def _done(self, code, status):
        p = self._p
        self._p = None
        out = bytes(p.readAllStandardOutput()).decode()
        err = bytes(p.readAllStandardError()).decode()
        self.runningChanged.emit()
        self.exited.emit(code, 0)
        for c, t in ((self._out, out), (self._err, err)):
            if isinstance(c, SplitParser):
                for line in t.splitlines():
                    c.read.emit(line)
            elif c is not None:
                c._text = t
                c.textChanged.emit()
                c.streamFinished.emit()


def main():
    test = os.path.abspath(sys.argv[1])
    os.environ["FAKE_NB"] = tempfile.mkdtemp(prefix="abyss-nb-")
    bin_dir = os.path.join(os.environ["FAKE_NB"], "bin")
    os.mkdir(bin_dir)
    os.symlink(os.path.join(HERE, "fake-netbird"), os.path.join(bin_dir, "netbird"))
    # scp is a fake too: it records its arguments and fails on demand
    os.symlink(os.path.join(HERE, "fake-scp"), os.path.join(bin_dir, "scp"))
    # The clipboard reader and the file picker are fakes too (see their files)
    os.symlink(os.path.join(HERE, "fake-wl-paste"), os.path.join(bin_dir, "wl-paste"))
    os.symlink(os.path.join(HERE, "fake-zenity"), os.path.join(bin_dir, "zenity"))
    # A terminal for SSH: Abyss looks one up before opening it
    os.symlink(shutil.which("true"), os.path.join(bin_dir, "kitty"))
    # ping answers nothing (exit 0, no output): "no answer"
    os.symlink(shutil.which("true"), os.path.join(bin_dir, "ping"))
    os.environ["QML_XHR_ALLOW_FILE_READ"] = "1"
    os.environ["PATH"] = bin_dir + os.pathsep + os.environ.get("PATH", "")
    qmlRegisterType(Process, "Quickshell.Io", 1, 0, "Process")
    qmlRegisterType(StdioCollector, "Quickshell.Io", 1, 0, "StdioCollector")
    qmlRegisterType(IpcHandler, "Quickshell.Io", 1, 0, "IpcHandler")
    qmlRegisterType(SplitParser, "Quickshell.Io", 1, 0, "SplitParser")
    app = QGuiApplication([sys.argv[0]])
    eng = QQmlApplicationEngine()
    eng.addImportPath(os.path.join(HERE, "imports"))
    eng.rootContext().setContextProperty("fakeDir", os.environ["FAKE_NB"])
    eng.load(QUrl.fromLocalFile(test))
    if not eng.rootObjects():
        return 2
    QTimer.singleShot(120000, lambda: (print("TIMEOUT"), app.exit(3)))
    return app.exec()


sys.exit(main())
