import sys
MIN_VERSION = "3.8"
sys.exit(int(tuple(map(int, MIN_VERSION.split("."))) > sys.version_info[:3]))
