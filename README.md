# Azkaban Magic - Containerized Workflow Manager

This project provides a containerized setup for running Azkaban, a workflow job scheduler, using Docker and Docker Compose.

## Overview

Azkaban is a batch workflow job scheduler created at LinkedIn to run Hadoop jobs. This containerized version provides:

- **Azkaban Web UI** - Web interface for managing workflows, projects, and job executions
- **MySQL Database** - Persistent storage for workflow metadata and execution history
- **Containerized Architecture** - Easy deployment and scaling using Docker

## Architecture

The setup consists of two main services:

1. **Azkaban Service** (`azkaban`)
   - Custom Java web server mimicking Azkaban functionality
   - Runs on port 8081
   - Provides login and dashboard interfaces
   - Connected to MySQL backend

2. **MySQL Database** (`mysql`)
   - MySQL 8.0 for data persistence
   - Runs on port 3306
   - Configured with Azkaban-specific database and user

## Prerequisites

- Docker
- Docker Compose
- Git

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd azkaban_magic
   ```

2. **Start the services:**
   ```bash
   docker compose up -d
   ```

3. **Access Azkaban Web UI:**
   - Open your browser to http://localhost:8081
   - Login with credentials: `admin` / `admin`

4. **Stop the services:**
   ```bash
   docker compose down
   ```

## File Structure

```
azkaban_magic/
├── README.md                 # This file
├── docker-compose.yml        # Docker Compose configuration
├── azkaban-setup.sh         # Setup script for Azkaban container
├── azkaban.properties       # Azkaban configuration (legacy)
├── azkaban-users.xml        # User configuration (legacy)
├── init.sql                 # MySQL initialization script
├── Dockerfile              # Docker image definition (legacy)
├── .dockerignore           # Docker build context exclusions
├── build.gradle.kts        # Gradle build configuration
├── settings.gradle.kts     # Gradle settings
└── .gitignore              # Git ignore rules
```

## Configuration

### Azkaban Configuration

The Azkaban web server is configured through the `azkaban-setup.sh` script, which:

- Creates a Java-based HTTP server on port 8081
- Provides login page with admin/admin credentials
- Shows a dashboard with workflow management interface
- Displays system status and quick action buttons

### MySQL Configuration

MySQL is configured with:
- Database: `azkaban`
- User: `azkaban`
- Password: `azkaban`
- Root password: `azkaban`

### Environment Variables

The following environment variables are configured in `docker-compose.yml`:

**Azkaban Service:**
- `MYSQL_HOST=mysql`
- `MYSQL_PORT=3306`
- `MYSQL_DATABASE=azkaban`
- `MYSQL_USER=azkaban`
- `MYSQL_PASSWORD=azkaban`

**MySQL Service:**
- `MYSQL_ROOT_PASSWORD=azkaban`
- `MYSQL_DATABASE=azkaban`
- `MYSQL_USER=azkaban`
- `MYSQL_PASSWORD=azkaban`

## Building and Running

### Using Docker Compose (Recommended)

```bash
# Start all services in detached mode
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Rebuild and start
docker compose up --build -d
```

### Manual Docker Commands

```bash
# Build custom image (if using Dockerfile)
docker build -t azkaban-magic .

# Create network
docker network create azkaban-network

# Run MySQL
docker run -d \
  --name mysql \
  --network azkaban-network \
  -e MYSQL_ROOT_PASSWORD=azkaban \
  -e MYSQL_DATABASE=azkaban \
  -e MYSQL_USER=azkaban \
  -e MYSQL_PASSWORD=azkaban \
  -p 3306:3306 \
  mysql:8.0

# Run Azkaban
docker run -d \
  --name azkaban \
  --network azkaban-network \
  -p 8081:8081 \
  -v $(pwd)/azkaban-setup.sh:/setup.sh \
  openjdk:11-jdk-slim \
  /bin/sh /setup.sh
```

## Development

### Project Structure

This is a Gradle-based Java project with:
- Java 11 compatibility
- JUnit 5 for testing
- Basic project structure for future Azkaban development

### Adding Custom Workflows

To extend this setup with actual Azkaban functionality:

1. Replace the demo web server with actual Azkaban binaries
2. Configure proper database schemas using Azkaban SQL scripts
3. Add workflow definition capabilities
4. Implement job execution engines

### Customization

**Changing Ports:**
Edit `docker-compose.yml` to modify port mappings:
```yaml
ports:
  - "8082:8081"  # Change external port to 8082
```

**Database Configuration:**
Modify environment variables in `docker-compose.yml` or create a `.env` file:
```env
MYSQL_PASSWORD=your_secure_password
AZKABAN_DB_PASSWORD=your_secure_password
```

## Troubleshooting

### Common Issues

1. **Port Already in Use:**
   ```bash
   # Check what's using port 8081
   lsof -i :8081
   
   # Stop conflicting services or change port in docker-compose.yml
   ```

2. **Container Won't Start:**
   ```bash
   # Check logs
   docker compose logs azkaban
   docker compose logs mysql
   ```

3. **Can't Connect to Web UI:**
   - Ensure containers are running: `docker compose ps`
   - Check if port 8081 is accessible: `curl http://localhost:8081`
   - Verify firewall settings

4. **Database Connection Issues:**
   ```bash
   # Test MySQL connection
   docker exec -it azkaban_magic-mysql-1 mysql -u azkaban -p azkaban
   ```

### Performance Tuning

**Memory Settings:**
Add JVM options to the Azkaban service in `docker-compose.yml`:
```yaml
environment:
  - JAVA_OPTS=-Xmx2g -Xms1g
```

**MySQL Performance:**
Add MySQL configuration:
```yaml
command: --innodb-buffer-pool-size=1G --max-connections=200
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and development purposes.

## Related Resources

- [Official Azkaban Documentation](https://azkaban.github.io/)
- [Azkaban GitHub Repository](https://github.com/azkaban/azkaban)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## Version History

- **v1.0.0** - Initial containerized setup with demo web interface
  - Docker Compose configuration
  - MySQL 8.0 integration  
  - Basic web UI mimicking Azkaban interface
  - Persistent data storage