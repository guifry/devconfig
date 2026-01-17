import subprocess
import time
from pathlib import Path

from pynput import keyboard
from pynput.keyboard import Controller, Key

from reformat import reformat_prompt

kb = Controller()


def get_clipboard() -> str:
    result = subprocess.run(["pbpaste"], capture_output=True, text=True)
    return result.stdout


def set_clipboard(text: str) -> None:
    subprocess.run(["pbcopy"], input=text, text=True)


def simulate_copy() -> None:
    kb.press(Key.cmd)
    kb.press("c")
    kb.release("c")
    kb.release(Key.cmd)


def simulate_paste() -> None:
    kb.press(Key.cmd)
    kb.press("v")
    kb.release("v")
    kb.release(Key.cmd)


def on_activate() -> None:
    simulate_copy()
    time.sleep(0.15)

    original = get_clipboard()
    if not original.strip():
        return

    try:
        reformatted = reformat_prompt(original)
        set_clipboard(reformatted)
        time.sleep(0.05)
        simulate_paste()
    except Exception as e:
        print(f"Error reformatting: {e}")


def main() -> None:
    print("Prompt reformatter running. Hotkey: Cmd+Option+P")
    print("Grant Accessibility access in System Settings if not working.")

    with keyboard.GlobalHotKeys({"<cmd>+<alt>+p": on_activate}) as h:
        h.join()


if __name__ == "__main__":
    main()
