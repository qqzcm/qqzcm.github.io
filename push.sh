#!/bin/bash

# 设置源目录路径
SOURCE_DIR="/e/note"

# 设置要排除的子目录列表，多个目录用空格分隔
EXCLUDED_DIRS=("myblog" )

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误: 源目录 $SOURCE_DIR 不存在。"
    exit 1
fi

# 遍历源目录下的所有一级子目录
for dir in "$SOURCE_DIR"/*/; do
    # 提取子目录名称
    dir_name=$(basename "$dir")
    
    # 检查是否需要排除当前子目录
    skip=false
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [ "$dir_name" = "$excluded" ]; then
            skip=true
            break
        fi
    done
    
    # 如果需要排除，则跳过当前子目录
    if [ "$skip" = true ]; then
        continue
    fi
    
    # 复制子目录中的文件到/root/目录
    echo "正在复制 $dir 中的文件到 /root/"
    #cp -r "$dir"/* /e/note/_posts 2>/dev/null || echo "警告: $dir 为空或复制过程中发生错误。"
done

echo "复制完成！"    