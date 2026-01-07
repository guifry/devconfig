import signal
import sys
import threading
import time

from Cocoa import NSApplication, NSRunLoop, NSDate

from clippy import clipboard, storage, hotkey, picker


POLL_INTERVAL = 0.5
_running = True
_last_content: str | None = None


def _poll_clipboard() -> None:
    global _last_content
    while _running:
        content = clipboard.read()
        if content and content != _last_content:
            storage.add_item(content)
            _last_content = content
        time.sleep(POLL_INTERVAL)


def _on_hotkey() -> None:
    picker.pick_and_paste()


def _signal_handler(sig, frame):  # noqa: ARG001
    global _running
    _running = False
    sys.exit(0)


def run() -> None:
    global _last_content

    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)

    if not hotkey.check_accessibility():
        print(
            "Accessibility permission required. "
            "Go to System Preferences → Privacy → Accessibility",
            file=sys.stderr,
        )

    _last_content = clipboard.read()

    NSApplication.sharedApplication()

    poll_thread = threading.Thread(target=_poll_clipboard, daemon=True)
    poll_thread.start()

    tap = hotkey.start_listener(_on_hotkey)
    if tap is None:
        print("Failed to create event tap. Grant Accessibility permission.", file=sys.stderr)
        sys.exit(1)

    print("Clippy daemon running. Press Cmd+Shift+V for history picker.")

    while _running:
        NSRunLoop.currentRunLoop().runMode_beforeDate_(
            "kCFRunLoopDefaultMode", NSDate.dateWithTimeIntervalSinceNow_(0.5)
        )


if __name__ == "__main__":
    run()
