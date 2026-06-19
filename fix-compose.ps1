$content = @'
services:
  # ==================== PostgreSQL Database ====================
  postgres:
    image: postgres:15-alpine
    container_name: prod_postgres
    restart: always
    environment:
      POSTGRES_DB: api_clinica_prod
      POSTGRES_USER: clinica_user
      POSTGRES_PASSWORD: l4cqF58iJzc0bvFAauZI24YLJzx+MHA+
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c maintenance_work_mem=64MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100
      -c random_page_cost=1.1
      -c effective_io_concurrency=200
      -c work_mem=4MB
      -c min_wal_size=2GB
      -c max_wal_size=8GB
    expose:
      - "5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../scripts:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U clinica_user -d api_clinica_prod"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 60s
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service=postgres"
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 1G
        reservations:
          cpus: "1"
          memory: 512M

  # ==================== Redis Cache ====================
  redis:
    image: redis:7-alpine
    container_name: prod_redis
    restart: always
    command: redis-server --appendonly yes --requirepass qoRufVQAZqOQ5Bnrn5VzNkQjF4sjlBef --maxmemory 512mb --maxmemory-policy allkeys-lru
    expose:
      - "6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
        labels: "service=redis"
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: 512M
        reservations:
          cpus: "0.5"
          memory: 256M

  # ==================== Node.js API ====================
  api:
    image: api-clinica:production
    build:
      context: ../../velyon_api
      dockerfile: ../velyon_infra/docker/Dockerfile.api.prod
    container_name: prod_api
    restart: always
    env_file:
      - ../../velyon_api/.env
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgresql://clinica_user:l4cqF58iJzc0bvFAauZI24YLJzx+MHA+@postgres:5432/api_clinica_prod
      REDIS_URL: redis://:qoRufVQAZqOQ5Bnrn5VzNkQjF4sjlBef@redis:6379/0
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: api_clinica_prod
      DB_USER: clinica_user
      DB_PASSWORD: l4cqF58iJzc0bvFAauZI24YLJzx+MHA+
    expose:
      - 3000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ../../velyon_api/logs:/app/logs
      - ../../velyon_api/tmp:/app/tmp
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service=api"
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 1G
        reservations:
          cpus: "1"
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # ==================== Node.js Frontend Tenant ====================
  frontend:
    image: tenant-frontend:production
    build:
      context: ../../velyon_frontend_tenant
      dockerfile: ../velyon_infra/docker/Dockerfile.frontend.prod
      args:
        VITE_API_BASE_URL: https://localhost/api
    container_name: prod_frontend
    restart: always
    env_file:
      - ../../velyon_frontend_tenant/.env
    environment:
      NODE_ENV: production
      PORT: 5173
      VITE_API_BASE_URL: https://localhost/api
    expose:
      - 5173
    volumes:
      - ../../velyon_frontend_tenant/logs:/app/logs
      - ../../velyon_frontend_tenant/tmp:/app/tmp
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service=frontend"
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 1G
        reservations:
          cpus: "1"
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5173/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # ==================== Node.js Frontend Site ====================
  frontend-site:
    image: site-frontend:production
    build:
      context: ../../velyon_frontend_site
      dockerfile: ../velyon_infra/docker/Dockerfile.frontend.prod
      args:
        VITE_API_BASE_URL: https://localhost/api
    container_name: prod_frontend_site
    restart: always
    env_file:
      - ../../velyon_frontend_site/.env
    environment:
      NODE_ENV: production
      PORT: 5174
      VITE_API_BASE_URL: https://localhost/api
    expose:
      - 5174
    volumes:
      - ../../velyon_frontend_site/logs:/app/logs
      - ../../velyon_frontend_site/tmp:/app/tmp
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service=frontend-site"
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 1G
        reservations:
          cpus: "1"
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5174/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # ==================== Nginx Reverse Proxy ====================
  nginx:
    build:
      context: ..
      dockerfile: docker/Dockerfile.nginx
    image: app-nginx:production
    container_name: prod_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../nginx/logs:/var/log/nginx
    depends_on:
      api:
        condition: service_healthy
      frontend:
        condition: service_healthy
      frontend-site:
        condition: service_healthy
    networks:
      - app_network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service=nginx"
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: 256M
        reservations:
          cpus: "0.5"
          memory: 128M
    healthcheck:
      test:
        [
          "CMD",
          "wget",
          "--quiet",
          "--tries=1",
          "--spider",
          "http://127.0.0.1/nginx-health",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  postgres_data:
  redis_data:

networks:
  app_network:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450

'@

Set-Content -Path "G:\novo\velyon_infra\docker\docker-compose.prod.yml" -Value $content -Encoding UTF8 -NoNewline
Write-Host "Arquivo docker-compose.prod.yml recriado com sucesso."
