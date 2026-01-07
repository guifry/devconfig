import objc
from Cocoa import (
    NSApplication,
    NSMenu,
    NSMenuItem,
    NSEvent,
    NSObject,
)

from clippy import clipboard, storage


MAX_DISPLAY_LEN = 60
_selected_content: str | None = None


def _truncate(text: str) -> str:
    text = text.replace("\n", " ").strip()
    if len(text) > MAX_DISPLAY_LEN:
        return text[:MAX_DISPLAY_LEN] + "..."
    return text


class MenuDelegate(NSObject):
    @objc.typedSelector(b"v@:@")
    def menuItemSelected_(self, sender):
        global _selected_content
        _selected_content = sender.representedObject()


def show_picker() -> str | None:
    global _selected_content
    _selected_content = None

    items = storage.get_items(limit=10)
    if not items:
        return None

    NSApplication.sharedApplication()
    menu = NSMenu.alloc().init()
    menu.setAutoenablesItems_(False)

    delegate = MenuDelegate.alloc().init()

    for i, item in enumerate(items):
        title = f"{i + 1}. {_truncate(item['content'])}"
        menu_item = NSMenuItem.alloc().initWithTitle_action_keyEquivalent_(
            title, "menuItemSelected:", ""
        )
        menu_item.setRepresentedObject_(item["content"])
        menu_item.setTarget_(delegate)
        menu_item.setEnabled_(True)
        menu.addItem_(menu_item)

    mouse_loc = NSEvent.mouseLocation()
    menu.popUpMenuPositioningItem_atLocation_inView_(None, mouse_loc, None)

    return _selected_content


def pick_and_paste() -> None:
    content = show_picker()
    if content:
        clipboard.write(content)
        clipboard.simulate_paste()
