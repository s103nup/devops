#!/usr/bin/env bash

set -euo pipefail

# Script: start-feature.sh
# Purpose: Create a feature branch from a source branch with optional unit tests.
# Version: 1.0.0
# Date: 2026-02-10
#
# Inputs (interactive):
# - Source branch name (required)
# - Run unit tests on source branch? (Y/n)
# - Feature branch name (required, ex: feature/tab/12345)
#
# Example:
#   ./scripts/start-feature.sh

die() {
	echo "Error: $1" >&2
	exit 1
}

get_repo_root() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	echo "$script_dir"
}

prompt_source_branch() {
	local branch
	read -r -p "Enter the source branch: " branch
	if [ -z "$branch" ]; then
		die "Source branch cannot be empty."
	fi
	echo "$branch"
}

prompt_feature_branch() {
	local branch
	read -r -p "Enter the feature branch (ex: feature/tab/12345): " branch
	if [ -z "$branch" ]; then
		die "Feature branch cannot be empty."
	fi
	echo "$branch"
}

ensure_branch_exists() {
	local repo_root=$1
	local branch=$2

	if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
		return 0
	fi

	if git -C "$repo_root" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
		return 0
	fi

	die "Source branch '$branch' does not exist locally or on origin."
}

update_source_branch() {
	local repo_root=$1
	local branch=$2

	if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
		git -C "$repo_root" switch "$branch"
	else
		git -C "$repo_root" switch -c "$branch" --track "origin/$branch"
	fi

	git -C "$repo_root" pull origin "$branch"
}

prompt_run_tests() {
	local answer
	read -r -p "Run unit tests on source branch? (Y/n): " answer

	case "$answer" in
		""|[Yy]*) return 0 ;;
		[Nn]*) return 1 ;;
		*) die "Please answer Y or n." ;;
	esac
}

run_unit_tests() {
	local repo_root=$1
	local compose_file="$repo_root/docker/docker-compose.yml"
	local env_file="$repo_root/docker/.env"
	local service_name="php-fpm"

	if [ ! -f "$compose_file" ]; then
		die "Docker compose file not found: $compose_file"
	fi

	if [ ! -f "$env_file" ]; then
		die "Docker env file not found: $env_file"
	fi

	docker compose --env-file "$env_file" -f "$compose_file" exec "$service_name" \
		./vendor/bin/phpunit --stop-on-failure
}

create_feature_branch() {
	local repo_root=$1
	local source_branch=$2
	local feature_branch=$3

	git -C "$repo_root" switch -c "$feature_branch" "$source_branch"
}

push_feature_branch() {
	local repo_root=$1
	local feature_branch=$2

	git -C "$repo_root" push --set-upstream origin "$feature_branch"
}

main() {
	local repo_root
	local source_branch
	local feature_branch

	repo_root="$(get_repo_root)"

	source_branch="$(prompt_source_branch)"
	ensure_branch_exists "$repo_root" "$source_branch"
	update_source_branch "$repo_root" "$source_branch"

	if prompt_run_tests; then
		run_unit_tests "$repo_root"
	fi

	feature_branch="$(prompt_feature_branch)"
	create_feature_branch "$repo_root" "$source_branch" "$feature_branch"
	push_feature_branch "$repo_root" "$feature_branch"

	echo "Feature branch '$feature_branch' created from '$source_branch' and pushed."
}

main