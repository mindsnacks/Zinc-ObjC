#!/usr/bin/env python

import sys
import json
import os.path
import argparse
import re
from zinc import ZincManifest
from zinc.utils import sha1_for_path

IGNORE_PATTERNS=['\.DS_Store']

def main():

    parser = argparse.ArgumentParser(description='')
    parser.add_argument('src_dirs', metavar='src_dir',
            nargs='*', help='')
    parser.add_argument('-d', '--dest', dest='dest',
            help='destination directory', default='.')
    parser.add_argument('-x', '--xcode', dest='xcode_mode', action='store_true',
            help='Use environment variables from Xcode. Overrides other \
            settings', default=False)

    args = parser.parse_args()

    if args.xcode_mode:
        dest = os.path.join(os.environ['BUILT_PRODUCTS_DIR'],
                os.environ['UNLOCALIZED_RESOURCES_FOLDER_PATH'])
        src_count = int(os.environ['SCRIPT_INPUT_FILE_COUNT'])
        src_dirs = [os.environ['SCRIPT_INPUT_FILE_%d' % (i)] 
                for i in range(src_count)]
    else:
        src_dirs = args.src_dirs
        dest = args.dest
    
    for src_dir in src_dirs:
        src_dir = os.path.realpath(src_dir)
        bundle_catalog_id = os.path.split(src_dir)[-1]
        bundle_id = bundle_catalog_id.split('.')[-1]
        catalog_id = bundle_catalog_id[:-len(bundle_id)-1]
        print catalog_id, bundle_id
        manifest = ZincManifest(catalog_id, bundle_id, 0)

        cwd = os.path.realpath(os.getcwd())
        os.chdir(src_dir)
        for root, dirs, files in os.walk(src_dir):
            for f in files:
                if True in [re.match(p, f) is not None for p in
                        IGNORE_PATTERNS]: continue
                rel_dir = root[len(src_dir)+1:]
                rel_path = os.path.join(rel_dir, f)
                manifest.add_file(rel_path, sha1_for_path(rel_path))
                manifest.add_format_for_file(rel_path, 'raw',
                        os.path.getsize(rel_path))
        os.chdir(cwd)

        out_file = os.path.join(dest, catalog_id + '.' + bundle_id + '.json')
        print out_file
        with open(out_file, 'w') as f:
            f.write(json.dumps(manifest.to_json()))

if __name__ == "__main__":
    main()
