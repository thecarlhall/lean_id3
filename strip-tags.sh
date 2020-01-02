#!/usr/bin/env bash
set -e

## collect verbose id3 information
id3=$(eyeD3 --no-color -v "$@")

## base options for all files
opts=${OPTS:-"--remove-all-comments --remove-all-images --remove-all-lyrics --remove-all-objects"}

## allowed frames
## ref: http://id3.org/id3v2.3.0
## ref: http://id3.org/id3v2.4.0-frames
# TALB Album/Movie/Show title
# TCOM Composer
# TCON Content type
# TPE1 Lead performer(s)/Soloist(s)
# TPE2 Band/orchestra/accompaniment
# TPE3 Conductor/performer refinement
# TIT2 Title/songname/content description
# TDRC Recording time
# TDRL Release time
# TPOS Part of a set
# TRCK Track number/Position in set
# TYER Year

allowed_frames=${ALLOWED_FRAMES:-"TALB TCON TPE1 TPE2 TPE3 TIT2 TDRC TDRL TPOS TRCK TYER"}

## parse the id3 info for frame name patterns, like WXXX (27 bytes) or TXXX x 10 (420 bytes)
found_frames=$(echo "$id3" | sort -u | awk '/^[A-Z][A-Z][A-Z][A-Z]? .*\([0-9]+ bytes\)$/ {print $1}')

## Concatenate the found frames with the allowed frames. Doubling the allowed frames will ensure
## they are excluded by `uniq -u` along with any found on the file. This causes the unrecognized
## frames to be unique (count==1) and pass through for stripping.
to_strip=$(echo -n $found_frames $allowed_frames $allowed_frames |
	awk 'BEGIN {RS=" "; ORS="\n"} {print $0}' |
	sort |
	uniq -u |
	awk 'BEGIN {ORS=" "} {print $0}')

to_strip+=" TXXX"

## if frames need to be stripped, add them to the options
if [[ ! -z $to_strip ]]; then
	opts+=$(echo $to_strip |
		awk 'BEGIN {RS=" "} {printf " --remove-frame=%s", $1}')
fi

## convert from v2.2 to v2.4 because eyeD3 can't write v2.2
if [[ "$id3" == *"ID3 v2.2"* ]]; then
	opts+=" --to-v2.4"
fi

## allow errors so that this script will run over all possible files
set +e
echo "Running with: $opts"
eyeD3 -v $opts "$@"
