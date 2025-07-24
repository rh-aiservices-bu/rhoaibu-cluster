#!/bin/bash

# Default values
NUM_QUESTIONS=3
API_KEY=""
URL=""
MODEL=""
INTERACTIVE_MODE=false

# Test questions array
QUESTIONS=(
    "What is the capital of France?"
    "Explain quantum computing in simple terms."
    "Write a Python function to calculate fibonacci numbers."
    "What are the benefits of renewable energy?"
    "How does machine learning work?"
    "What is the difference between AI and ML?"
    "Explain the concept of recursion."
    "What are the main programming paradigms?"
    "How do neural networks learn?"
    "What is the purpose of APIs?"
    "Describe the water cycle."
    "What is blockchain technology?"
    "How does photosynthesis work?"
    "What are the principles of good software design?"
    "Explain the theory of relativity in simple terms."
)

# Function to show usage
show_usage() {
    echo "Usage: $0 --url <URL> --model <MODEL> [--api-key <API_KEY>] [--num-questions <NUM>] [-i|--interactive]"
    echo ""
    echo "Options:"
    echo "  --url           vLLM endpoint URL (required)"
    echo "  --model         Model name to use (required)"
    echo "  --api-key       API key for authentication (optional)"
    echo "  --num-questions Number of questions to test (default: 3)"
    echo "  -i, --interactive Enable interactive mode to ask custom questions"
    echo ""
    echo "Example:"
    echo "  $0 --url http://localhost:8000/v1/chat/completions --model your-model-name"
    echo "  $0 --url http://localhost:8000/v1/chat/completions --model your-model-name --api-key your-key --num-questions 5"
    echo "  $0 --url http://localhost:8000/v1/chat/completions --model your-model-name -i"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            URL="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --num-questions)
            NUM_QUESTIONS="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check required parameters or prompt in interactive mode
if [[ -z "$URL" || -z "$MODEL" ]]; then
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        echo "Interactive setup mode"
        echo ""
        
        # Prompt for URL
        while [[ -z "$URL" ]]; do
            echo -n "Enter vLLM endpoint URL: "
            read -r URL
            if [[ -z "$URL" ]]; then
                echo "URL is required"
            fi
        done
        
        # Prompt for model
        while [[ -z "$MODEL" ]]; do
            echo -n "Enter model name: "
            read -r MODEL
            if [[ -z "$MODEL" ]]; then
                echo "Model name is required"
            fi
        done
        
        # Prompt for API key (optional)
        echo -n "Enter API key (optional, press Enter to skip): "
        read -r API_KEY
        
        echo ""
    else
        echo "Error: --url and --model are required"
        show_usage
        exit 1
    fi
fi

# Auto-append chat completions endpoint if not present
if [[ "$URL" != *"/v1/chat/completions" ]]; then
    URL="${URL%/}/v1/chat/completions"
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed"
    exit 1
fi

# Check if jq is available (optional but helpful)
JQ_AVAILABLE=false
if command -v jq &> /dev/null; then
    JQ_AVAILABLE=true
fi

echo "Testing vLLM endpoint: $URL"
echo "Model: $MODEL"
if [[ "$INTERACTIVE_MODE" == "true" ]]; then
    echo "Mode: Interactive"
else
    echo "Number of test questions: $NUM_QUESTIONS"
fi
echo "$(printf '%.0s-' {1..50})"

# Function to get random questions
get_random_questions() {
    local num=$1
    local selected=()
    local indices=()
    
    # Generate random indices
    while [[ ${#indices[@]} -lt $num && ${#indices[@]} -lt ${#QUESTIONS[@]} ]]; do
        local idx=$((RANDOM % ${#QUESTIONS[@]}))
        if [[ ! " ${indices[*]} " =~ " ${idx} " ]]; then
            indices+=($idx)
        fi
    done
    
    # Get questions by indices
    for idx in "${indices[@]}"; do
        selected+=("${QUESTIONS[$idx]}")
    done
    
    printf '%s\n' "${selected[@]}"
}

# Function to test endpoint
test_question() {
    local question="$1"
    local test_num="$2"
    
    echo ""
    echo "Test $test_num: $question"
    
    # Prepare headers
    local headers=(-H "Content-Type: application/json")
    if [[ -n "$API_KEY" ]]; then
        headers+=(-H "Authorization: Bearer $API_KEY")
    fi
    
    # Prepare payload
    local payload=$(cat <<EOF
{
    "model": "$MODEL",
    "messages": [
        {"role": "user", "content": "$question"}
    ],
    "max_tokens": 150,
    "temperature": 0.7
}
EOF
)
    
    # Make request
    local response
    local http_code
    
    response=$(curl -s -w "%{http_code}" "${headers[@]}" -d "$payload" "$URL" 2>/dev/null)
    http_code="${response: -3}"
    response="${response%???}"
    
    if [[ "$http_code" == "200" ]]; then
        if [[ "$JQ_AVAILABLE" == "true" ]]; then
            local content
            local prompt_tokens
            local completion_tokens
            local total_tokens
            
            content=$(echo "$response" | jq -r '.choices[0].message.content // "No content found"' 2>/dev/null)
            prompt_tokens=$(echo "$response" | jq -r '.usage.prompt_tokens // "N/A"' 2>/dev/null)
            completion_tokens=$(echo "$response" | jq -r '.usage.completion_tokens // "N/A"' 2>/dev/null)
            total_tokens=$(echo "$response" | jq -r '.usage.total_tokens // "N/A"' 2>/dev/null)
            
            if [[ ${#content} -gt 200 ]]; then
                content="${content:0:200}..."
            fi
            
            echo "✅ Response: $content"
            echo "📊 Token Usage - Prompt: $prompt_tokens | Completion: $completion_tokens | Total: $total_tokens"
        else
            echo "✅ Response received (install jq for formatted output)"
            echo "Raw response: ${response:0:300}..."
        fi
    else
        echo "❌ HTTP $http_code"
        if [[ "$JQ_AVAILABLE" == "true" ]]; then
            local error_msg
            error_msg=$(echo "$response" | jq -r '.error.message // .detail // "Unknown error"' 2>/dev/null)
            echo "Error: $error_msg"
        else
            echo "Error response: ${response:0:200}..."
        fi
    fi
}

# Get random questions and test them
IFS=$'\n' read -d '' -r -a selected_questions < <(get_random_questions "$NUM_QUESTIONS")

for i in "${!selected_questions[@]}"; do
    test_question "${selected_questions[$i]}" $((i + 1))
done

echo ""
echo "Testing completed!"