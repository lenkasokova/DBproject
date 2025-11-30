#!/usr/bin/env python3
import argparse, os, re, sys, tempfile, shutil
from pathlib import Path

# Matches ".0" that follows a digit and is NOT followed by another digit
SAFE_PATTERN = re.compile(r'(?<=\d)\.0(?!\d)')

def process_stream(instream, outstream, naive: bool):
    if naive:
        for line in instream:
            outstream.write(line.replace(".0", ""))
    else:
        for line in instream:
            outstream.write(SAFE_PATTERN.sub("", line))

def main():
    ap = argparse.ArgumentParser(
        description="Remove trailing numeric '.0' from a text file (e.g., 123.0 -> 123)."
    )
    ap.add_argument("input", help="Path to the input file")
    ap.add_argument("-o", "--output", help="Path to write the result (default: <input>.cleaned)")
    ap.add_argument("--inplace", action="store_true", help="Edit the file in place (atomic replace)")
    ap.add_argument("--naive", action="store_true",
                    help="Replace ALL occurrences of '.0' (not just numeric endings).")
    ap.add_argument("--encoding", default="utf-8", help="File encoding (default: utf-8)")
    args = ap.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        print(f"Error: {in_path} does not exist.", file=sys.stderr)
        sys.exit(1)

    if args.inplace and args.output:
        print("Choose either --inplace or --output, not both.", file=sys.stderr)
        sys.exit(1)

    if args.inplace:
        # Write to temp file in the same directory, then atomic replace
        with tempfile.NamedTemporaryFile("w", delete=False, dir=str(in_path.parent), encoding=args.encoding) as tmpf:
            with in_path.open("r", encoding=args.encoding, newline="") as fin:
                process_stream(fin, tmpf, naive=args.naive)
            tmp_name = tmpf.name
        os.replace(tmp_name, in_path)  # atomic on the same filesystem
        return

    out_path = Path(args.output) if args.output else in_path.with_suffix(in_path.suffix + ".cleaned")
    with in_path.open("r", encoding=args.encoding, newline="") as fin, \
         out_path.open("w", encoding=args.encoding, newline="") as fout:
        process_stream(fin, fout, naive=args.naive)

    print(f"Wrote: {out_path}")

if __name__ == "__main__":
    main()
