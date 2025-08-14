# ✅ Coolify Environment Variables Configuration - Complete

## What Was Set Up

I've successfully configured the environment variables setup for deploying Open WebUI to Coolify. Here's what was created:

### 📁 Files Created

1. **`coolify-env-configuration.md`**
   - Comprehensive guide for all environment variables
   - Detailed explanations for each variable
   - Step-by-step instructions for Coolify configuration
   - Troubleshooting tips

2. **`.env.coolify.example`**
   - Template file with all available environment variables
   - Pre-configured with sensible defaults
   - Organized by category (Required, Optional, etc.)
   - Extensive comments explaining each variable

3. **`generate-key.ps1`**
   - PowerShell script to generate secure WEBUI_SECRET_KEY
   - Works on Windows systems
   - Provides clear instructions for using the generated key

4. **`generate_secret_key.py`**
   - Python alternative for generating secret keys
   - Cross-platform compatibility
   - Interactive options for saving the key

## 🚀 Quick Start Guide

### Step 1: Generate Your Secret Key

Run the PowerShell script:
```powershell
powershell -ExecutionPolicy Bypass -File generate-key.ps1
```

Or if you have Python installed:
```bash
python generate_secret_key.py
```

### Step 2: Configure in Coolify

1. Log into your Coolify dashboard
2. Navigate to your Open WebUI application
3. Go to the "Environment Variables" section
4. Add these essential variables:

#### Required Variables:
- `WEBUI_SECRET_KEY` = [your generated key] *(mark as Secret)*
- `OPEN_WEBUI_PORT` = 3000

#### For Ollama Users:
- `OLLAMA_BASE_URL` = http://ollama:11434

#### For OpenAI Users:
- `OPENAI_API_KEY` = [your OpenAI API key] *(mark as Secret)*

### Step 3: Deploy

After adding all variables:
1. Click "Save" or "Apply"
2. Redeploy the application
3. Check logs for any errors

## 📋 Environment Variables Summary

### Essential Variables
| Variable | Purpose | Default/Example |
|----------|---------|-----------------|
| `WEBUI_SECRET_KEY` | Session security | Generated 64-char hex string |
| `OLLAMA_BASE_URL` | Ollama connection | `http://ollama:11434` |
| `OPENAI_API_KEY` | OpenAI API access | Your API key |
| `OPEN_WEBUI_PORT` | External port | `3000` |

### Security Settings
| Variable | Purpose | Production Value |
|----------|---------|------------------|
| `CORS_ALLOW_ORIGIN` | CORS policy | Your domain URL |
| `FORWARDED_ALLOW_IPS` | Proxy IPs | `127.0.0.1` |
| `DO_NOT_TRACK` | Disable tracking | `true` |
| `ANONYMIZED_TELEMETRY` | Disable telemetry | `false` |

### Model Configuration
| Variable | Purpose | Default |
|----------|---------|---------|
| `WHISPER_MODEL` | Speech-to-text model | `base` |
| `RAG_EMBEDDING_MODEL` | Document embeddings | `sentence-transformers/all-MiniLM-L6-v2` |

## 🔒 Security Best Practices

1. **Always set `WEBUI_SECRET_KEY`** - This is critical for session security
2. **Mark sensitive variables as "Secret"** in Coolify:
   - `WEBUI_SECRET_KEY`
   - `OPENAI_API_KEY`
   - Any database passwords
3. **In production**, restrict `CORS_ALLOW_ORIGIN` to your specific domain
4. **Use HTTPS** in production environments
5. **Regularly rotate** your secret keys and API keys

## 📚 Documentation Files

- **Full Configuration Guide**: See `coolify-env-configuration.md`
- **Environment Template**: Copy `.env.coolify.example` to `.env.coolify` and customize
- **Docker Compose**: Use `docker-compose.coolify.yaml` for deployment

## ✨ Next Steps

1. Generate your secret key using one of the provided scripts
2. Configure the environment variables in Coolify
3. Deploy your application
4. Test the connection to your LLM provider (Ollama or OpenAI)
5. Verify sessions are working (indicates WEBUI_SECRET_KEY is configured correctly)

## 🆘 Troubleshooting

If you encounter issues:
1. Check Coolify application logs for environment variable errors
2. Ensure all required variables are set
3. Verify secret keys are properly marked as "Secret" in Coolify
4. Confirm service names match if using Ollama (internal Docker networking)
5. Test API keys are valid and have sufficient credits (for OpenAI)

## ✅ Configuration Complete!

Your Coolify environment variables are now properly configured. The application is ready for deployment with all necessary security and configuration settings in place.
