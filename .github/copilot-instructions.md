# Copilot Instructions for MindMatch

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview
MindMatch is a Flutter application designed to promote meaningful human connections with AI support. The app helps users connect based on emotional affinities, values, and worldviews, inspired by Society 5.0 principles.

## Architecture Guidelines
- Follow Flutter best practices and Material Design 3 guidelines
- Use Provider for state management
- Implement Firebase for authentication and data storage
- Use go_router for navigation
- Follow clean architecture patterns

## Key Features
1. **Onboarding Flow**: First-time user introduction
2. **Authentication**: Email/password, Google, and Apple sign-in
3. **User Profiles**: Comprehensive user data with tags and goals
4. **Firebase Integration**: User data storage and real-time features
5. **AI Integration**: Future integration with Google Gemini API

## Code Style
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Follow Dart conventions (snake_case for files, camelCase for variables)
- Use const constructors where possible
- Implement proper error handling with try-catch blocks

## File Structure
- `lib/screens/` - UI screens
- `lib/widgets/` - Reusable UI components
- `lib/services/` - Business logic and API calls
- `lib/models/` - Data models
- `lib/utils/` - Utility classes and constants

## Firebase Configuration
- Authentication with multiple providers
- Firestore for user data and messaging
- Storage for profile pictures and media
- Real-time listeners for chat functionality

## UI/UX Guidelines
- Use AppColors class for consistent theming
- Implement responsive design
- Add loading states and error handling
- Follow accessibility guidelines
- Use meaningful animations and transitions

## Security Considerations
- Validate all user inputs
- Implement proper Firebase security rules
- Handle sensitive data appropriately
- Use secure authentication flows

When generating code, ensure it follows these guidelines and integrates seamlessly with the existing codebase.
