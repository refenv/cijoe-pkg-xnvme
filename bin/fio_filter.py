#!/usr/bin/env python
"""
    This script extracts the features of interest from the fio-output produced
    by running the CIJOE "xnvme_fioe.sh" testcase.
"""
from pathlib import Path
import argparse
import json
import sys
import os

def extract(root, expr, func):
    """
    Recursively scan root for files matching expr, applying func(filepath)
    Yielding tuples on the form (filepath, func(filepath))
    """

    for path in Path(root).rglob(expr):
        fpath = path.resolve()

        yield fpath, func(fpath)

def transform(fpath):
    """
    Extract JSON from the file at the given path
    Naively searches for document in the midst of other stuff
    """

    # Read the entire file
    output = None
    with open(fpath) as fdo:
        output = fdo.read()

    # Scan for the beginning and end of the JSON txt-representation
    begin = end = 0
    prev = " "
    for cnt, char in enumerate(output):
        if prev == "\n":
            if char == "{":
                begin = cnt
            elif char == "}":
                end = cnt
        prev = char

    return json.loads(output[begin:end+1])

def load(fpath, doc):
    """Extract the features of interest"""

    prefix = "xnvme-fioe-compare-"

    _, rest = str(fpath).split(prefix)
    topic, jazz = rest.split(os.sep)[0:2]

    for job in doc["jobs"]:
        yield (
            "%s.%s" % (jazz, topic),
            "read",
            "qd: %02d" % int(job["job options"]["iodepth"]),
            "iops: %0.1fk" % (job["read"]["iops"] / 1000),
            "bw_MB: % 5d" % (job["read"]["bw_bytes"] / (1000*1000)),
            "bw_MiB: % 5d" % (job["read"]["bw_bytes"] / (1024*1024)),
            "lat_min: % 5d" % job["read"]["lat_ns"]["min"],
            "lat_avg: % 5d" % job["read"]["lat_ns"]["mean"]
        )

def main(args):
    """Let's go!"""

    for fpath, doc in extract(args.output, args.fn_glob, transform):
        for result in load(fpath, doc):
            print(", ".join(list(result)))

def parse_args():
    """Parse command-line arguments for cij_runner"""

    prsr = argparse.ArgumentParser(
        description="Extract features from fio-output",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    prsr.add_argument(
        'output',
        help="Path to test output",
        default=os.getcwd()
    )
    prsr.add_argument(
        "--fn-glob",
        help="Filter matching fio-output files",
        default="fio-output*.txt"
    )

    return prsr.parse_args()

if __name__ == "__main__":
    try:
        sys.exit(main(parse_args()))
    except (KeyboardInterrupt) as exc:
        print("Well... too bad...")
