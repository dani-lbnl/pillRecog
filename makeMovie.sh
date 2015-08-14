#If you have a bunch of files, then just launch it on limited numbers of files instead of all at once. For example, something like this:
#!/usr/bin/env bash

## Collect all png files in the files array
files=( *png )
## How many should be done at once
batch=50

## Read the array in batches of $batch
for (( i=0; $i<${#files[@]}; i+=$batch ))
do
    ## Convert this batch
    convert -delay 2 -loop 0 "${files[@]:$i:$batch}" animated.$i.gif
done

## Now, merge them into a single file
convert  animated.*.gif all.gif
