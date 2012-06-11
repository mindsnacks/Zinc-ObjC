#!/usr/bin/env python

import sys
import json
import os.path
from zinc import ZincManifest
from zinc.utils import sha1_for_path

def main():
    if len(sys.argv) < 2:
        print "usage: %s <path to local filelist>" % (sys.argv[0])
        exit(1)

    in_path = sys.argv[1]
    in_file = os.path.basename(in_path)
    os.chdir(os.path.dirname(in_path))

    with open(in_file) as f:
        d = json.load(f)
        bundle_id = d['bundle']
        files = d['files']

    manifest = ZincManifest(bundle_id, 0)
    for file in files:
        manifest.add_file(file, sha1_for_path(file))
        manifest.add_format_for_file(file, 'raw', os.path.getsize(file))

    print manifest.to_json()

if __name__ == "__main__":
    main()
