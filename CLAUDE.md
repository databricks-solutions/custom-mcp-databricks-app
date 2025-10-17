# Databricks App Template Development Guide

## Project Memory

This is a modern full-stack application template for Databricks Apps, featuring FastAPI backend with React TypeScript frontend and modern development tooling.

## Tech Stack

**Backend:**
- Python with `uv` for package management
- FastAPI for API framework
- Databricks SDK for workspace integration
- OpenAPI automatic client generation

**Frontend:**
- TypeScript with React
- Vite for fast development and hot reloading
- shadcn/ui components with Tailwind CSS
- React Query for API state management
- Bun for package management

## Development Workflow

### 🚨 CRITICAL: UV Installation Required 🚨

**IMPORTANT: This project requires `uv` (Python package manager) to be installed.**

Before proceeding with any development tasks, **ALWAYS check if uv is installed:**

```bash
# Check if uv is installed
uv --version
```

**If uv is not found or command fails:**
1. **ASK USER PERMISSION** before installing: "uv is required for this project. May I install it for you?"
2. **Only after user approval**, install using the official installer:
   ```bash
   # Install uv (requires user permission)
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # Restart shell or source the updated PATH
   source ~/.bashrc  # or ~/.zshrc
   
   # Verify installation
   uv --version
   ```

**Why uv is required:**
- All Python dependency management (`uv add/remove`)
- Virtual environment management
- Python execution (`uv run python`)
- Backend server operation
- Package installation and updates

**Without uv installed, NOTHING in this project will work correctly.**

### Package Management
- Use `uv add/remove` for Python dependencies, not manual edits to pyproject.toml
- Use `bun add/remove` for frontend dependencies, not manual package.json edits
- Always check if dependencies exist in the project before adding new ones

### Development Commands
- `./setup.sh` - Interactive environment setup and dependency installation
- `./watch.sh` - Start development servers with hot reloading (frontend:5173, backend:8000)
- `./fix.sh` - Format code (ruff for Python, prettier for TypeScript)
- `./deploy.sh` - Deploy to Databricks Apps

### 🚨 IMPORTANT: NEVER RUN THE SERVER MANUALLY 🚨

**ALWAYS use the watch script with nohup and logging:**

```bash
# Start development servers (REQUIRED COMMAND)
nohup ./watch.sh > /tmp/databricks-app-watch.log 2>&1 &

# Or for production mode
nohup ./watch.sh --prod > /tmp/databricks-app-watch.log 2>&1 &
```

**NEVER run uvicorn or the server directly!** Always use `./watch.sh` as it:
- Configures environment variables properly
- Starts both frontend and backend correctly
- Generates TypeScript client automatically
- Handles authentication setup
- Provides proper logging and error handling

### 🚨 PYTHON EXECUTION RULE 🚨

**NEVER run `python` directly - ALWAYS use `uv run`:**

```bash
# ✅ CORRECT - Always use uv run
uv run python script.py
uv run uvicorn server.app:mcp_asgi_app
uv run scripts/make_fastapi_client.py

# ❌ WRONG - Never use python directly
python script.py
uvicorn server.app:app
python scripts/make_fastapi_client.py
```

### 🚨 DATABRICKS CLI EXECUTION RULE 🚨

**IMPORTANT: Databricks CLI Installation Required**
If you don't have the Databricks CLI installed or it's outdated, **ALWAYS ask the user before installing.** **Requires version 0.260.0 or higher:**

**Installation Process:**
1. First check if CLI exists and version: `databricks version`
2. If missing or outdated, **ASK USER PERMISSION** before installing
3. Only after user approval, install using official installer
4. Verify installation worked correctly

```bash
# Check current version (if installed)
databricks version

# If user approves installation, use the official installer (REQUIRED - ensures latest version)
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# Verify version is 0.260.0+
databricks version
```

**NEVER run `databricks` CLI directly - ALWAYS prefix with environment setup:**

```bash
# ✅ CORRECT - Always source .env.local first
source .env.local && export DATABRICKS_HOST && export DATABRICKS_TOKEN && databricks current-user me
source .env.local && export DATABRICKS_HOST && export DATABRICKS_TOKEN && databricks apps list
source .env.local && export DATABRICKS_HOST && export DATABRICKS_TOKEN && databricks workspace list /

# ❌ WRONG - Never use databricks CLI directly
databricks current-user me
databricks apps list
databricks workspace list /
```

**Why this is required:**
- Ensures environment variables are loaded from .env.local
- Exports authentication variables to environment
- Prevents authentication failures and missing configuration

### Claude Natural Language Commands
Claude understands natural language commands for common development tasks:

**Development Lifecycle:**
- "start the devserver" → Runs `./watch.sh` in background with logging
- "kill the devserver" → Stops all background development processes
- "fix the code" → Runs `./fix.sh` to format Python and TypeScript code
- "deploy the app" → Runs `./deploy.sh` to deploy to Databricks Apps

**Development Tasks:**
- "add a new API endpoint" → Creates FastAPI routes with proper patterns
- "create a new React component" → Builds UI components using shadcn/ui
- "debug this error" → Analyzes logs and fixes issues
- "install [package]" → Adds dependencies using uv (Python) or bun (frontend)
- "generate the TypeScript client" → Regenerates API client from OpenAPI spec
- "open the UI in playwright" → Opens the frontend app in Playwright browser for testing
- "open app" → Gets app URL from `./app_status.sh` and opens it with `open {url}`

### Implementation Validation Workflow
**During implementation, ALWAYS:**
1. **Start development server first**: `nohup ./watch.sh > /tmp/databricks-app-watch.log 2>&1 &`
2. **Open app with Playwright** to see current state before changes
3. **After each implementation step:**
   - Check logs: `tail -f /tmp/databricks-app-watch.log`
   - Use Playwright to verify UI changes are working
   - Take snapshots to confirm features render correctly
   - Test user interactions and API calls
4. **🚨 CRITICAL: FastAPI Endpoint Verification**
   - **IMPORTANT: After adding ANY new FastAPI endpoint, MUST curl the endpoint to verify it works**
   - **NEVER move on to the next step until the endpoint is verified with curl**
   - **Example verification commands:**
     ```bash
     # Test GET endpoint
     curl -s http://localhost:8000/api/new-endpoint | jq
     
     # Test POST endpoint
     curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' http://localhost:8000/api/new-endpoint | jq
     ```
   - **Show the curl response to confirm the endpoint works correctly**
   - **If the endpoint fails, debug and fix it before proceeding**
5. **Install Playwright if needed**: `claude mcp add playwright npx '@playwright/mcp@latest'`
6. **Iterative validation**: Test each feature before moving to next step

**This ensures every implementation step is validated and working before proceeding.**

### Development Server
- **ALWAYS** run `./watch.sh` with nohup in background and log to file for debugging
- Watch script automatically runs in background and logs to `/tmp/databricks-app-watch.log`
- Frontend runs on http://localhost:5173
- Backend runs on http://localhost:8000
- API docs available at http://localhost:8000/docs
- Supports hot reloading for both frontend and backend
- Automatically generates TypeScript client from FastAPI OpenAPI spec
- **Check logs**: `tail -f /tmp/databricks-app-watch.log`
- **Stop processes**: `pkill -f "watch.sh"` or check PID file

### Code Quality
- Use `./fix.sh` for code formatting before commits
- Python: ruff for formatting and linting, ty for type checking
- TypeScript: prettier for formatting, ESLint for linting
- Type checking with TypeScript and ty (Python)

### API Development
- FastAPI automatically generates OpenAPI spec
- TypeScript client is auto-generated from OpenAPI spec
- Test endpoints with curl or FastAPI docs
- Check server logs after requests
- Verify response includes expected fields

### Databricks API Integration
- **ALWAYS** reference `docs/databricks_apis/` documentation when implementing Databricks features
- Use `docs/databricks_apis/databricks_sdk.md` for workspace, cluster, and SQL operations
- Use `docs/databricks_apis/mlflow_genai.md` for AI agent and LLM functionality
- Use `docs/databricks_apis/model_serving.md` for model serving endpoints and inference
- Use `docs/databricks_apis/workspace_apis.md` for file operations and directory management
- Follow the documented patterns and examples for proper API usage
- Check official documentation links in each API guide for latest updates

### Frontend Development
- Use shadcn/ui components for consistent UI
- Follow React Query patterns for API calls
- Use TypeScript strictly - no `any` types
- Import from auto-generated client: `import { apiClient } from '@/fastapi_client'`
- Client uses shadcn/ui components with proper TypeScript configuration
- shadcn components must be added with: npx shadcn@latest add <component-name>

### Testing Methodology
- Test API endpoints using FastAPI docs interface
- Use browser dev tools for frontend debugging
- Check network tab for API request/response inspection
- Verify console for any JavaScript errors

### Deployment
- Use `./deploy.sh` for Databricks Apps deployment
- Automatically builds frontend and generates requirements.txt
- Configures app.yaml with environment variables
- Verifies deployment through Databricks CLI
- **IMPORTANT**: After deployment, monitor `/logz` endpoint of your Databricks app to check for installation issues
- App logs are available at: `https://<app-url>/logz` (visit in browser - requires OAuth authentication)

### Environment Configuration
- Use `.env.local` for local development configuration
- Set environment variables and Databricks credentials
- Never commit `.env.local` to version control
- Use `./setup.sh` to create and update environment configuration

### Debugging Tips
- Verify environment variables are set correctly
- Use FastAPI docs for API testing: http://localhost:8000/docs
- Check browser console for frontend errors
- Use React Query DevTools for API state inspection
- **Check watch logs**: `tail -f /tmp/databricks-app-watch.log` for all development server output
- **Check process status**: `ps aux | grep databricks-app` or check PID file at `/tmp/databricks-app-watch.pid`
- **Force stop**: `kill $(cat /tmp/databricks-app-watch.pid)` or `pkill -f watch.sh`

### Key Files
- `server/app.py` - FastAPI application entry point
- `server/routers/` - API endpoint routers
- `client/src/App.tsx` - React application entry point
- `client/src/pages/` - React page components
- `scripts/make_fastapi_client.py` - TypeScript client generator
- `pyproject.toml` - Python dependencies and project configuration
- `client/package.json` - Frontend dependencies and scripts
- `claude_scripts/` - Test scripts created by Claude for testing functionality

### API Documentation
- `docs/databricks_apis/` - Comprehensive API documentation for Databricks integrations
- `docs/databricks_apis/databricks_sdk.md` - Databricks SDK usage patterns
- `docs/databricks_apis/mlflow_genai.md` - MLflow GenAI for AI agents
- `docs/databricks_apis/model_serving.md` - Model serving endpoints and inference
- `docs/databricks_apis/workspace_apis.md` - Workspace file operations

### Documentation Files
- `docs/product.md` - Product requirements document (created during /dba workflow)
- `docs/design.md` - Technical design document (created during /dba workflow)
- These files are generated through iterative collaboration with the user during the /dba command

### Common Issues
- If TypeScript client is not found, run the client generation script manually
- If hot reload not working, restart `./watch.sh`
- If dependencies missing, run `./setup.sh` to reinstall

### MCP (Model Context Protocol) Integration

**IMPORTANT: The server must support BOTH HTTP homepage AND MCP over HTTP simultaneously.**

#### MCP Setup and Configuration
- **ALWAYS use absolute paths when adding MCP servers** because the command can be run from anywhere:
  ```bash
  # ✅ CORRECT - Use absolute path
  claude mcp add databricks-proxy /Users/nikhil.thorat/emu/mcp-commands-databricks-app/mcp_databricks_client.py
  
  # ❌ WRONG - Never use relative paths
  claude mcp add databricks-proxy ./mcp_databricks_client.py
  ```

#### MCP Testing Workflow
**End-to-end testing process for MCP integration:**

1. **Add the MCP server to Claude CLI:**
   ```bash
   claude mcp add databricks-proxy /Users/nikhil.thorat/emu/mcp-commands-databricks-app/mcp_databricks_client.py
   ```

2. **Test MCP availability:**
   ```bash
   # Test if MCP tools are available
   echo "list the mcp prompts and tools" | claude
   ```

3. **Check MCP logs for debugging:**
   ```bash
   # Find MCP log directory (created by Claude CLI)
   ls -la ~/Library/Caches/claude-cli-nodejs/-Users-nikhil-thorat-emu-mcp-commands-databricks-app/mcp-logs-databricks-proxy/
   
   # Read the latest log file
   cat ~/Library/Caches/claude-cli-nodejs/-Users-nikhil-thorat-emu-mcp-commands-databricks-app/mcp-logs-databricks-proxy/$(ls -t ~/Library/Caches/claude-cli-nodejs/-Users-nikhil-thorat-emu-mcp-commands-databricks-app/mcp-logs-databricks-proxy/ | head -1)
   ```

   **Log locations from actual testing:**
   - MCP logs: `~/Library/Caches/claude-cli-nodejs/-Users-nikhil-thorat-emu-mcp-commands-databricks-app/mcp-logs-databricks-proxy/`
   - Log files are timestamped like: `mcp-2025-07-22T00-14-48-872Z.log`
   - Logs contain detailed MCP communication including tool discovery and execution

4. **Verify both HTTP and MCP work simultaneously:**
   - HTTP Homepage: `http://localhost:5176` (or port shown in watch logs)
   - MCP Discovery: Available through Claude CLI when MCP server is added
   - Both must work at the same time without conflicts

#### MCP Architecture in this App
- FastAPI app serves both regular HTTP endpoints and MCP functionality
- MCP server is integrated using FastMCP library
- MCP tools are mounted at `/mcp` path with SSE support
- Client proxy (`mcp_databricks_client.py`) connects to deployed app or local server
- OAuth authentication handled automatically for deployed apps

### Testing MCP Servers
When testing MCP server connections, use this trick:
```bash
# Check if MCP server is connected and list available commands
echo "list your mcp commands" | claude

# Check specific MCP server prompts
echo "What MCP prompts are available from databricks-mcp?" | claude
```

If the MCP server doesn't respond:
1. Check Claude logs: `tail -f ~/Library/Logs/Claude/*.log`
2. Check MCP logs in cache directory
3. Verify the proxy command works standalone
4. Ensure the app is deployed and accessible

### Writing Effective MCP Prompts

**IMPORTANT: MCP prompts should be detailed and actionable, not short and vague.**

MCP prompts are stored in the `prompts/` directory as Markdown files. When Claude receives these prompts, they should provide clear, specific instructions about what to do immediately.

#### Best Practices for MCP Prompts:

1. **Be Explicit and Detailed**: Instead of "List files", write detailed instructions like:
   ```markdown
   # Directory Contents Analysis
   
   **IMMEDIATE ACTION REQUIRED:** Execute the ls command right now to display all files and directories.
   
   You must run this exact command immediately:
   ```bash
   ls -la
   ```
   
   **What this command does:**
   - `ls` lists directory contents
   - `-l` shows detailed information (permissions, size, date modified)
   - `-a` shows ALL files including hidden files
   ```

2. **Use Action-Oriented Language**: 
   - ✅ "Execute this command now"
   - ✅ "Run the following immediately"
   - ✅ "You must perform this action"
   - ❌ "You can list files"
   - ❌ "Consider running ls"

3. **Provide Context and Explanation**: Include:
   - What the command/action does
   - Why it's important
   - What output to expect
   - How to interpret results

4. **Specify Exact Commands**: Always provide the complete, copy-pasteable command rather than general instructions.

5. **Use Clear Structure**: 
   - Start with clear action requirement
   - Provide exact command in code block
   - Explain what it does
   - Explain why it matters

#### Example Transformation:

**Bad (vague):**
```markdown
Use ping to test connectivity
```

**Good (detailed and actionable):**
```markdown
# Test Network Connectivity

**IMMEDIATE ACTION REQUIRED:** Run the ping command right now to test network connectivity to Google.

You must execute this exact command immediately:
```bash
ping -c 4 google.com
```

**What this does:**
- Tests if your system can reach google.com
- Sends 4 ping packets (-c 4 flag limits to 4 pings)
- Shows response times and packet loss statistics
- Confirms internet connectivity and DNS resolution

**Execute the ping command now using the Bash tool.**
```

### Databricks App Testing and Debugging

The project includes two powerful clients for testing and debugging deployed Databricks apps:

#### HTTP API Client (dba_client.py)

Test your deployed app's API endpoints with authenticated requests:

```bash
# Test user authentication and get user info
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/user/me

# Get MCP server information
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/mcp_info/info

# Test MCP discovery endpoint
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/mcp_info/discovery

# Make POST requests with JSON data
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/data POST '{"key":"value"}'

# Test any custom endpoint
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/custom/endpoint
```

**Features:**
- Automatic Databricks CLI OAuth authentication
- Supports GET, POST, PUT, DELETE methods
- Token caching and validation
- Uses environment variables from `.env.local`
- Detailed debug output showing token usage

#### WebSocket Log Streaming Client (dba_logz.py)

Stream live logs from your deployed Databricks app for real-time debugging:

```bash
# Stream all logs for 30 seconds (default)
uv run python dba_logz.py https://your-app.aws.databricksapps.com

# Stream logs for a specific duration
uv run python dba_logz.py https://your-app.aws.databricksapps.com --duration 10

# Filter logs with search query
uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "ERROR" --duration 60

# Search for specific API calls
uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "/api/mcp" --duration 30

# Monitor startup logs
uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "FastAPI" --duration 15
```

**Features:**
- Real-time WebSocket connection to `/logz/stream`
- Optional search filtering with regex support
- Configurable streaming duration
- Automatic OAuth authentication
- Structured JSON log output with timestamps

#### Authentication Setup

Both clients use your existing Databricks CLI authentication:

```bash
# Ensure you're authenticated (both clients will check this automatically)
source .env.local && export DATABRICKS_HOST && export DATABRICKS_TOKEN && databricks current-user me
```

The clients automatically:
- Load environment variables from `.env.local`
- Use your Databricks CLI profile or host configuration
- Handle token refresh if needed
- Provide detailed authentication debug output

#### Debugging Workflow

1. **Test basic connectivity:**
   ```bash
   uv run python dba_client.py https://your-app.aws.databricksapps.com /api/user/me
   ```

2. **Verify MCP functionality:**
   ```bash
   uv run python dba_client.py https://your-app.aws.databricksapps.com /api/mcp_info/info
   ```

3. **Monitor live logs during testing:**
   ```bash
   uv run python dba_logz.py https://your-app.aws.databricksapps.com --duration 60 &
   # In another terminal, test your app
   uv run python dba_client.py https://your-app.aws.databricksapps.com /api/some/endpoint
   ```

4. **Debug specific issues:**
   ```bash
   # Search for errors
   uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "ERROR|Failed|Exception"
   
   # Monitor specific endpoints
   uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "/api/mcp_info"
   ```

## MCP Debugging and Troubleshooting

### 🚨 CRITICAL: MCP Connection Debugging

**When MCP integration isn't working, use this systematic debugging approach:**

#### Step 1: Test Before Adding to Claude CLI

**CRITICAL: Always test your MCP connection locally before running `claude mcp add`**

```bash
# Go to the MCP proxy directory  
cd dba_mcp_proxy

# Test MCP connection and discover what tools are available
echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/list"}' | python mcp_client.py --databricks-host YOUR_DATABRICKS_HOST --databricks-app-url YOUR_APP_URL
```

**This should return a JSON response with available tools. Take note of the tool names.**

#### Step 2: Test Any Available Tool

**Pick any tool from the list and test it:**

```bash
# Generic pattern - replace TOOL_NAME with any tool from your list
echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/call", "params": {"name": "TOOL_NAME", "arguments": {}}}' | python mcp_client.py --databricks-host YOUR_DATABRICKS_HOST --databricks-app-url YOUR_APP_URL

# Example with a common tool (if it exists in your setup)
echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/call", "params": {"name": "health", "arguments": {}}}' | python mcp_client.py --databricks-host YOUR_DATABRICKS_HOST --databricks-app-url YOUR_APP_URL
```

#### Step 3: Log Verification Workflow

**CRITICAL: Verify requests are reaching your app by monitoring logs simultaneously:**

1. **Start log monitoring in one terminal:**
   ```bash
   # Monitor for MCP requests specifically
   uv run python dba_logz.py YOUR_APP_URL --search "/mcp" --duration 60
   ```

2. **In another terminal, make any MCP request:**
   ```bash
   cd dba_mcp_proxy
   echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/call", "params": {"name": "TOOL_NAME", "arguments": {}}}' | python mcp_client.py --databricks-host YOUR_DATABRICKS_HOST --databricks-app-url YOUR_APP_URL
   ```

3. **Verify log output shows the request:**
   ```
   📋 {"source":"APP","timestamp":1756142xxx,"message":"INFO: 127.0.0.1:xxxxx - \"POST /mcp/ HTTP/1.1\" 200 OK"}
   ```

**If you see the `/mcp` POST request at the same time you sent it, then you know you're in good shape!**

#### Step 4: Only After Local Testing Works - Add to Claude CLI

**Once Steps 1-3 work locally, then add to Claude CLI:**

```bash
# Get your app URL
export DATABRICKS_APP_URL=$(./app_status.sh | grep "App URL" | awk '{print $NF}')

# Add to Claude CLI (this runs the same uvx command you just tested)
claude mcp add YOUR_SERVER_NAME --scope user -- \
  uvx --refresh --from git+ssh://git@github.com/databricks-solutions/custom-mcp-databricks-app.git dba-mcp-proxy \
  --databricks-host $DATABRICKS_HOST \
  --databricks-app-url $DATABRICKS_APP_URL
```

**The key insight: The `claude mcp add` command runs the exact same `uvx --refresh --from...` command you can test locally first.**

### Common Issues and Solutions

#### Issue 1: "Connection refused" or timeout errors

**Diagnosis:**
```bash
# Test basic connectivity
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/user/me
```

**Solutions:**
- Verify app is deployed and running: `./app_status.sh`
- Check if app URL is correct in your command
- Ensure you're authenticated: `databricks current-user me`

#### Issue 2: "401 Unauthorized" errors

**Diagnosis:**
```bash
# Check authentication
source .env.local && export DATABRICKS_HOST && export DATABRICKS_TOKEN && databricks current-user me
```

**Solutions:**
- Re-authenticate: `databricks auth login --host $DATABRICKS_HOST`
- Verify environment variables in `.env.local`
- Check if your token has expired

#### Issue 3: MCP tools not found

**Diagnosis:**
```bash
# Test MCP endpoint directly
uv run python dba_client.py https://your-app.aws.databricksapps.com /api/mcp_info/discovery
```

**Solutions:**
- Redeploy the app: `./deploy.sh`
- Check app logs for startup errors: `uv run python dba_logz.py https://your-app.aws.databricksapps.com --search "ERROR|FastAPI" --duration 30`
- Verify MCP server is running on the app

#### Issue 4: SQL queries failing

**Symptoms:** `"No SQL warehouse ID provided"` or warehouse errors

**Diagnosis:**
```bash
# Check available warehouses
echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/call", "params": {"name": "list_warehouses", "arguments": {}}}' | python mcp_client.py --databricks-host YOUR_DATABRICKS_HOST --databricks-app-url YOUR_APP_URL
```

**Solutions:**
- Ensure you have at least one SQL warehouse running
- Set `DATABRICKS_SQL_WAREHOUSE_ID` in your app's environment
- Start a warehouse in the Databricks workspace UI

### Debug Command Reference

**Quick debugging commands:**

```bash
# Test MCP proxy connection
cd dba_mcp_proxy && echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/list"}' | python mcp_client.py --databricks-host $DATABRICKS_HOST --databricks-app-url $DATABRICKS_APP_URL

# Test HTTP client
uv run python dba_client.py $DATABRICKS_APP_URL /api/user/me

# Monitor logs for 30 seconds
uv run python dba_logz.py $DATABRICKS_APP_URL --duration 30

# Monitor MCP requests specifically
uv run python dba_logz.py $DATABRICKS_APP_URL --search "/mcp|MCP" --duration 60

# Test app health through MCP
cd dba_mcp_proxy && echo '{"jsonrpc": "2.0", "id": "test", "method": "tools/call", "params": {"name": "health", "arguments": {}}}' | python mcp_client.py --databricks-host $DATABRICKS_HOST --databricks-app-url $DATABRICKS_APP_URL
```

**Environment setup for debugging:**
```bash
# Load environment and test
source .env.local
export DATABRICKS_HOST
export DATABRICKS_TOKEN
export DATABRICKS_APP_URL=$(./app_status.sh | grep "App URL" | awk '{print $NF}')

# Verify all variables are set
echo "Host: $DATABRICKS_HOST"
echo "App URL: $DATABRICKS_APP_URL"
databricks current-user me
```

Remember: This is a development template focused on rapid iteration and modern tooling.