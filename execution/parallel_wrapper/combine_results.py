from __future__ import print_function
import os
import sys
import subprocess
import shutil
import glob


def intersection(executing_list, executed_list):
    return set(executing_list).intersection(executed_list)


file_exists = os.path.isfile("./suite/parallel_results/test_executing.txt")

if file_exists:
    executing_file_read = open("./suite/parallel_results/test_executing.txt", "r")
    executed_file_read = open("./suite/parallel_results/test_executed.txt", "r")
    executed_file_append = open("./suite/parallel_results/test_executed.txt", "a")

    test_name = sys.argv[1]
    executed_file_append.write(str(test_name) + "\n")
    executed_file_append.close()

    executing_list_array = []
    executed_list_array = []

    for test in executing_file_read:
        executing_list_array.append(test)

    executing_test_count = len(executing_list_array)

    for test in executed_file_read:
        executed_list_array.append(test)

    result = intersection(executing_list_array, executed_list_array)

    intersection_test_count = len(result)

    if executing_test_count == intersection_test_count:
        subprocess.call(
            "rebot --nostatusrc "
            "--output ./output.xml "
            "--outputdir ./suite/parallel_results/ "
            "--merge ./suite/parallel_results/test-*/output.xml ",
            shell=True)

        source = './suite/parallel_results/test-*/*.png'
        destination = './suite/parallel_results/'

        for file in glob.glob(r'./suite/parallel_results/*/*.png'):
            shutil.move(file, destination)

    executing_file_read.close()
    executed_file_read.close()
else:
    print("No Combination of Results needed")
