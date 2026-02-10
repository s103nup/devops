#!/usr/bin/env bash

set -euo pipefail

# Script: to-master.sh
# Purpose: Merge release into master and update version with optional build.
# Version: 1.0.0
# Date: 2026-02-10
#
# Inputs (interactive):
# - New version number (required, numeric)
# - Run npm build? (Y/n)
#
# Example:
#   ./scripts/to-master.sh

die() {
  echo "Error: $1" >&2
  exit 1
}

get_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  echo "$script_dir"
}

# 顯示當前版本
show_current_version() {
  local repo_root=$1
  local current_version
  current_version=$(git -C "$repo_root" describe --tags --abbrev=0 2>/dev/null || echo "無標籤")
  echo "Current version: $current_version"
  return 0
}

# 驗證版本格式
validate_version() {
  local version=$1
  if [ -z "$version" ]; then
    echo "Version cannot be empty."
    return 1
  fi

  if ! [[ "$version" =~ ^[0-9]+$ ]]; then
    echo "Version must be a number."
    return 1
  fi

  return 0
}

# 取得新版本號
prompt_version() {
  echo -n "Enter the new version: " >&2
  read -r version

  if ! validate_version "$version"; then
    exit 1
  fi

  echo "$version"
}

# 更新 version.yaml
update_version_file() {
  local repo_root=$1
  local version=$2
  local version_file="$repo_root/version.yaml"

  if [ ! -f "$version_file" ]; then
    die "version.yaml not found: $version_file"
  fi

  sed -i '' "s/version: \"[0-9]*\"/version: \"$version\"/" "$version_file"
  echo "Updated version.yaml to version: $version"
}

# 建置專案
build_project() {
  local repo_root=$1
  echo -n "Do you want to run npm build? (Y/n): "
  read -r answer

  if [[ "$answer" =~ ^[Nn]$ ]]; then
    echo "Skipping build."
    return 1
  else
    echo "Building project..."
    (cd "$repo_root" && npm ci && npm run build)
    return 0
  fi
}

# 提交變更
commit_changes() {
  local repo_root=$1
  local version=$2
  local has_build=$3

  git -C "$repo_root" add "$repo_root/version.yaml"

  if [ "$has_build" = "true" ]; then
    git -C "$repo_root" add "$repo_root/public/build/"
  fi

  git -C "$repo_root" commit -m "Update version to $version and build"
  echo "Committed changes"
}

# 推送變更
push_changes() {
  local repo_root=$1
  git -C "$repo_root" push origin master
  echo "Pushed changes to master"
}

# 顯示完成訊息
show_completion_message() {
  echo ""
  echo "Build triggered. Please check the GitLab pipeline:"
  echo "   https://gitlab.svc.litv.tv/cms-team/cms4/-/pipelines"
  echo ""
  echo "Version update and merge completed successfully."
}

# 主流程
main() {
  local repo_root
  repo_root="$(get_repo_root)"

  echo "Starting merge and version update process..."
  echo ""

  # Checkout and update the release branch
  echo "Updating release branch..."
  git -C "$repo_root" switch release
  git -C "$repo_root" pull origin release

  # Checkout and update the master branch
  echo "Updating master branch..."
  git -C "$repo_root" switch master
  git -C "$repo_root" pull origin master

  # Merge release into master
  echo "Merging release into master..."
  git -C "$repo_root" merge --no-ff release -m "Merge release into master"
  echo ""

  # Display current version and get new version
  show_current_version "$repo_root"
  VERSION=$(prompt_version)
  echo ""

  # Update, build, commit and push
  update_version_file "$repo_root" "$VERSION"

  if build_project "$repo_root"; then
    commit_changes "$repo_root" "$VERSION" "true"
  else
    commit_changes "$repo_root" "$VERSION" "false"
  fi

  # push_changes "$repo_root"

  # Show completion message
  show_completion_message
}

# 執行主流程
main
