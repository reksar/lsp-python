import sys
MIN_VERSION = "3.8"
sys.exit(int(sys.version_info[:3] < tuple(map(int, MIN_VERSION.split(".")))))
