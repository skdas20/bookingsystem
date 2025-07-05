<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Appointment Booking System Backend - Copilot Instructions

## Project Context
This is a complete appointment booking system backend built with Express.js, TypeScript, PostgreSQL, and Docker. The system handles user authentication, availability management, slot generation, and booking operations with full timezone support.

## Code Style Guidelines
- Use TypeScript with strict type checking
- Follow RESTful API conventions
- Implement proper error handling with try-catch blocks
- Use Zod for request validation
- Return appropriate HTTP status codes (200, 201, 400, 401, 404, 409, 500)
- Include comprehensive JSDoc comments for complex functions

## Architecture Patterns
- **Route handlers**: Keep business logic in route files, use middleware for cross-cutting concerns
- **Database queries**: Use parameterized queries to prevent SQL injection
- **Authentication**: Use JWT tokens with Bearer authentication
- **Validation**: Validate all inputs using Zod schemas
- **Error handling**: Use centralized error handler middleware

## Key Dependencies
- **express**: Web framework
- **pg**: PostgreSQL client
- **jsonwebtoken**: JWT token handling
- **bcrypt**: Password hashing
- **zod**: Schema validation
- **date-fns & date-fns-tz**: Date/time manipulation with timezone support
- **uuid**: Unique ID generation

## Business Logic Rules
- **Lead time**: Bookings must be ≥ 2 hours in advance
- **Booking horizon**: Bookings cannot be > 14 days in advance
- **Cancellation notice**: Cancellations must be ≥ 12 hours before appointment
- **Slot intervals**: Must be between 15 minutes and 8 hours
- **Timezone handling**: Store UTC in database, convert for user display

## Database Schema
- **users**: Authentication and user info
- **availability_rules**: Weekly availability patterns per user
- **bookings**: Appointment bookings with UUID IDs and cancel codes

## Security Considerations
- Hash passwords with bcrypt (12 salt rounds)
- Validate JWT tokens on protected routes
- Sanitize all database inputs
- Use parameterized queries
- Implement proper CORS and security headers

## Testing & Development
- Use nodemon for development hot reloading
- Docker setup for consistent environment
- Health check endpoint at `/health`
- Comprehensive error logging
- Request/response logging middleware

When generating code, ensure it follows these patterns and maintains consistency with the existing codebase.
