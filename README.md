# Laravel + Statamic Docker Image

This Docker image provides a production-ready environment for running Laravel and Statamic applications. It combines Nginx, PHP-FPM 8.3, and Supervisor in a single container, optimized for AWS ECS/Fargate deployment.

## Image Components

- **Base Image**: `php:8.3-fpm-alpine` (Alpine Linux-based PHP-FPM)
- **Web Server**: Nginx
- **Process Manager**: Supervisor
- **PHP Version**: 8.3
- **Composer**: Latest version

## Key Features

### 1. PHP Extensions
The image includes essential PHP extensions:
- bcmath
- exif
- gd
- intl
- mbstring
- pdo_mysql
- opcache

### 2. Application Setup
- Uses Composer for dependency management
- Optimizes autoloader for production
- Pre-warms Statamic/Laravel caches
- Sets up proper permissions for storage and cache directories

### 3. Process Management
Supervisor manages two main processes:
- PHP-FPM (FastCGI Process Manager)
- Nginx web server

### 4. Logging Strategy
The image implements a comprehensive logging strategy optimized for container environments:

#### Nginx Logging
- Access logs are redirected to STDOUT
- Error logs are redirected to STDERR
- Log rotation is disabled for container-friendly logging

#### PHP-FPM Logging
- Error logs are redirected to STDERR
- Worker output is captured
- Log level set to "notice"

#### PHP Error Handling
- Error logging enabled
- Display errors disabled (production-safe)
- Errors logged to STDERR

This logging setup ensures:
- All logs are properly captured in container environments
- Compatibility with AWS CloudWatch
- No log file rotation issues in containers
- Proper error tracking without exposing sensitive information

### 5. Health Checks
- Built-in health check endpoint at `/healthz`
- 90-second interval health checks
- 3-second timeout

## Configuration Files

### Nginx Configuration
- Listens on port 8080
- Configured for Laravel/Statamic routing
- Includes health check endpoint
- Optimized for PHP-FPM communication

### Supervisor Configuration
- Runs in foreground mode (PID 1)
- Manages both Nginx and PHP-FPM processes
- Configures proper logging for both services

## Usage

### Building the Image
```bash
docker build -t your-image-name .
```

### Running the Container
```bash
docker run -p 8080:8080 your-image-name
```

### Environment Variables
The application can be configured using standard Laravel environment variables.

## Notes

- The image is designed to run as a single container in production
- All logs are properly forwarded to container logs
- The setup is optimized for AWS ECS/Fargate deployment
