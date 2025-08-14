# Coolify Environment Variables Configuration for Open WebUI

This guide provides instructions for configuring environment variables in Coolify for your Open WebUI deployment.

## Required Environment Variables

### 1. WEBUI_SECRET_KEY (Required for Security)
**Purpose**: Secret key for securing sessions and cookies
**Example**: Generate a secure random string (32+ characters)
```bash
# Generate on Linux/Mac:
openssl rand -hex 32

# Or use Python:
python -c "import secrets; print(secrets.token_hex(32))"
```
**Coolify Setting**: 
- Variable Name: `WEBUI_SECRET_KEY`
- Value: Your generated secret key

### 2. Connection Configuration

#### Option A: Using Ollama (Local LLM)
If you're using Ollama for local LLM:

**OLLAMA_BASE_URL**
- Variable Name: `OLLAMA_BASE_URL`
- Default Value: `http://ollama:11434`
- Note: If Ollama is running as a separate service in Coolify, use the internal service name

#### Option B: Using OpenAI API
If you're using OpenAI's API:

**OPENAI_API_KEY**
- Variable Name: `OPENAI_API_KEY`
- Value: Your OpenAI API key from https://platform.openai.com/api-keys

**OPENAI_API_BASE_URL** (Optional)
- Variable Name: `OPENAI_API_BASE_URL`
- Value: Leave empty for default OpenAI endpoint, or specify custom endpoint

### 3. Port Configuration

**OPEN_WEBUI_PORT**
- Variable Name: `OPEN_WEBUI_PORT`
- Default Value: `3000`
- Note: External port for accessing the UI (internal port is always 8080)

## Optional Environment Variables

### Security & CORS Settings

**CORS_ALLOW_ORIGIN**
- Variable Name: `CORS_ALLOW_ORIGIN`
- Default Value: `*`
- Production Recommendation: Set to your actual domain (e.g., `https://yourdomain.com`)

**FORWARDED_ALLOW_IPS**
- Variable Name: `FORWARDED_ALLOW_IPS`
- Default Value: `*`
- Production Recommendation: Set to `127.0.0.1` for proxy configuration

### Privacy & Telemetry

**DO_NOT_TRACK**
- Variable Name: `DO_NOT_TRACK`
- Recommended Value: `true`

**SCARF_NO_ANALYTICS**
- Variable Name: `SCARF_NO_ANALYTICS`
- Recommended Value: `true`

**ANONYMIZED_TELEMETRY**
- Variable Name: `ANONYMIZED_TELEMETRY`
- Recommended Value: `false`

### Model Configuration

**WHISPER_MODEL**
- Variable Name: `WHISPER_MODEL`
- Default Value: `base`
- Options: `tiny`, `base`, `small`, `medium`, `large`

**RAG_EMBEDDING_MODEL**
- Variable Name: `RAG_EMBEDDING_MODEL`
- Default Value: `sentence-transformers/all-MiniLM-L6-v2`

### Application Settings

**ENV**
- Variable Name: `ENV`
- Recommended Value: `prod` for production

**PORT**
- Variable Name: `PORT`
- Value: `8080` (internal port, don't change unless necessary)

## How to Add Environment Variables in Coolify

1. **Navigate to your Open WebUI application** in Coolify dashboard

2. **Go to Environment Variables section**:
   - Click on your application
   - Navigate to "Environment" or "Environment Variables" tab

3. **Add each variable**:
   - Click "Add Environment Variable"
   - Enter the Variable Name (e.g., `WEBUI_SECRET_KEY`)
   - Enter the Value
   - Mark as "Secret" for sensitive values like API keys and secret keys
   - Save the variable

4. **Essential variables to configure first**:
   ```
   WEBUI_SECRET_KEY=<your-generated-secret>
   OLLAMA_BASE_URL=http://ollama:11434  (if using Ollama)
   OPENAI_API_KEY=<your-api-key>  (if using OpenAI)
   OPEN_WEBUI_PORT=3000
   ```

5. **After adding all variables**:
   - Click "Save" or "Apply"
   - Redeploy the application for changes to take effect

## Example Complete Configuration

### For Ollama Setup:
```env
WEBUI_SECRET_KEY=your-32-character-secret-key-here
OLLAMA_BASE_URL=http://ollama:11434
OPEN_WEBUI_PORT=3000
CORS_ALLOW_ORIGIN=https://your-domain.com
FORWARDED_ALLOW_IPS=127.0.0.1
DO_NOT_TRACK=true
SCARF_NO_ANALYTICS=true
ANONYMIZED_TELEMETRY=false
ENV=prod
WHISPER_MODEL=base
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

### For OpenAI Setup:
```env
WEBUI_SECRET_KEY=your-32-character-secret-key-here
OPENAI_API_KEY=sk-your-openai-api-key-here
OPEN_WEBUI_PORT=3000
CORS_ALLOW_ORIGIN=https://your-domain.com
FORWARDED_ALLOW_IPS=127.0.0.1
DO_NOT_TRACK=true
SCARF_NO_ANALYTICS=true
ANONYMIZED_TELEMETRY=false
ENV=prod
WHISPER_MODEL=base
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

## Verification

After configuring and redeploying:

1. Check application logs in Coolify for any environment variable errors
2. Access your Open WebUI at the configured port
3. Test the connection to your LLM provider (Ollama or OpenAI)
4. Verify that sessions are maintained (indicates WEBUI_SECRET_KEY is working)

## Troubleshooting

- **Connection refused to Ollama**: Ensure Ollama service is running and the service name in OLLAMA_BASE_URL matches Coolify's internal service name
- **OpenAI API errors**: Verify your API key is correct and has sufficient credits
- **Session issues**: Ensure WEBUI_SECRET_KEY is set and persistent across deployments
- **Port conflicts**: Check that OPEN_WEBUI_PORT isn't already in use

## Security Best Practices

1. Always set a strong `WEBUI_SECRET_KEY`
2. Store API keys as secrets in Coolify (mark as "Secret" when adding)
3. In production, restrict `CORS_ALLOW_ORIGIN` to your specific domain
4. Set `FORWARDED_ALLOW_IPS` to `127.0.0.1` when using a reverse proxy
5. Regularly rotate your secret keys and API keys
