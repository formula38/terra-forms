import os

VERBOSE = os.getenv("DEBUG_VERBOSE", "true").lower() == "true"

def log_info(message: str):
    if VERBOSE:
        print(f"[INFO] {message}")

def log_warn(message: str):
    print(f"[WARN] {message}")

def log_error(message: str):
    print(f"[ERROR] {message}")

def log_success(message: str):
    print(f"[✓] {message}")

def log_title(title: str):
    print(f"\n=== {title.upper()} ===")
