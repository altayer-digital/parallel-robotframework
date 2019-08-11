import os
import yaml
import requests
import json
import datetime

__version__ = '1.0.0'


class CustomLib(object):
    ROBOT_LIBRARY_VERSION = __version__
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def create_result_folder(self):
        directory = "/suite/results/"

        if not os.path.exists(directory):
            os.mkdir(directory)

    def generate_website_url(self, language, website):

        dir_path = os.getcwd()
        with open(dir_path + '/suite/execution/config/url_generator.yml') as stream:
            data_loaded = yaml.load(stream, Loader=yaml.FullLoader)

        url = str(data_loaded[website][language])
        return url

    def get_timeout(self, timeout, value):

        dir_path = os.getcwd()
        with open(dir_path + '/suite/execution/config/timeout.yml') as stream:
            data_loaded = yaml.load(stream, Loader=yaml.FullLoader)

        return str(data_loaded[timeout][value])

    def get_browser_stack_build_id(self, user_name, access_key):

        self.write_to_log('-- getting build id --')

        url = "http://" \
              + user_name \
              + ":" \
              + access_key \
              + "@api.browserstack.com/automate/builds/"

        r = requests.get(url)
        loaded_json = json.loads(r.text)

        if loaded_json[0]["automation_build"]["hashed_id"] is not None:
            self.write_to_log('build id ' + loaded_json[0]["automation_build"]["hashed_id"])
            return loaded_json[0]["automation_build"]["hashed_id"]
        else:
            self.write_to_log('Error getting build id '
                              + loaded_json[0]["automation_build"]["hashed_id"])

    def write_to_log(self, log):
        self.create_result_folder()
        now = datetime.datetime.now()
        text_file = open("suite/results/error_logs.txt", "a+")
        text_file.write("%s  --  %s\n" % (str(now), log.encode("utf-8")))
        text_file.close()
