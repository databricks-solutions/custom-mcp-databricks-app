---
description: "Comprehensive debugging for development and deployment issues"
---

# Debug Your Databricks App

I'll help you debug issues with your Databricks app by running comprehensive diagnostics and providing solutions.

## What I'll do:

1. **System Health Check** - Verify all tools and dependencies
2. **Development Environment Debug** - Check local development setup
3. **Authentication Validation** - Test Databricks connectivity
4. **Local App Testing** - Run app locally to identify issues
5. **Deployment Status Analysis** - Check deployed app health
6. **Provide Solutions** - Give specific fixes for identified problems

## Debugging Workflow

**Step 1: System Health Check**
```bash
# Check required tools
uv --version
bun --version
databricks --version
python --version

# Check project structure
ls -la

# Verify key files exist
ls -la .env.local
ls -la server/app.py
ls -la client/package.json
```

**Step 2: Development Environment Debug**
```bash
# Check development server status
ps aux | grep databricks-app

# Check logs
tail -20 /tmp/databricks-app-watch.log

# Check PID file
cat /tmp/databricks-app-watch.pid
```

**Step 3: Authentication Debug**
```bash
# Test authentication
databricks current-user me

# With profile if configured
databricks current-user me --profile "$DATABRICKS_CONFIG_PROFILE"

# Check .env.local configuration
cat .env.local
```

**Step 4: Local App Testing**
```bash
# Run app locally with debug mode
./run_app_local.sh --verbose
```

**Step 5: Deployment Status Analysis**
```bash
# Check app status
./app_status.sh --verbose

# Check workspace files
databricks workspace list "$DBA_SOURCE_CODE_PATH"
```

## Common Issues and Solutions

### Development Server Issues

**Problem: Port already in use**
```bash
# Kill processes on ports 3000/8000
pkill -f "uvicorn server.app:app"
pkill -f "vite"
pkill -f "node.*3000"
```

**Problem: Development server won't start**
```bash
# Clean restart
kill $(cat /tmp/databricks-app-watch.pid) || pkill -f watch.sh
rm -f /tmp/databricks-app-watch.pid
rm -f /tmp/databricks-app-watch.log
nohup ./watch.sh > /tmp/databricks-app-watch.log 2>&1 &
```

### Import and Build Issues

**Problem: TypeScript client missing**
```bash
# Regenerate TypeScript client
uv run python scripts/make_fastapi_client.py
```

**Problem: `@/lib/utils` import error**
```bash
# Check if utils.ts exists in correct location
ls -la src/lib/utils.ts
ls -la client/src/lib/utils.ts

# Copy if missing
mkdir -p src/lib
cp client/src/lib/utils.ts src/lib/utils.ts
```

**Problem: Python import errors**
```bash
# Check virtual environment
uv run python -c "import sys; print(sys.path)"

# Reinstall dependencies
uv sync
```

### Authentication Issues

**Problem: Databricks authentication failed**
```bash
# Test different auth methods
databricks current-user me
databricks current-user me --profile "$DATABRICKS_CONFIG_PROFILE"

# Reconfigure authentication
./setup.sh
```

**Problem: Invalid credentials**
```bash
# Check token validity (for PAT)
curl -H "Authorization: Bearer $DATABRICKS_TOKEN" \
     "$DATABRICKS_HOST/api/2.0/current-user"

# Re-authenticate
databricks auth login --host "$DATABRICKS_HOST"
```

### Deployment Issues

**Problem: App deployment failed**
```bash
# Check app status
./app_status.sh --verbose

# Test locally first
./run_app_local.sh --verbose

# Check deployment logs
# Visit app URL + /logz in browser
```

**Problem: App not running after deployment**
```bash
# Get detailed app info
databricks apps get "$DATABRICKS_APP_NAME"

# Check workspace sync
databricks workspace list "$DBA_SOURCE_CODE_PATH"

# Redeploy with verbose output
./deploy.sh --verbose
```

### Build and Compilation Issues

**Problem: Frontend build fails**
```bash
# Check frontend dependencies
cd client
bun install

# Build manually
bun run build

# Check for TypeScript errors
bun run type-check
```

**Problem: Backend startup fails**
```bash
# Test backend manually
uv run uvicorn server.app:mcp_asgi_app --reload

# Check Python dependencies
uv run python -c "import fastapi; print('FastAPI OK')"
uv run python -c "import databricks; print('Databricks SDK OK')"
```

## Advanced Debugging

### Log Analysis
```bash
# Development logs
tail -f /tmp/databricks-app-watch.log

# Filter for errors
grep -i error /tmp/databricks-app-watch.log

# Check for specific issues
grep -i "port.*use" /tmp/databricks-app-watch.log
```

### Network Debugging
```bash
# Check if ports are available
netstat -an | grep :3000
netstat -an | grep :8000

# Test API connectivity
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

### File System Issues
```bash
# Check permissions
ls -la .env.local
ls -la scripts/

# Check disk space
df -h

# Check file integrity
file server/app.py
file client/package.json
```

## Nuclear Reset (Last Resort)

If all else fails, here's a complete reset:

```bash
# Stop everything
pkill -f watch.sh
pkill -f uvicorn
pkill -f vite

# Clean up files
rm -f /tmp/databricks-app-watch.pid
rm -f /tmp/databricks-app-watch.log
rm -f /tmp/local-app-test.log

# Reinstall dependencies
uv sync
cd client && bun install && cd ..

# Reconfigure environment
./setup.sh

# Test locally
./run_app_local.sh

# Start fresh
./watch.sh
```

## Getting Help

If you're still having issues:

1. **Check the logs** - Always start with `/tmp/databricks-app-watch.log`
2. **Test locally** - Use `./run_app_local.sh --verbose`
3. **Verify authentication** - Test with `databricks current-user me`
4. **Check app status** - Use `./app_status.sh --verbose`
5. **Visit `/logz`** - Check deployment logs in browser

## Success Indicators

Your app is working when:
- ✅ Development servers start without errors
- ✅ Frontend loads at http://localhost:3000
- ✅ Backend responds at http://localhost:8000
- ✅ API docs work at http://localhost:8000/docs
- ✅ Authentication tests pass
- ✅ App deploys successfully
- ✅ Deployed app shows "RUNNING" status

You've got this! 🐛➡️✅