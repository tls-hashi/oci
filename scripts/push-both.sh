#!/bin/bash
# Push to both hashi (work) and origin (personal) remotes
# Usage: ./scripts/push-both.sh [branch]

BRANCH="${1:-main}"
HASHI_REMOTE="hashi"
ORIGIN_REMOTE="origin"

echo "🚀 Pushing to both remotes..."
echo "Branch: $BRANCH"
echo ""

# Push to hashi (work account - triggers HCP Terraform)
echo "📤 Pushing to $HASHI_REMOTE/$BRANCH (HCP Terraform - PRIMARY)..."
if git push $HASHI_REMOTE $BRANCH; then
    echo "✅ Successfully pushed to $HASHI_REMOTE"
else
    echo "❌ Failed to push to $HASHI_REMOTE"
    exit 1
fi

echo ""

# Push to origin (personal account - keep in sync)
echo "📤 Pushing to $ORIGIN_REMOTE/$BRANCH (Personal - SYNC)..."
if git push $ORIGIN_REMOTE $BRANCH; then
    echo "✅ Successfully pushed to $ORIGIN_REMOTE"
else
    echo "❌ Failed to push to $ORIGIN_REMOTE"
    exit 1
fi

echo ""
echo "✨ Both remotes updated successfully!"
echo "💡 HCP Terraform will process the push to $HASHI_REMOTE/main"
