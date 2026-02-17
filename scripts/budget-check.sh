#!/bin/bash
# Budget checker for OpenRouter API
# Usage: ./budget-check.sh [--warn-only]

# CONFIG
# Set your API key here or via OPENROUTER_API_KEY env var
API_KEY="${OPENROUTER_API_KEY}"

DAILY_BUDGET=5.00          # $5/day budget
WARN_PERCENT=20             # Warn if below 20% remaining
WARN_DOLLAR=1.00            # Warn if single call > $1

# Model pricing (per 1M tokens) - add more as needed
declare -A MODEL_PRICES=(
    ["minimax/minimax-m2.5"]=0.20
    ["moonshotai/kimi-k2.5"]=0.30
    ["moonshotai/kimi-k2-thinking"]=0.50
    ["xai/grok-4"]=2.00
    ["anthropic/claude-4-opus-2026"]=15.00
    ["openai/gpt-5.3-codex"]=10.00
    ["deepseek/deepseek-v3.2"]=0.25
)

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: OPENROUTER_API_KEY not set${NC}"
    exit 1
fi

# Fetch balance
echo "Fetching OpenRouter balance..."
RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" "https://openrouter.ai/api/v1/credits")

# Extract available credits (looks for "total_usage" or similar)
BALANCE=$(echo "$RESPONSE" | grep -oP '"total_credits":\s*\K[0-9.]+' || echo "0")

if [ "$BALANCE" = "0" ] || [ -z "$BALANCE" ]; then
    # Try alternate field
    BALANCE=$(echo "$RESPONSE" | grep -oP '"balance":\s*"\K[0-9.]+' || echo "0")
fi

if [ "$BALANCE" = "0" ] || [ -z "$BALANCE" ]; then
    # Try alternate field (total_credits)
    BALANCE=$(echo "$RESPONSE" | grep -oP '"total_credits":\s*\K[0-9.]+' || echo "0")
fi

if [ "$BALANCE" = "0" ] || [ -z "$BALANCE" ]; then
    echo -e "${RED}Could not parse balance from response:${NC}"
    echo "$RESPONSE"
    exit 1
fi

# Calculate percentages
REMAINING_PERCENT=$(echo "scale=2; ($BALANCE / $DAILY_BUDGET) * 100" | bc)

echo -e "\n=== OpenRouter Budget ==="
echo -e "Balance: \$${BALANCE}"
echo -e "Daily Budget: \$${DAILY_BUDGET}"
echo -e "Remaining: ${REMAINING_PERCENT}%"

# Warnings
if (( $(echo "$REMAINING_PERCENT < $WARN_PERCENT" | bc -l) )); then
    echo -e "${RED}⚠️  WARNING: Balance below ${WARN_PERCENT}%!${NC}"
fi

if (( $(echo "$BALANCE < 1.00" | bc -l) )); then
    echo -e "${RED}⚠️  WARNING: Less than $1 remaining!${NC}"
fi

# Estimate cost function
estimate_cost() {
    local model=$1
    local input_tokens=$2
    local output_tokens=$3
    
    local price=${MODEL_PRICES[$model]:-0.50}  # default to $0.50 if unknown
    
    local input_cost=$(echo "scale=6; ($input_tokens / 1000000) * $price" | bc)
    local output_cost=$(echo "scale=6; ($output_tokens / 1000000) * $price * 1.5" | bc)  # output usually more expensive
    local total=$(echo "scale=6; $input_cost + $output_cost" | bc)
    
    echo "$total"
}

# Quick cost estimator
if [ "$1" = "--estimate" ]; then
    MODEL="${2:-minimax/minimax-m2.5}"
    INPUT_TOKENS="${3:-1000}"
    OUTPUT_TOKENS="${4:-2000}"
    
    COST=$(estimate_cost "$MODEL" $INPUT_TOKENS $OUTPUT_TOKENS)
    
    echo -e "\n=== Cost Estimate ==="
    echo -e "Model: $MODEL"
    echo -e "Input tokens: $INPUT_TOKENS"
    echo -e "Output tokens: $OUTPUT_TOKENS"
    echo -e "Estimated cost: \$$COST"
    
    if (( $(echo "$COST > $WARN_DOLLAR" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Warning: This call may exceed \$${WARN_DOLLAR}${NC}"
    fi
fi

echo ""
