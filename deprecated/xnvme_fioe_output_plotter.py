#!/usr/bin/env python3
# pylint: skip-file
import matplotlib.pyplot as plt
import numpy as np
import argparse
import pprint
import sys
import csv
import re

PROJECT="xNVMe"

PHRASING = {
    "bs": "I/O Size in bytes (bs)",
    "qd": "I/O Depth (qd)",
    "lat": "Latency in nano-seconds (lat)",
    "bw": "Bandwidth in MB/sec (bw)",
    "iops": "I/O Operations pr. second (iops k)",

    "thr/xnvme": "ioctl/%s" % PROJECT,

    "spdk/reimp": "spdk/reference",
    "spdk/%s" % PROJECT: "spdk/%s" % PROJECT,

    "io_uring/reimp/sqt/nvec": "io_uring/reference",
    "io_uring/%s/sqt" % PROJECT: "io_uring/%s" % PROJECT,

    "libaio/reimp": "libaio/reference",
    "libaio/%s" % PROJECT: "libaio/%s" % PROJECT,

    "io_uring/reimp/iop/rf":        "iop",
    "io_uring/reimp/iop/fb/rf":     "iop + fb",
    "io_uring/reimp/iop/nvec/rf":   "iop + nvec",

    "io_uring/reimp/sqt/rf":        "sqt",
    "io_uring/reimp/sqt/fb/rf":     "sqt + fb",
    "io_uring/reimp/sqt/nvec/rf":   "sqt + nvec",

    "io_uring/reimp/sqt/iop/rf":    "sqt + iop",

    "io_uring/reimp/rf": "default",
    "io_uring/reimp/fb/rf": "fb",
    "io_uring/reimp/nvec/rf": "nvec",
}

HATCHES = {
    "spdk": ["o", ".", '-', '+', 'x', '\\', '*', 'o', 'O', '.'],
    "libaio": ["+", "x", '-', '+', 'x', '\\', '*', 'o', 'O', '.'],
    "io_uring": ['\\', '//', '-', '+', 'x', '\\', '*', 'o', 'O', '.'],
    "thr": ['+', 'x', '\\', '*', 'o', 'O', '.', '\\', '//', '-' ],
    "nil": ['+', 'x', '\\', '*', 'o', 'O', '.', '\\', '//', '-' ],
    "null": ['+', 'x', '\\', '*', 'o', 'O', '.', '\\', '//', '-' ],
    "ioctl": ['o', 'O', '.', '\\', '//', '-', '+', 'x', '\\', '*'],
    "uring_pt": ['o', 'O', '.', '\\', '//', '-', '+', 'x', '\\', '*'],
}

def pretty(text):

    phrase = PHRASING.get(text, None)
    if phrase is None:
        return text

    return phrase

def row_to_dict(args, row):
    """Transform the given csv-row to dict"""

    result = {}

    for x in row:
        if not ":" in x:
            continue

        parts = [y.strip() for y in x.strip().split(":")]
        result[parts[0]] = ":".join(parts[1:])

    return result

def label(sample):
    """Produce a label for the given sample"""

    lbl = []
    lbl.append(sample["api"])
    lbl.append(sample["impl"])

    for option in ["sqt", "iop", "nvec", "fb", "rf"]:
        foo = int(sample.get(option, 0))
        if foo:
            lbl.append(option)

    return "/".join(lbl)

def plot_line(args, dataset, labels, xaxis=None, yaxis=None):
    """huha"""

    xticks = []
    markers = ["+", "o", "s", "x", "h", "d", "*", "<", ">", "1", "*", "p"]

    for c, lbl in enumerate(labels):
        dset = dataset[lbl]

        xs = []
        ys = []
        for qd, bs, y in sorted(zip(dset["qd"], dset["bs"], dset[yaxis])):
            if args.qd and qd != int(args.qd):
                continue
            if args.bs and bs != int(args.bs):
                continue

            xs.append(qd if xaxis == "qd" else bs)
            ys.append(y)

        foo = {}
        for x, y in zip(xs, ys):
            if x not in foo:
                foo[x] = y
                continue

            if yaxis == "lat":
                best = min
            else:
                best = max

            foo[x] = best(y, foo[x]) if xaxis == "qd" else best(y, foo[x])

        xs = []
        ys = []
        for x in sorted(foo.keys()):
            xs.append(x)
            ys.append(foo[x])

        print(xs, ys)

        plt.plot(
            xs, ys, label=pretty(lbl) if args.pretty else lbl, marker=markers[c], markersize=12
        )

        if not xticks:
            xticks = xs

    plt.title("%s as a function of %s; fixed-%s" % (
        pretty(args.y_axis), args.x_axis, "qd=%s" % args.qd if args.qd else "bs=%s" % args.bs
    ))

    xticks = [sorted(list(set(xticks)))]

    plt.xscale(args.x_scale)
    plt.ylabel(pretty(yaxis) if args.pretty else yaxis)
    plt.xlabel(pretty(xaxis) if args.pretty else xaxis)
    plt.legend()
    plt.show()

def plot_bar(args, dataset, labels, xaxis=None, yaxis=None):
    """huha"""

    labels.sort()

    nbars = len(labels)
    bars = {}

    groups = ["spdk", "io_uring", "libaio", "uring_pt"] + \
            ["thr" for x in labels if "thr" in x] + \
            ["nil" for x in labels if "nil" in x] + \
            ["null" for x in labels if "null" in x]
    groups.sort()

    width = 1 # the width of the bars

    fig, ax = plt.subplots()

    xticks = []
    grp_labels = []
    global_ymax = 0.0
    for c, grp in enumerate(groups, 0):

        for k, lbl in enumerate([l for l in labels if grp in l], 0):
            hatch = HATCHES.get(grp)[k]

            ys = [{"qd": qd, "bs": bs, "lat": lat, "bw": bw, "iops": iops} for qd, bs, lat, bw, iops in sorted(zip(
                dataset[lbl]["qd"],
                dataset[lbl]["bs"],

                dataset[lbl]["lat"],
                dataset[lbl]["bw"],
                dataset[lbl]["iops"],
            )) if qd == int(args.qd) and bs == int(args.bs)]

            y = min((y[yaxis] for y in ys))
            global_ymax = max(global_ymax, y)

            #xtick = width * c + width * (k+1) + c
            xtick = c * 2 + (k+1) + c
            xticks.append(xtick)

            bars[lbl] = ax.bar(
                xtick * width,
                y,
                width,
                label=pretty(lbl) if args.pretty else lbl,
                hatch=hatch,
                edgecolor='black'
            )
            grp_labels.append(lbl)

    # Add some text for labels, title and custom x-axis tick labels, etc.
    ncol = 3
    if len(labels) == 4 or len(labels) > 8:
        ncol = 4

    ax.legend(
        loc="upper center", ncol=ncol, bbox_to_anchor=(0.5, 1.05),
        fancybox=True, shadow=True
    )

    ax.set_title("%s at qd: %s and bs: %s" % (pretty(yaxis), args.qd, args.bs), y=-0.1)

    ax.set_ylabel(pretty(yaxis))
    if False:
        ax.set_xticks(xticks)
        ax.set_xticklabels(
            grp_labels,
            rotation="-90",
        )
    else:
        plt.tick_params(
            axis='x',          # changes apply to the x-axis
            which='both',      # both major and minor ticks are affected
            bottom=False,      # ticks along the bottom edge are off
            top=False,         # ticks along the top edge are off
            labelbottom=False)

    xmin, xmax, ymin, ymax = plt.axis()
    plt.axis([xmin, xmax, ymin, global_ymax * 1.30])

    def autolabel(rects):
        """Attach a text label above each bar in *rects*, displaying its height."""

        for rect in rects:
            height = rect.get_height()
            ax.annotate(
                '{}'.format(height),
                xy=(rect.get_x() + rect.get_width() / 2, height),
                xytext=(0, 3),  # 3 points vertical offset
                textcoords="offset points",
                ha='center',
                va='bottom',
                rotation=45
            )

    for lbl in bars:
        autolabel(bars[lbl])

    fig.tight_layout()

    plt.show()

def etl(args):
    """Extract the csv data, transform into dicts load in plot"""

    dset = {}

    # Open CSV, convert CSV-rows to samples, convert format and construct dict
    with open(args.csv_file, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')

        for row in spamreader:
            sample = row_to_dict(args, row)

            lbl = label(sample)
            if lbl not in dset:
                dset[lbl] = {
                    "qd": [],
                    "bs": [],

                    "bw": [],
                    "iops": [],
                    "lat": []
                }

            dset[lbl]["qd"].append(int(sample["qd"]))
            dset[lbl]["bs"].append(
                int(sample["bs"][:-1]) * 1024  if "k" in sample["bs"] else int(sample["bs"])
            )

            dset[lbl]["bw"].append(float(sample["bw"][:-2]))
            dset[lbl]["iops"].append(float(sample["iops"][:-1]))
            dset[lbl]["lat"].append(int(
                sample["lat_ns_mean"][:-1] if "k" in sample["lat_ns_mean"] else sample["lat_ns_mean"]
            ))

    if args.plot == "bar":
        plot_bar(args, dset, [
            x for x in dset.keys() if re.match(".*%s.*" % args.filter, x)], args.x_axis, args.y_axis
        )
    elif args.plot == "line":
        plot_line(args, dset, [
            x for x in dset.keys() if re.match(".*%s.*" % args.filter, x)], args.x_axis, args.y_axis
        )
    else:
        print("invalid --plot='%s'" % args.plot)
        return 1

    return 0

def main():
    """Parse CLI args and call ETL"""

    parser = argparse.ArgumentParser(description='Produce plots for %s' % PROJECT)
    parser.add_argument(
        "--csv-file",
        required=True,
        help="Path to .csv file containing experiment result"
    )
    parser.add_argument(
        "--filter",
        default="xnvme"
    )
    parser.add_argument(
        "--bs",
        choices=["512", "4096", "16384", "32768"],
        help="Fix block-size to this value to produce a function of qd"
    )
    parser.add_argument(
        "--qd",
        choices=["1", "2", "4", "8", "16"],
        help="Fix queue-depth to this value and produce a function of bs"
    )
    parser.add_argument(
        "--x-scale",
        choices=["linear", "log", "symlog", "logit"],
        default="linear"
    )
    parser.add_argument(
        "--y-axis",
        choices=["lat", "bw", "iops"],
        default="lat"
    )
    parser.add_argument(
        "--y-scale",
        choices=["linear", "log", "symlog", "logit"],
        default="linear"
    )
    parser.add_argument(
        "--plot",
        choices=["line", "bar"],
        default="bar"
    )
    parser.add_argument(
        "--pretty",
        choices=["1", "0"],
        default="1"
    )

    args = parser.parse_args()
    args.pretty = int(args.pretty)

    if not args.bs and not args.qd:
        print("select one of --qd or --bs")
        return 1

    if args.bs:
        args.x_axis = "qd"
    if args.qd:
        args.x_axis = "bs"

    return etl(args)

if __name__ == "__main__":
    sys.exit(main())
