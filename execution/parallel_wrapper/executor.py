#!/usr/bin/env python

#  Copyright 2008-2015 Nokia Networks
#  Copyright 2016-     Robot Framework Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


import os.path
import sys
import shutil
import subprocess
import yaml
import time

from robot.conf import RobotSettings
from robot.htmldata import HtmlFileWriter, ModelWriter, JsonWriter, TESTDOC
from robot.parsing import disable_curdir_processing
from robot.running import TestSuiteBuilder
from robot.utils import (abspath, Application, file_writer, get_link_path,
                         html_escape, html_format, is_string, secs_to_timestr, seq2str2,
                         timestr_to_secs, unescape)


USAGE = """robot.testdoc -- Robot Framework test data documentation tool

Version:  <VERSION>

Usage:  python -m robot.testdoc [options] data_sources output_file

Testdoc generates a high level test documentation based on Robot Framework
test data. Generated documentation includes name, documentation and other
metadata of each test suite and test case, as well as the top-level keywords
and their arguments.

Options
=======

  -T --title title       Set the title of the generated documentation.
                         Underscores in the title are converted to spaces.
                         The default title is the name of the top level suite.
  -N --name name         Override the name of the top level suite.
  -D --doc document      Override the documentation of the top level suite.
  -M --metadata name:value *  Set/override metadata of the top level suite.
  -G --settag tag *      Set given tag(s) to all test cases.
  -t --test name *       Include tests by name.
  -s --suite name *      Include suites by name.
  -i --include tag *     Include tests by tags.
  -e --exclude tag *     Exclude tests by tags.
  -A --argumentfile path *  Text file to read more arguments from. Use special
                          path `STDIN` to read contents from the standard input
                          stream. File can have both options and data sources
                          one per line. Contents do not need to be escaped but
                          spaces in the beginning and end of lines are removed.
                          Empty lines and lines starting with a hash character
                          (#) are ignored. New in Robot Framework 3.0.2.
                          Example file:
                          |  --name Example
                          |  # This is a comment line
                          |  my_tests.robot
                          |  output.html
                          Examples:
                          --argumentfile argfile.txt --argumentfile STDIN
  -h -? --help           Print this help.

All options except --title have exactly same semantics as same options have
when executing test cases.

Execution
=========

Data can be given as a single file, directory, or as multiple files and
directories. In all these cases, the last argument must be the file where
to write the output. The output is always created in HTML format.

Testdoc works with all interpreters supported by Robot Framework (Python,
Jython and IronPython). It can be executed as an installed module like
`python -m robot.testdoc` or as a script like `python path/robot/testdoc.py`.

Examples:

  python -m robot.testdoc my_test.html testdoc.html
  jython -m robot.testdoc -N smoke_tests -i smoke path/to/my_tests smoke.html
  ipy path/to/robot/testdoc.py first_suite.txt second_suite.txt output.html

For more information about Testdoc and other built-in tools, see
http://robotframework.org/robotframework/#built-in-tools.
"""


class TestDoc(Application):

    def __init__(self):
        Application.__init__(self, USAGE, arg_limits=(2,))

    def main(self, datasources, title=None, **options):

        outfile = abspath(datasources.pop())
        suite = TestSuiteFactory(datasources, **options)

        self._write_test_doc(suite, outfile, title)
        self.console(outfile)
        self.wait_for_result()

    def _write_test_doc(self, suite, outfile, title):
        with file_writer(outfile) as output:
            model_writer = TestdocModelWriter(output, suite, title)
            HtmlFileWriter(output, model_writer).write(TESTDOC)

    def wait_for_result(self):
        filename = './parallel_results/log.html'
        while True:
            try:
                with open(filename, 'rb') as _:
                    print("All the tests were finished please check ./parallel_results/ for details.")
                    break
            except IOError:
                time.sleep(3)


@disable_curdir_processing
def TestSuiteFactory(datasources, **options):
    settings = RobotSettings(options)
    if is_string(datasources):
        datasources = [datasources]
    suite = TestSuiteBuilder().build(*datasources)
    suite.configure(**settings.suite_config)
    return suite


class TestdocModelWriter(ModelWriter):

    def __init__(self, output, suite, title=None):
        self._output = output
        self._output_path = getattr(output, 'name', None)
        self._suite = suite
        self._title = title.replace('_', ' ') if title else suite.name

    def write(self, line):
        self._output.write('<script type="text/javascript">\n')
        self.write_data()
        self._output.write('</script>\n')

    def write_data(self):
        model = {
            'suite': JsonConverter(self._output_path).convert(self._suite),
            'title': self._title,
            'generated': int(time.time() * 1000)
        }
        JsonWriter(self._output).write_json('testdoc = ', model)


class JsonConverter(object):

    def __init__(self, output_path=None):
        self._output_path = output_path

    def convert(self, suite):
        return self._convert_suite(suite)

    def _convert_suite(self, suite):
        return {
            'source': suite.source or '',
            'relativeSource': self._get_relative_source(suite.source),
            'id': suite.id,
            'name': self._escape(suite.name),
            'fullName': self._escape(suite.longname),
            'doc': self._html(suite.doc),
            'metadata': [(self._escape(name), self._html(value))
                         for name, value in suite.metadata.items()],
            'numberOfTests': suite.test_count,
            'suites': self._convert_suites(suite),
            'tests': self._convert_tests(suite),
            'keywords': list(self._convert_keywords(suite))
        }

    def _get_relative_source(self, source):
        if not source or not self._output_path:
            return ''
        return get_link_path(source, os.path.dirname(self._output_path))

    def _escape(self, item):
        return html_escape(item)

    def _html(self, item):
        return html_format(unescape(item))

    def _convert_suites(self, suite):
        return [self._convert_suite(s) for s in suite.suites]

    def _convert_tests(self, suite):
        return [self._convert_test(t) for t in suite.tests]

    def run_docker(self, test_name):
        f = open("./parallel_results/test_executing.txt", "a")
        f.write(test_name + "\n")
        count = len(open("./parallel_results/test_executing.txt").readlines())
        f.close()

        with open("./parallel_results/auto_generated_config.yml") as stream:
            data_loaded = yaml.load(stream)

        website = data_loaded['website']
        language = data_loaded['language']
        remote_desired = data_loaded['remote_desired']
        retry_run = data_loaded['retry_run']
        critical = data_loaded['critical']
        timeout = data_loaded['timeout']
        batch = data_loaded['batch']
        image_name = data_loaded['image_name']

        critical = critical.replace('-', ' ')

        if timeout == 'half':
            time.sleep(1)
        elif timeout == 'single':
            time.sleep(2)
        elif timeout == 'double':
            time.sleep(5)
        else:
            time.sleep(5)

        if batch != 'full':
            num_batch = int(batch)

            if count != 0:
                if count % num_batch == 0:
                    time.sleep(200)

        subprocess.call("./execution/parallel_wrapper/run_temp.sh  "
                        + test_name
                        + " "
                        + str(count)
                        + " "
                        + website
                        + " "
                        + language
                        + " "
                        + remote_desired
                        + " "
                        + retry_run
                        + " "
                        + critical
                        + " "
                        + timeout
                        + " "
                        + image_name,
                        shell=True)

    def _convert_test(self, test):
        test_name = self._escape(test.name).replace(' ', '_')
        self.run_docker(test_name)

        return {
            'name': self._escape(test.name),
            'fullName': self._escape(test.longname),
            'id': test.id,
            'doc': self._html(test.doc),
            'tags': [self._escape(t) for t in test.tags],
            'timeout': self._get_timeout(test.timeout),
            'keywords': list(self._convert_keywords(test))
        }

    def _convert_keywords(self, item):
        for kw in getattr(item, 'keywords', []):
            if kw.type == kw.SETUP_TYPE:
                yield self._convert_keyword(kw, 'SETUP')
            elif kw.type == kw.TEARDOWN_TYPE:
                yield self._convert_keyword(kw, 'TEARDOWN')
            elif kw.type == kw.FOR_LOOP_TYPE:
                yield self._convert_for_loop(kw)
            else:
                yield self._convert_keyword(kw, 'KEYWORD')

    def _convert_for_loop(self, kw):
        return {
            'name': self._escape(self._get_for_loop(kw)),
            'arguments': '',
            'type': 'FOR'
        }

    def _convert_keyword(self, kw, kw_type):
        return {
            'name': self._escape(self._get_kw_name(kw)),
            'arguments': self._escape(', '.join(kw.args)),
            'type': kw_type
        }

    def _get_kw_name(self, kw):
        if kw.assign:
            return '%s = %s' % (', '.join(a.rstrip('= ') for a in kw.assign), kw.name)
        return kw.name

    def _get_for_loop(self, kw):
        joiner = ' %s ' % kw.flavor
        return ', '.join(kw.variables) + joiner + seq2str2(kw.values)

    def _get_timeout(self, timeout):
        if timeout is None:
            return ''
        try:
            tout = secs_to_timestr(timestr_to_secs(timeout.value))
        except ValueError:
            tout = timeout.value
        if timeout.message:
            tout += ' :: ' + timeout.message
        return tout


def testdoc_cli(arguments):
    TestDoc().execute_cli(arguments)


def testdoc(*arguments, **options):
    TestDoc().execute(*arguments, **options)


def clear_arguments(argument):
    full_arguments = argument[1:]
    extra_arguments = argument[-8:]
    final_arguments = [item for item in full_arguments if item not in extra_arguments]

    data = {}
    data['website'] = argument[-8]
    data['language'] = argument[-7]
    data['remote_desired'] = argument[-6]
    data['retry_run'] = argument[-5]
    data['critical'] = argument[-4]
    data['timeout'] = argument[-3]
    data['batch'] = argument[-2]
    data['image_name'] = argument[-1]
    with open("./parallel_results/auto_generated_config.yml", 'w+') as outfile:
        yaml.dump(data, outfile, default_flow_style=False)

    return argument_to_remove(final_arguments)


def pre_run_files_creation():
    directory = "./parallel_results/"

    if os.path.exists(directory):
        shutil.rmtree(directory)

    if not os.path.exists(directory):
        os.mkdir(directory)

    f = open(directory + "test_executed.txt", "w+")
    f.close()
    f = open(directory + "test_executing.txt", "w+")
    f.close()


def argument_to_remove(arguments):

    delete_arguments(arguments, '--include')
    delete_arguments(arguments, '--test')
    delete_arguments(arguments, '--exclude')
    delete_arguments(arguments, '--suite')
    return arguments


def delete_arguments(arguments, item):
    position = get_location(arguments, item)
    if arguments[position + 1] == 'empty':
        del arguments[position]
        del arguments[position]


def get_location(arguments, item_to_find):
    for i in [i for i, x in enumerate(arguments) if x == item_to_find]:
        return i


if __name__ == '__main__':
    pre_run_files_creation()
    testdoc_cli(clear_arguments(sys.argv))
