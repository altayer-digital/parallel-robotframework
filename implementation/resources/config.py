# This is the main configuration file which carries all the configs for the test suite.

# Machine Configurations

CONFIG_SELECTOR = "main_config"
BROWSER = "chrome"
PLATFORM = "MAC"
DEFAULT_MAC_VERSION = "Sierra"
RESOLUTION = "1280x1024"
BROWSER_VERSION = "61"
BROWSER_DEBUG = "true"
BROWSER_NETWORK = "true"

# Session Configurations

REMOTE_DESIRED = "False"
SELENIUM_TIMEOUT = "10 seconds"
IS_IE = "False"
REMOTE_SESSION = "get session id"

# Website Details

LANGUAGE = ""
WEBSITE = "job"
WEBSITE_URL = "https://www.google.com"

# Browserstack Support

BSUser = "USERNAME"
AccessKey = "KEY"
REMOTE_URL = "http://BSUser:AccessKey@hub.browserstack.com:80/wd/hub"

# Test Initialisation

TEST_NAME = "NONE"
SUITE_NAME = "NONE"
TMP_PATH = "/tmp"

# Timeouts

TIME_OUT = "single"

t_xmin = "4s"
t_min = "10s"
t_mid = "20s"
t_max = "30s"
t_xmax = "60s"