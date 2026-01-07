import ctypes
import ctypes.util
from typing import Callable

import Quartz


HOTKEY_CALLBACK: Callable[[], None] | None = None

_app_services = ctypes.cdll.LoadLibrary(
    "/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices"
)
_app_services.AXIsProcessTrusted.restype = ctypes.c_bool

# Cmd+Option+V keycodes
KEYCODE_V = 9
MODIFIER_CMD = Quartz.kCGEventFlagMaskCommand
MODIFIER_ALT = Quartz.kCGEventFlagMaskAlternate
REQUIRED_MODIFIERS = MODIFIER_CMD | MODIFIER_ALT


def _event_callback(proxy, event_type, event, refcon):  # noqa: ARG001
    if event_type == Quartz.kCGEventKeyDown:
        keycode = Quartz.CGEventGetIntegerValueField(
            event, Quartz.kCGKeyboardEventKeycode
        )
        flags = Quartz.CGEventGetFlags(event)
        cmd_shift = (flags & REQUIRED_MODIFIERS) == REQUIRED_MODIFIERS
        if keycode == KEYCODE_V and cmd_shift and HOTKEY_CALLBACK:
            HOTKEY_CALLBACK()
            return None
    return event


def start_listener(callback: Callable[[], None]) -> Quartz.CFMachPortRef | None:
    global HOTKEY_CALLBACK
    HOTKEY_CALLBACK = callback

    mask = (1 << Quartz.kCGEventKeyDown)
    tap = Quartz.CGEventTapCreate(
        Quartz.kCGSessionEventTap,
        Quartz.kCGHeadInsertEventTap,
        Quartz.kCGEventTapOptionDefault,
        mask,
        _event_callback,
        None,
    )

    if tap is None:
        return None

    source = Quartz.CFMachPortCreateRunLoopSource(None, tap, 0)
    Quartz.CFRunLoopAddSource(
        Quartz.CFRunLoopGetCurrent(), source, Quartz.kCFRunLoopCommonModes
    )
    Quartz.CGEventTapEnable(tap, True)
    return tap


def check_accessibility() -> bool:
    return _app_services.AXIsProcessTrusted()
