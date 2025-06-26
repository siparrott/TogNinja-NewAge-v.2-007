# VoucherPlus - Photography Business Platform

## Overview

VoucherPlus is a comprehensive photography business management platform built with React and TypeScript. The application serves as both a customer-facing voucher marketplace and an administrative CRM system for managing photography services, clients, galleries, and business operations.

## System Architecture

### Frontend Architecture
- **React 18** with TypeScript for type safety
- **Vite** as the build tool and development server
- **React Router DOM** for client-side routing
- **Tailwind CSS** for styling with custom Poppins font
- **Framer Motion** for animations and micro-interactions
- **Context API** for state management (Auth, Cart, Language, App)

### Backend Architecture
- **Supabase** as the primary backend service providing:
  - PostgreSQL database with Row Level Security (RLS)
  - Authentication and user management
  - Storage for images and files
  - Edge Functions for serverless operations
- **Stripe** integration for payment processing
- **Edge Functions** deployed on Supabase for API endpoints

### Database Design
- PostgreSQL database with comprehensive schema including:
  - User authentication and admin management
  - Client relationship management (CRM)
  - Gallery and image management
  - Blog content management
  - Newsletter subscriptions
  - Financial tracking (voucher sales, invoices)
  - Analytics and reporting data

## Key Components

### Authentication System
- Supabase Auth for user management
- Admin user system with role-based access control
- Protected routes for admin functionality
- JWT token-based authentication

### CRM Features
- Client management with detailed profiles
- Lead tracking and conversion
- Project and booking management
- Invoice and expense tracking
- Equipment and location management
- Analytics and reporting dashboard

### Gallery Management
- Password-protected client galleries
- Image upload with automatic resizing
- Download functionality for clients
- Access logging and visitor tracking
- Integration with external services (TogNinja)

### E-commerce Platform
- Voucher marketplace with multiple photography packages
- Shopping cart functionality
- Stripe payment integration
- Order management and fulfillment

### Content Management
- Blog system with rich text editing
- SEO optimization features
- Image storage and management
- Newsletter subscription system

## Data Flow

1. **User Authentication**: Users authenticate through Supabase Auth, with admin privileges checked via the `admin_users` table
2. **Gallery Access**: Clients access password-protected galleries through unique links and JWT tokens
3. **Payment Processing**: Voucher purchases flow through Stripe with webhook integration for order fulfillment
4. **Content Creation**: Admin users create and manage blog posts, galleries, and client data through protected admin routes
5. **Data Storage**: All data is stored in Supabase PostgreSQL with appropriate RLS policies for security

## External Dependencies

### Core Services
- **Supabase**: Database, authentication, storage, and edge functions
- **Stripe**: Payment processing and subscription management
- **Resend**: Email delivery service for notifications

### Development Tools
- **ESLint**: Code quality and linting
- **TypeScript**: Type checking and development experience
- **Vite**: Fast development server and build tool

### UI Libraries
- **Lucide React**: Icon library
- **React Router DOM**: Client-side routing
- **Framer Motion**: Animation library
- **FullCalendar**: Calendar component for booking management

### Utility Libraries
- **Sharp**: Image processing and resizing
- **PapaParse**: CSV parsing for data imports
- **PDF-Kit**: PDF generation for invoices
- **BCrypt**: Password hashing
- **UUID**: Unique identifier generation

## Deployment Strategy

### Environment Configuration
- Environment variables for Supabase URLs and API keys
- Stripe configuration for payment processing
- CORS headers configured for cross-origin requests

### Build Process
- Vite builds optimized production bundle
- TypeScript compilation with strict type checking
- Tailwind CSS optimization and purging

### Database Migrations
- Comprehensive migration system with incremental updates
- Row Level Security policies for data protection
- Proper foreign key relationships and constraints

### Edge Functions
- Serverless functions for API endpoints
- CORS-enabled for frontend integration
- JWT authentication for protected routes

## Recent Changes
- June 21, 2025: Fixed CSV import system to use existing Supabase Edge Functions instead of local API endpoints
- CSV import now properly calls `/upload`, `/map`, and `/status/{importId}` endpoints on the `clients-import` Edge Function
- Removed dependency on non-existent local backend API routes
- Authentication properly integrated with existing Supabase auth system

## Changelog
- June 21, 2025. Initial setup

## User Preferences

Preferred communication style: Simple, everyday language.