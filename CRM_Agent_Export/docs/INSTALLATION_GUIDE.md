# CRM Agent Installation Guide

## Prerequisites

- Node.js 18 or higher
- PostgreSQL 14 or higher  
- npm or yarn package manager

## Environment Setup

1. **Create Environment File**
```bash
cp .env.example .env
```

2. **Configure Environment Variables**
```env
# Database
DATABASE_URL=postgresql://username:password@host:port/database

# AI Services
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Studio Configuration  
STUDIO_NAME="Your Studio Name"
PUBLIC_SITE_BASE_URL=https://yourdomain.com
```

## Database Setup

1. **Install Dependencies**
```bash
npm install
```

2. **Initialize Database**
```bash
npm run db:push
```

3. **Verify Connection**
```bash
npm run db:status
```

## Agent Configuration

1. **Tool Registry Setup**
The agent automatically registers 74 tools on startup. Verify in logs:
```
📋 Registered 74 tools for CRM agent
✅ Tool registered: send_email
✅ Tool registered: create_lead
...
```

2. **Knowledge Base Setup**
Run initial knowledge base population:
```bash
npm run agent:setup-kb
```

## Development Server

Start the development server:
```bash
npm run dev
```

The agent will be available at:
- Web Interface: http://localhost:5000
- API Endpoints: http://localhost:5000/api/
- Agent Chat: http://localhost:5000/admin/crm-assistant

## Production Deployment

1. **Build Application**
```bash
npm run build
```

2. **Start Production Server**
```bash
npm start
```

## Verification Steps

1. **Check Agent Status**
Navigate to `/admin/crm-assistant` and verify the chat interface loads

2. **Test Basic Functionality**
Send a test message: "List all leads"

3. **Verify Database Connection**
Check that the agent can read/write to the database

## Troubleshooting

### Common Issues

**Agent Not Responding**
- Check API keys are correctly set
- Verify database connection
- Check server logs for errors

**Tool Registration Failures**
- Ensure all dependencies are installed
- Check file permissions
- Verify TypeScript compilation

**Database Connection Issues**
- Verify DATABASE_URL format
- Check PostgreSQL service is running
- Ensure database exists and is accessible

### Debug Mode

Enable debug logging:
```env
DEBUG_AGENT=true
DEBUG_OPENAI=true
```

### Support

For integration support or customization needs, refer to the technical documentation in `/docs/` or contact the development team.