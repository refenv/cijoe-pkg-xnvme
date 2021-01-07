#!/usr/bin/env python
"""
    This script extracts the features of interest from the fio-output produced
    by running the CIJOE "xnvme_fioe.sh" testcase.
"""
import argparse
import json
import sys
import os
try:
    from pathlib import Path
except ImportError:
    sys.exit(0)

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

    label_plan = "NONE"
    label_suite = "NONE"

    dnames = str(fpath).split(os.sep)
    for cnt, dname in enumerate(dnames):
        if ".sh" in dname:
            label_suite = dnames[cnt-1]
            label_plan = dnames[cnt-2]

    feats = {
        "filename": {
            "alias": "fname", "fmt": "%s", "fun": str
        },

        "ioengine": {
            "alias": "eng", "fmt": "%s", "fun": lambda x: "xnvme" if "libxnvme" in x else x
        },
        "sqthread_poll": {
            "alias": "sqt", "fmt": "%d", "fun": int
        },
        "hipri": {
            "alias": "iop", "fmt": "%d", "fun": int
        },
        "nonvectored": {
            "alias": "nvec", "fmt": "%d", "fun": int
        },
        "registerfiles": {
            "alias": "rf", "fmt": "%d", "fun": int
        },
        "fixedbufs": {
            "alias": "fb", "fmt": "%d", "fun": int
        },

        "rw": {
            "alias": "rw", "fmt": "% 8s", "fun": str
        },
        "iodepth": {
            "alias": "qd", "fmt": "%02d", "fun": int
        },
        "bs": {
            "alias": "bs", "fmt": "% 4s", "fun": str
        },
    }
    feats_order = [
#        "filename",
#        "ioengine",
        "sqthread_poll", "hipri", "nonvectored", "fixedbufs", "registerfiles",
        "rw", "iodepth", "bs"
    ]

    res = {

        "bw_bytes": {
            "alias": "bw", "fmt": "% 12s", "fun": lambda x: " %0.1f MB" % (x / (1024 * 1024))
        },
        "iops": {
            "alias": "iops", "fmt": "%s", "fun": lambda x : "% 7s" % ("%0.1fk" % (x / 1000))
        },
        "lat_ns": {
            "alias": "lat_ns_mean", "fmt": "% 7d", "fun": lambda x : x["mean"]
        }
    }
    res_order = ["bw_bytes", "iops", "lat_ns"]

    for job in doc["jobs"]:

        sample = {}

        fio_opts = []
        for feat in feats_order:
            sample[feat] = feats[feat]["fun"]("0")

            fval = doc["global options"].get(feat, None)
            if fval:
                sample[feat] = fval

            fval = job["job options"].get(feat, None)
            if fval:
                sample[feat] = fval

            jazz = "%s: %s" % (feats[feat]["alias"], feats[feat]["fmt"])
            fio_opts.append(jazz % feats[feat]["fun"](sample[feat]))

        fio_res = []
        for r in res_order:
            jazz = "%s: %s" % (res[r]["alias"], res[r]["fmt"])
            fio_res.append(jazz % res[r]["fun"](job["read"][r]))

        eng = doc["global options"]["ioengine"]
        fname = doc["global options"]["filename"]

        api = eng
        impl = "reference"

        if "libxnvme" in eng:
            xopt = [x.split("=")[1] for x in fname.split("?") if "async" in x]
            if not xopt:
                xopt = ["spdk"]

            api = "".join(xopt)
            impl = "xnvme"
            if "ioctl_ring" in fname:
                api = "uring_pt"

        yield (
            "% 16s" % label_plan,
            ", ".join( [ "api: % 8s" % api] + fio_opts + ["impl: % 5s" % impl ] + fio_res)
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
