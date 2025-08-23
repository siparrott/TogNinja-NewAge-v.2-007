# CRM Agent System Export

## Overview

This export contains the complete Self-Planning Knowledge-Aware CRM Agent system that was developed for New Age Fotografie. The agent provides autonomous capabilities for database operations, customer interaction, and business process automation.

## Key Features

- **Self-Planning Autonomous Agent**: Can plan and execute multi-step tasks independently
- **Knowledge-Aware System**: Utilizes pgvector knowledge base for semantic search and self-diagnosis
- **Guarded Write Operations**: Secure database operations with approval workflows and audit logging
- **74 Registered Tools**: Comprehensive tool registry covering all business functions
- **Real-time Chat Interface**: User can interact with agent through dashboard chat system
- **Database Integration**: Full PostgreSQL/Drizzle ORM integration

## Architecture

### Core Components

1. **Agent System** (`/agent/`)
   - Main agent orchestration and reasoning logic
   - Tool registry with 74+ business tools
   - Knowledge base integration
   - Memory and context management

2. **Server Components** (`/server/`)
   - CRM agent routes and API endpoints
   - Database connection and storage layer
   - Tool execution and security layer

3. **Client Interface** (`/client/`)
   - Chat components for user interaction
   - CRM Operations Assistant interface
   - Real-time communication with agent

4. **Database Layer** (`/database/`)
   - PostgreSQL schema definitions
   - Drizzle ORM configuration
   - Storage abstraction layer

5. **Configuration** (`/config/`)
   - Environment setup
   - Package dependencies
   - Database configuration

## Key Capabilities

### Autonomous Operations
- CREATE_LEAD, UPDATE_CLIENT, SEND_INVOICE, SEND_EMAIL
- Multi-step task planning and execution
- Self-diagnosis and error recovery
- Context-aware decision making

### Knowledge Integration
- Semantic search across business data
- Real-time information retrieval
- Business intelligence and analytics
- Customer interaction history

### Security Features
- Approval workflows for sensitive operations
- Comprehensive audit logging
- Role-based access control
- Secure API authentication

## Database Schema

The system uses PostgreSQL with the following key tables:
- `leads` - Customer lead management
- `clients` - Client information and history
- `invoices` - Billing and payment tracking
- `sessions` - Photography session scheduling
- `knowledge_base` - Agent knowledge storage (pgvector)
- `agent_interactions` - Conversation history and context

## Installation Requirements

### Dependencies
- Node.js 18+
- PostgreSQL 14+
- TypeScript
- Drizzle ORM
- Express.js
- React 18+

### Environment Variables
```
DATABASE_URL=postgresql://...
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

## Setup Instructions

1. Install dependencies: `npm install`
2. Configure environment variables
3. Setup PostgreSQL database
4. Run migrations: `npm run db:push`
5. Start development server: `npm run dev`

## File Structure

```
CRM_Agent_Export/
├── agent/                  # Core agent system
│   ├── tools/             # 74+ business tools
│   ├── integrations/      # External service integrations
│   └── memory/            # Context and knowledge management
├── server/                # Backend API and routes
│   ├── routes/           # CRM agent endpoints
│   └── database files    # DB connection and storage
├── client/               # Frontend chat interfaces
│   └── chat/            # Agent interaction components
├── database/            # Database schema and config
├── shared/              # Shared types and schemas
├── config/              # Configuration files
└── docs/                # Documentation
```

## Usage

The CRM agent can be accessed through:
1. **Dashboard Chat**: Direct interaction via web interface
2. **API Endpoints**: Programmatic access via REST API
3. **Tool Registry**: Direct tool execution for specific tasks

## Tools Available

The agent has access to 74 registered tools including:
- Communication (email, SMS, notifications)
- CRM operations (leads, clients, invoices)
- Scheduling and calendar management
- File and document management
- Analytics and reporting
- Automation workflows
- Customer portal management

## Technical Notes

- Uses Claude 3.5 Sonnet as primary LLM with OpenAI GPT-4o fallback
- Implements sophisticated prompt engineering for task planning
- Maintains persistent conversation history and context
- Supports real-time updates and notifications
- Includes comprehensive error handling and recovery

## Integration Notes

To integrate this CRM agent into another application:
1. Adapt the database schema to your existing tables
2. Update environment configuration
3. Modify tool registry for your business needs
4. Customize the chat interface components
5. Configure authentication and security settings

## Support

This system was developed specifically for New Age Fotografie CRM requirements. Adaptation for other use cases may require modifications to the tool registry, database schema, and business logic.