# New Age Fotografie CRM - Professional Photography Studio Management System

## Overview
New Age Fotografie CRM is a full-stack web application designed as a comprehensive customer relationship management system for a professional photography studio. It streamlines business operations by offering client management, gallery showcasing, booking, invoicing, and various administrative functions through both customer-facing and administrative interfaces. The vision is to provide a robust platform for managing a photography business, supporting functions from client interaction to automated printing services.

## User Preferences
Preferred communication style: Simple, everyday language.

## System Architecture
The application is structured as a monorepo, separating client, server, and shared code.

### Technology Stack
- **Frontend**: React with TypeScript (Vite, Tailwind CSS, shadcn/ui)
- **Backend**: Express.js with TypeScript
- **Database**: PostgreSQL with Drizzle ORM (Neon Database)
- **Authentication**: Custom session-based authentication
- **Storage**: Local file storage with optional cloud integration
- **Deployment**: Configured for production with esbuild

### Frontend Architecture
- **Component Library**: shadcn/ui and Radix UI
- **State Management**: React Context API (e.g., AppContext, AuthContext)
- **Routing**: React Router
- **Form Handling**: React Hook Form with Zod validation
- **Data Fetching**: TanStack Query
- **Real-time Features**: Server-sent events and polling for live updates

### Backend Architecture
- **API Layer**: Express.js
- **Database Layer**: Drizzle ORM with PostgreSQL
- **Database**: Neon PostgreSQL (independent account with complete data migration)
- **Authentication**: Express session-based authentication
- **File Storage**: Local filesystem with structured organization
- **System Design**: Core focus on photography session management, digital file organization, invoice generation, and comprehensive CRM agent integration. Includes features like multi-view calendar displays, golden hour optimization, equipment conflict detection, and AI-powered analytics foundations. Comprehensive SEO optimization and meta tag generation are built-in. Multi-photographer SaaS template management system with premium tiers and automated template import is a core architectural decision.

### Database Architecture (August 24, 2025)
- **Neon-Only Strategy**: Complete migration to independent Neon account
- **Data Scope**: CRM clients (2,153), email messages (17,574), blog posts (1,596), knowledge base (486), SEO intelligence (72), invoicing, price lists, calendar events, and all business systems
- **Migration Ready**: supabase-COMPLETE-import.sql contains all 22,064 records for new Neon import
- **Supabase Removed**: All Supabase dependencies eliminated for streamlined Neon-only architecture
- **Connection**: Direct Neon PostgreSQL connection via Drizzle ORM

### CRM Agent System
A self-planning, knowledge-aware CRM agent system is integrated, offering autonomous capabilities. This includes:
- **Autonomous Planning & Execution**: The agent can plan and execute multi-step tasks, utilizing a comprehensive tool registry.
- **Guarded Write Enablement**: Supports `CREATE_LEAD`, `UPDATE_CLIENT`, `SEND_INVOICE`, and `SEND_EMAIL` operations with robust guardrails, approval workflows, and detailed audit logging.
- **Persistent Memory**: Maintains conversation history and context across sessions.
- **Knowledge Base**: Utilizes a `pgvector` knowledge base for semantic knowledge retrieval and self-diagnosis.
- **Tool Registry**: Over 60 tools are registered covering communication, search, billing, scheduling, products, files, content, analytics, administration, automation, and customer portal management.
- **AutoBlog System**: Integrated AI-powered content generation for blog posts, featuring real image analysis (GPT-4o Vision), sophisticated prompt engineering, and SEO optimization. Supports scheduled and immediate publishing.
- **Website Wizard**: Comprehensive website analysis capabilities including performance metrics, content scraping, and SEO insights.

### UI/UX Decisions
- Modern, professional design with purple accent colors matching company branding.
- Intuitive admin interface with clear navigation for various CRM functions.
- Photography-specific elements like comprehensive family portrait collages and curated galleries.
- Accessible components through Radix UI primitives.
- Mobile responsiveness for all pages.

## External Dependencies
- **Supabase**: Authentication, Real-time Database, File Storage.
- **Neon Database**: Serverless PostgreSQL hosting.
- **Stripe**: Payment processing for voucher sales.
- **Prodigi**: Print-on-demand fulfillment for gallery orders.
- **OpenAI**: GPT-4o for AI agent functionality (CRM operations, AutoBlog content generation, image analysis, language transcription via Whisper API).
- **Anthropic**: Claude 3.5 Sonnet (primary LLM with OpenAI fallback).
- **Nodemailer**: Email sending functionality via SMTP.
- **@radix-ui/**: Accessible UI components.
- **date-fns**: Date manipulation.
- **validator**: Email validation.
- **@extractus/article-extractor**: Content scraping for Website Wizard.
- **serpapi**, **keyword-extractor**: For SEO and competitive intelligence.
- **jsPDF**: For invoice PDF generation.
- **xlsx**: For Excel file import.