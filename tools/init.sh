#!/usr/bin/sh

if [ ! -d .git ]; then
    echo "not in a git-managed repo."
    exit 1
fi

mkdir -p .git/hooks
if [ -f .git/hooks/pre-push ]; then
    echo "pre-push hook already exists in this repo."
    echo "consider manually merging your custom hook with the one defined here."
    exit 1
fi

cp tools/hooks/pre-push .git/hooks/ || exit 1
exit 0
