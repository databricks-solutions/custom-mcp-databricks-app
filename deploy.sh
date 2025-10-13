#!/bin/bash

# Deploy the Databricks App Template to Databricks.
# For configuration options see README.md and .env.local.
# Usage: ./deploy.sh [--verbose] [--create]

set -e

# Parse command line arguments
VERBOSE=false
CREATE_APP=false
for arg in "$@"; do
  case $arg in
    --verbose)
      VERBOSE=true
      echo "🔍 Verbose mode enabled"
      ;;
    --create)
      CREATE_APP=true
      echo "🔧 App creation mode enabled"
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: ./deploy.sh [--verbose] [--create]"
      exit 1
      ;;
  esac
done

# Function to print timing info
print_timing() {
  if [ "$VERBOSE" = true ]; then
    echo "⏱️  $(date '+%H:%M:%S') - $1"
  fi
}

# Load environment variables from .env.local if it exists.
print_timing "Loading environment variables"
if [ -f .env.local ]
then
  source .env.local
fi

# Validate required configuration
if [ -z "$DBA_SOURCE_CODE_PATH" ]
then
  echo "❌ DBA_SOURCE_CODE_PATH is not set. Please run ./setup.sh first."
  exit 1
fi

if [ -z "$DATABRICKS_APP_NAME" ]
then
  echo "❌ DATABRICKS_APP_NAME is not set. Please run ./setup.sh first."
  exit 1
fi

if [ -z "$DATABRICKS_AUTH_TYPE" ]
then
  echo "❌ DATABRICKS_AUTH_TYPE is not set. Please run ./setup.sh first."
  exit 1
fi

# Handle authentication based on type
print_timing "Starting authentication"
echo "🔐 Authenticating with Databricks..."

if [ "$DATABRICKS_AUTH_TYPE" = "pat" ]; then
  # PAT Authentication
  if [ -z "$DATABRICKS_HOST" ] || [ -z "$DATABRICKS_TOKEN" ]; then
    echo "❌ PAT authentication requires DATABRICKS_HOST and DATABRICKS_TOKEN. Please run ./setup.sh first."
    exit 1
  fi
  
  echo "Using Personal Access Token authentication"
  export DATABRICKS_HOST="$DATABRICKS_HOST"
  export DATABRICKS_TOKEN="$DATABRICKS_TOKEN"
  
  # Test connection
  if ! databricks current-user me >/dev/null 2>&1; then
    echo "❌ PAT authentication failed. Please check your credentials."
    echo "💡 Try running: databricks auth login --host $DATABRICKS_HOST"
    echo "💡 Or run ./setup.sh to reconfigure authentication"
    exit 1
  fi
  
elif [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  # Profile Authentication
  if [ -z "$DATABRICKS_CONFIG_PROFILE" ]; then
    echo "❌ Profile authentication requires DATABRICKS_CONFIG_PROFILE. Please run ./setup.sh first."
    exit 1
  fi
  
  echo "Using profile authentication: $DATABRICKS_CONFIG_PROFILE"
  
  # Test connection
  if ! databricks current-user me --profile "$DATABRICKS_CONFIG_PROFILE" >/dev/null 2>&1; then
    echo "❌ Profile authentication failed. Please check your profile configuration."
    echo "💡 Try running: databricks auth login --host <your-host> --profile $DATABRICKS_CONFIG_PROFILE"
    echo "💡 Or run ./setup.sh to reconfigure authentication"
    exit 1
  fi
  
else
  echo "❌ Invalid DATABRICKS_AUTH_TYPE: $DATABRICKS_AUTH_TYPE. Must be 'pat' or 'profile'."
  exit 1
fi

echo "✅ Databricks authentication successful"
print_timing "Authentication completed"

# Function to display app info
display_app_info() {
  echo ""
  echo "📱 App Name: $DATABRICKS_APP_NAME"
  
  # Get app URL
  if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
    APP_URL=$(databricks apps get "$DATABRICKS_APP_NAME" --profile "$DATABRICKS_CONFIG_PROFILE" --output json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('url', 'URL not available'))
except: 
    print('URL not available')
" 2>/dev/null)
  else
    APP_URL=$(databricks apps get "$DATABRICKS_APP_NAME" --output json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('url', 'URL not available'))
except: 
    print('URL not available')
" 2>/dev/null)
  fi
  
  echo "🌐 App URL: $APP_URL"
  echo ""
}

# Display initial app info
display_app_info

# Check if app needs to be created
if [ "$CREATE_APP" = true ]; then
  print_timing "Starting app creation check"
  echo "🔍 Checking if app '$DATABRICKS_APP_NAME' exists..."
  
  # Check if app exists
  if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
    APP_EXISTS=$(databricks apps list --profile "$DATABRICKS_CONFIG_PROFILE" 2>/dev/null | grep -c "^$DATABRICKS_APP_NAME " 2>/dev/null || echo "0")
  else
    APP_EXISTS=$(databricks apps list 2>/dev/null | grep -c "^$DATABRICKS_APP_NAME " 2>/dev/null || echo "0")
  fi
  
  # Clean up the variable (remove any whitespace/newlines)
  APP_EXISTS=$(echo "$APP_EXISTS" | head -1 | tr -d '\n')
  
  if [ "$APP_EXISTS" -eq 0 ]; then
    echo "❌ App '$DATABRICKS_APP_NAME' does not exist. Creating it..."
    echo "⏳ This may take several minutes..."
    
    if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
      if [ "$VERBOSE" = true ]; then
        databricks apps create "$DATABRICKS_APP_NAME" --profile "$DATABRICKS_CONFIG_PROFILE"
      else
        databricks apps create "$DATABRICKS_APP_NAME" --profile "$DATABRICKS_CONFIG_PROFILE" > /dev/null 2>&1
      fi
    else
      if [ "$VERBOSE" = true ]; then
        databricks apps create "$DATABRICKS_APP_NAME"
      else
        databricks apps create "$DATABRICKS_APP_NAME" > /dev/null 2>&1
      fi
    fi
    
    echo "✅ App '$DATABRICKS_APP_NAME' created successfully"
    
    # Verify creation
    if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
      APP_EXISTS=$(databricks apps list --profile "$DATABRICKS_CONFIG_PROFILE" | grep -c "^$DATABRICKS_APP_NAME " || echo "0")
    else
      APP_EXISTS=$(databricks apps list | grep -c "^$DATABRICKS_APP_NAME " || echo "0")
    fi
    
    if [ "$APP_EXISTS" -eq 0 ]; then
      echo "❌ Failed to create app '$DATABRICKS_APP_NAME'"
      exit 1
    fi
  else
    echo "✅ App '$DATABRICKS_APP_NAME' already exists"
  fi
  
  print_timing "App creation check completed"
fi

mkdir -p build

# Generate requirements.txt from pyproject.toml without editable installs
print_timing "Starting requirements generation"
echo "📦 Generating requirements.txt..."
if [ "$VERBOSE" = true ]; then
  echo "Using custom script to avoid editable installs..."
  uv run python scripts/generate_semver_requirements.py
else
  uv run python scripts/generate_semver_requirements.py
fi
print_timing "Requirements generation completed"

# Build frontend
print_timing "Starting frontend build"
echo "🏗️  Building frontend..."
cd client
if [ "$VERBOSE" = true ]; then
  npm run build
else
  npm run build > /dev/null 2>&1
fi
cd ..
echo "✅ Frontend build complete"
print_timing "Frontend build completed"

# Create workspace directory and upload source
print_timing "Starting workspace setup"
echo "📂 Creating workspace directory..."
if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  databricks workspace mkdirs "$DBA_SOURCE_CODE_PATH" --profile "$DATABRICKS_CONFIG_PROFILE"
else
  databricks workspace mkdirs "$DBA_SOURCE_CODE_PATH"
fi
echo "✅ Workspace directory created"

echo "📤 Syncing source code to workspace..."
# Use databricks sync to properly update all files including requirements.txt
if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  databricks sync . "$DBA_SOURCE_CODE_PATH" --profile "$DATABRICKS_CONFIG_PROFILE"
else
  databricks sync . "$DBA_SOURCE_CODE_PATH"
fi
echo "✅ Source code uploaded"
print_timing "Workspace setup completed"

# Deploy to Databricks
print_timing "Starting Databricks deployment"
echo "🚀 Deploying to Databricks..."

if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  if [ "$VERBOSE" = true ]; then
    databricks apps deploy "$DATABRICKS_APP_NAME" --source-code-path "$DBA_SOURCE_CODE_PATH" --debug --profile "$DATABRICKS_CONFIG_PROFILE"
  else
    databricks apps deploy "$DATABRICKS_APP_NAME" --source-code-path "$DBA_SOURCE_CODE_PATH" --profile "$DATABRICKS_CONFIG_PROFILE"
  fi
else
  if [ "$VERBOSE" = true ]; then
    databricks apps deploy "$DATABRICKS_APP_NAME" --source-code-path "$DBA_SOURCE_CODE_PATH" --debug
  else
    databricks apps deploy "$DATABRICKS_APP_NAME" --source-code-path "$DBA_SOURCE_CODE_PATH"
  fi
fi
print_timing "Databricks deployment completed"

echo ""
echo "✅ Deployment complete!"
echo ""

# Get the actual app URL from the apps list
echo "🔍 Getting app URL..."
if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  APP_URL=$(databricks apps list --profile "$DATABRICKS_CONFIG_PROFILE" --output json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        apps = data
    else:
        apps = data.get('apps', [])
    for app in apps:
        if app.get('name') == '"'"'$DATABRICKS_APP_NAME'"'"':
            print(app.get('url', ''))
            break
except: pass
" 2>/dev/null)
else
  APP_URL=$(databricks apps list --output json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        apps = data
    else:
        apps = data.get('apps', [])
    for app in apps:
        if app.get('name') == '"'"'$DATABRICKS_APP_NAME'"'"':
            print(app.get('url', ''))
            break
except: pass
" 2>/dev/null)
fi

if [ -n "$APP_URL" ]; then
  echo "Your app is available at:"
  echo "$APP_URL"
  echo ""
  echo "📊 Monitor deployment logs at (visit in browser):"
  echo "$APP_URL/logz"
else
  # Fallback to workspace URL if we can't get the app URL
  if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
    WORKSPACE_URL=$(databricks workspace current --profile "$DATABRICKS_CONFIG_PROFILE" 2>/dev/null | grep -o 'https://[^/]*' || echo "https://<your-databricks-workspace>")
  else
    WORKSPACE_URL="$DATABRICKS_HOST"
  fi
  echo "Your app should be available at:"
  echo "$WORKSPACE_URL/apps/$DATABRICKS_APP_NAME"
  echo ""
  echo "📊 Monitor deployment logs at (visit in browser):"
  echo "Check 'databricks apps list' for the actual app URL, then add /logz"
fi

echo ""
if [ "$DATABRICKS_AUTH_TYPE" = "profile" ]; then
  echo "To check the status:"
  echo "databricks apps list --profile $DATABRICKS_CONFIG_PROFILE"
else
  echo "To check the status:"
  echo "databricks apps list"
fi
echo ""
echo "💡 If the app fails to start, visit the /logz endpoint in your browser for installation issues."
echo "💡 The /logz endpoint requires browser authentication (OAuth) and cannot be accessed via curl."