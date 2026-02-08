# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack e-commerce shopping application with three main components:

- **client** - Admin web panel (Vue.js 2 + Element UI)
- **server** - Backend API (Spring Boot + MyBatis-Plus)
- **uni-mall** - Mobile shopping app (uni-app framework for cross-platform deployment)

The application follows a three-tier architecture where both the admin panel and mobile app communicate with the same Spring Boot backend API, which persists data to MySQL.

## Development Commands

### Server (Backend)

**Location:** `server/`

**Technology:** Spring Boot 2.2.2, Java 8, Maven

```bash
# From server directory
mvn clean package           # Build the application
mvn spring-boot:run         # Run directly with Maven
java -jar target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar  # Run packaged jar
```

**Configuration:** Server runs on port 8080 with context path `/zhinengxiaochengxsc`

**Database:** MySQL database `db_mall` on localhost:3306. Connection details in `server/src/main/resources/application.yml`

### Client (Admin Panel)

**Location:** `client/`

**Technology:** Vue.js 2.6.10, Element UI, Vue Router, Axios

```bash
# From client directory
npm install                 # Install dependencies
npm run serve               # Development server on port 8081
npm run build               # Production build
npm run lint                # Run ESLint
```

**Development Setup:** The dev server proxies API requests to the backend:
- Dev server: `http://localhost:8081`
- API proxy: `/zhinengxiaochengxsc` → `http://localhost:8080/zhinengxiaochengxsc/`

**Note:** If you encounter Sass compilation issues on Windows, you may need to set `SASS_BINARY_PATH` environment variable (see `前段启动米宁.txt`)

### Uni-Mall (Mobile App)

**Location:** `uni-mall/`

**Technology:** uni-app framework (Vue 2 based), ColorUI

This is a uni-app project that builds to multiple platforms:
- WeChat Mini Program (appid: wx1c7a0edfd2ffc273)
- H5 web app
- Alipay, Baidu, Toutiao mini-programs
- Native Android/iOS apps

**Build Methods:**
- **HBuilderX IDE:** Import project and use Run/Build menus
- **uni-app CLI:** Use `npm run dev:PLATFORM` or `npm run build:PLATFORM` commands if configured

**H5 Configuration:** Base path is `/tiaozaoshichang/front/h5/` (configured in `manifest.json`)

## Architecture

### Backend Structure (Spring Boot)

The backend follows a standard Spring Boot layered architecture:

- **`com.jlwl`** - Root package
- **`com.controller`** - REST API controllers (table-based routing pattern like `/shangpin/page`, `/users/login`)
- **`com.entity`** - JPA entities mapped to database tables
- **`com.dao`** - MyBatis-Plus mappers for data access
- **`com.service`** - Business logic layer
- **`com.config`** - Configuration classes (Shiro security, etc.)

**Key Dependencies:**
- MyBatis-Plus 2.3 - ORM with enhanced CRUD capabilities
- Apache Shiro 1.3.2 - Authentication and authorization
- FastJSON 1.2.8 - JSON serialization
- Baidu AI SDK 4.4.1 - AI-powered features (recommendations, etc.)
- Apache POI 3.9 - Excel import/export
- Hutool 4.0.12 - Java utility library

**API Response Format:** Standardized responses with `code`, `message`, and `data` fields

### Frontend Structure (Client - Vue Admin)

- **`src/views/`** - Page components organized by feature (shangpin, yonghu, orders, etc.)
- **`src/router/`** - Vue Router configuration
- **`src/api/`** - API service layer using Axios
- **`src/utils/`** - Utility functions and helpers
- **`src/components/`** - Reusable Vue components
- **`src/icons/`** - SVG icon system using svg-sprite-loader

**Key Features Implemented:**
- Data visualization with ECharts
- Rich text editing with vue-quill-editor
- QR code generation with vue-qr
- Print functionality with print-js
- Excel export with vue-json-excel

### Mobile App Structure (Uni-Mall)

- **`pages/`** - Page components following uni-app structure
- **`components/`** - Reusable components
- **`uni_modules/`** - uni-app plugin modules (extensive UI component library)
- **`static/`** - Static assets (images, styles)
- **`manifest.json`** - App configuration and platform-specific settings
- **`pages.json`** - Page routing and navigation configuration

## Database Schema

The application uses MySQL with key tables:
- `users` - System administrators
- `yonghu` - Regular customers
- `shangpin` - Products
- `shangjia` - Sellers/vendors
- `shangpin_order` - Orders
- `cart` - Shopping cart
- `address` - Shipping addresses
- `chat` - Customer service messages
- `forum` - Forum posts
- `news` - News/announcements
- `config` - System configuration

**SQL File:** `db_mall.sql` in project root contains the database schema

## Authentication & Authorization

- **Backend:** Apache Shiro with JWT tokens for stateless authentication
- **Frontend:** Token stored in localStorage, sent in request headers
- **Role-based:** Different access levels for admins, users, and sellers

## File Upload

- **Backend:** Supports up to 1000MB file uploads (configured in application.yml)
- **Storage:** Files stored in `server/static/` directory
- **Access:** Served via Spring's static resource handling

## Development Workflow

1. Start MySQL database service
2. Start backend server (`cd server && mvn spring-boot:run`)
3. Start admin panel (`cd client && npm run serve`)
4. For mobile development, use HBuilderX to run in simulator or device
5. Admin panel accessible at `http://localhost:8081`
6. Backend API at `http://localhost:8080/zhinengxiaochengxsc`

## API Endpoint Pattern

The backend follows a table-based RESTful pattern:
- `GET /{table}/page` - Paginated list
- `GET /{table}/info/{id}` - Get by ID
- `POST /{table}/save` - Create
- `PUT /{table}/update` - Update
- `DELETE /{table}/{id}` - Delete

Where `{table}` is the entity name (e.g., `shangpin`, `yonghu`, `orders`)
