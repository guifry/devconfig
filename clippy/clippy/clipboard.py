import subprocess


def read() -> str | None:
    try:
        result = subprocess.run(
            ["pbpaste"], capture_output=True, text=True, check=True
        )
        return result.stdout if result.stdout else None
    except subprocess.CalledProcessError:
        return None


def write(content: str) -> bool:
    try:
        subprocess.run(
            ["pbcopy"], input=content, text=True, check=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def simulate_paste() -> bool:
    try:
        subprocess.run(
            [
                "osascript", "-e",
                'tell application "System Events" to keystroke "v" using command down'
            ],
            check=True,
            capture_output=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False
