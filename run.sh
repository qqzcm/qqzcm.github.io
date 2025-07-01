#!/bin/bash

SOURCE_DIR="/e/note"

rm -f /e/note/myblog/_posts/*

EXCLUDED_DIRS=("myblog" "image")

if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: dir $SOURCE_DIR not found"
    exit 1
fi

for dir in "$SOURCE_DIR"/*/; do
    dir_name=$(basename "$dir")
    
    skip=false
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [ "$dir_name" = "$excluded" ]; then
            skip=true
            break
        fi
    done
    
    if [ "$skip" = true ]; then
        continue
    fi
    
    echo "copy $dir"
    cp -r "$dir"/*  /e/note/myblog/_posts/
done

echo "============>copy build"

jekyll build --incremental 
echo "============>jekyll build"


rm -rf  /e/note/myblog/image
cp -r /e/note/image /e/note/myblog/
echo "============>xcopy"

#cd _site
#echo "============>cd _site"

git add .
echo "============>git add"

git commit -m "update"
echo "============>git commit"

git push origin master --force
echo "============>git push"


