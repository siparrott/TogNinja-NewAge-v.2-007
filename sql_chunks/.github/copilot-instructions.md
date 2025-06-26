<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# NEWAGEFrntEUI - Copilot Instructions

This is a React + TypeScript + Vite web application with the following tech stack:

## Technology Stack
- **Frontend Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Backend Integration**: Supabase
- **Authentication**: JWT tokens with bcryptjs
- **UI Components**: 
  - Lucide React icons
  - Framer Motion for animations
  - FullCalendar for calendar functionality
  - Recharts for data visualization
- **Additional Libraries**: 
  - React Router for navigation
  - React Helmet for SEO
  - React CountUp for animated counters
  - Typewriter Effect for text animations

## Project Structure
- `/src` - Main source code
- `/public` - Static assets
- `/scripts` - Setup and utility scripts
- `/tests` - Test files
- `/supabase` - Supabase configuration

## Development Guidelines
- Use TypeScript for all new code
- Follow React functional component patterns with hooks
- Use Tailwind CSS classes for styling
- Ensure components are properly typed
- Use environment variables for configuration (check .env.example)
- Follow ESLint configuration for code quality

## Environment Setup
- Copy `.env.example` to `.env` and configure Supabase credentials
- Run `npm ci --include=dev` to install dependencies
- Use `npm run dev` for development server
- Use `npm run build` for production build

## Common Commands
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run lint` - Run ESLint
- `npm run preview` - Preview production build
