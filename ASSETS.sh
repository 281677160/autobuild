#!/bin/bash

# 配置变量
GIT_REPOSITORY="281677160/autobuild"  # 替换为你的仓库路径
UPDATE_TAG="Update-x86"
FIRMWARE_VERSION="23.05-Lede-x86-64"
BOOT_TYPE="uefi"
FIRMWARE_SUFFIX=".img.gz"

# 获取Release中的所有文件
ASSETS=$(curl -s -H "Authorization: token $REPO_TOKEN" \
  "https://api.github.com/repos/$GIT_REPOSITORY/releases/tags/$UPDATE_TAG" \
  | jq -r --arg regex "$FIRMWARE_VERSION-.*-$BOOT_TYPE-.*$FIRMWARE_SUFFIX" '.assets[] | select(.name | test($regex)) | "\(.id) \(.name) \(.updated_at)"')

# 检查是否有符合条件的文件
if [ -z "$ASSETS" ]; then
  echo "没有找到符合条件的文件。"
  exit 0
fi

# 将文件按更新时间排序，保留时间最靠前的文件
readarray -t sorted_assets < <(echo "$ASSETS" | sort -k3,3)

# 删除除第一个文件之外的所有文件
for asset in "${sorted_assets[@]:1}"; do
  asset_id=$(echo "$asset" | awk '{print $1}')
  asset_name=$(echo "$asset" | awk '{print $2}')
  echo "删除文件: $asset_name (ID: $asset_id)"
  curl -X DELETE -s -H "Authorization: token $REPO_TOKEN" \
    "https://api.github.com/repos/$GIT_REPOSITORY/releases/assets/$asset_id"
done

echo "操作完成。"
