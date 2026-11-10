#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version> (e.g. ./release.sh 1.0.0)"
    exit 1
fi

# Ensure version starts with 'v' for git tag
if [[ "$VERSION" != v* ]]; then
    TAG="v$VERSION"
else
    TAG="$VERSION"
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  You have uncommitted changes. Please commit or stash them first."
    git status -s
    exit 1
fi

echo "🚀 Preparing release for $TAG..."

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "❌ Tag $TAG already exists locally. Use a new version number."
    exit 1
fi

# Create annotated tag
git tag -a "$TAG" -m "Release $TAG"
echo "✅ Created git tag $TAG"

# Push to GitHub
echo "⬆️  Pushing tag to origin..."
git push origin "$TAG"

echo "🎉 Successfully pushed $TAG to GitHub!"
echo "GitHub Actions is now automatically building LuminaClean.app and publishing the release."
echo "Watch progress here: https://github.com/sadik254/LuminaClean/actions"
