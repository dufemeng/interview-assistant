# System Design Preparation for Series B Startup Interview

## Understanding Series B Startup System Design Expectations

### What's Different at Series B vs Big Tech
| Aspect | Big Tech (FAANG) | Series B Startup |
|--------|------------------|------------------|
| **Scale** | Millions of users from day 1 | Thousands to hundreds of thousands |
| **Resources** | Large teams, dedicated infra | Small teams, limited budget |
| **Time Horizon** | Long-term scalability | 6-18 month scalability |
| **Tech Debt Tolerance** | Low (long-term focus) | Medium (velocity over perfection) |
| **Innovation Pressure** | Incremental improvements | Rapid experimentation |

### Key Principles for Series B System Design
1. **Pragmatism over Perfection**: Solve today's problems well, keep tomorrow's options open
2. **Progressive Complexity**: Start simple, add complexity only when needed
3. **Business Alignment**: Every technical decision should serve business goals
4. **Team Constraints**: Design for the team you have, not an ideal team
5. **Cost Awareness**: Cloud costs matter at this stage

---

## Common System Design Questions for Fullstack Roles

### Question 1: Design a Real-time Analytics Dashboard

**Scenario**: "Design a dashboard that shows real-time business metrics to internal teams. It should support 10,000 concurrent users, update every 5 seconds, and allow custom widget creation."

#### Step-by-Step Approach

**1. Clarify Requirements**
- "Real-time" means 5-second updates, not sub-second
- 10,000 concurrent users, not necessarily 10,000 unique users
- Internal use means less concern about public API rate limits
- Custom widgets imply flexible data schema

**2. High-Level Architecture**
```
Frontend (React) → API Gateway → Backend Services → Data Sources
      ↑                    ↑              ↑              ↑
   WebSocket/SSE       Load Balancer   Cache Layer    Databases
```

**3. Component Breakdown**

**Frontend (React Application)**:
- **State Management**: Zustand for client state, React Query for server state
- **Real-time Updates**: SSE for simplicity (one-way, HTTP-based, auto-reconnect)
- **Component Architecture**: Widget library with plugin system
- **Performance**: Virtualization for large datasets, code splitting, memoization

**API Layer**:
- **Express.js** with TypeScript
- **Authentication**: JWT with refresh tokens
- **Rate Limiting**: Per user/IP to prevent abuse
- **API Versioning**: URL-based (`/api/v1/`) from the start

**Real-time Service**:
- **SSE Endpoints**: One connection per user session
- **Connection Management**: Redis for connection state
- **Message Broadcasting**: Redis Pub/Sub for cross-instance communication
- **Fallback**: Long-polling for browsers that don't support SSE

**Data Processing**:
- **Aggregation Service**: Pre-computes metrics on schedule
- **Cache Layer**: Redis for frequently accessed aggregates
- **Database**: PostgreSQL for relational data, TimescaleDB for time-series
- **ETL Pipeline**: For transforming raw data into dashboard format

**4. Scalability Considerations**

**Horizontal Scaling**:
- Stateless API servers behind load balancer
- Redis for session storage (not in-memory)
- Database read replicas for analytics queries
- CDN for static assets

**Performance Optimizations**:
- Response caching at multiple levels (CDN, Redis, browser)
- Database query optimization (indexes, materialized views)
- Connection pooling for database access
- Compression for large JSON responses

**Monitoring & Observability**:
- Application metrics (response times, error rates)
- Business metrics (dashboard usage, widget popularity)
- Infrastructure metrics (CPU, memory, disk I/O)
- Alerting for SLA violations

**5. Trade-off Discussions**

**SSE vs WebSocket**:
- SSE chosen because: One-way communication sufficient, simpler implementation, HTTP-based (works with existing infra)
- WebSocket better if: Need bidirectional communication, sub-second updates

**Database Choices**:
- PostgreSQL + TimescaleDB: Good balance of relational and time-series capabilities
- Alternative: ClickHouse for pure analytics, but more operational complexity

**Caching Strategy**:
- Multi-level: CDN (static), Redis (dynamic), browser (localStorage)
- Cache invalidation: Time-based for metrics, event-based for user data

**6. Implementation Phases**

**Phase 1 (MVP - 2 weeks)**:
- Basic dashboard with pre-defined widgets
- Polling instead of real-time (setInterval)
- Single Express server, in-memory cache
- Proof of concept for widget system

**Phase 2 (Production - 1 month)**:
- SSE for real-time updates
- Redis for caching and session storage
- Database optimization (indexes, read replicas)
- Basic monitoring and alerting

**Phase 3 (Scale - 2 months)**:
- Horizontal scaling of API servers
- Advanced caching strategies
- Comprehensive monitoring
- Widget marketplace/plugin system

**7. Key Metrics to Track**
- Dashboard load time (target: < 3 seconds)
- Data freshness (target: < 5 seconds from source to UI)
- API response time P99 (target: < 200ms)
- Error rate (target: < 0.1%)
- Concurrent connections (capacity planning)

---

### Question 2: Design a Multi-tenant SaaS Dashboard Platform

**Scenario**: "We want to turn our internal dashboard into a SaaS product. Design a system that supports multiple customers (tenants) with data isolation, custom branding, and usage-based billing."

#### Step-by-Step Approach

**1. Multi-tenancy Models Evaluation**

**Database per Tenant**:
- Pros: Strong isolation, easy backups/restores, custom schemas
- Cons: Operational complexity, harder aggregation, more connections

**Shared Database, Separate Schemas**:
- Pros: Good isolation, simpler operations than DB-per-tenant
- Cons: Cross-tenant queries harder, schema changes complex

**Shared Database, Tenant ID Column**:
- Pros: Simple implementation, easy cross-tenant analytics
- Cons: Weakest isolation, data leakage risk, indexing challenges

**Recommendation for Series B**: Start with shared database + tenant_id, evolve to separate schemas if needed. Justify: faster time-to-market, simpler operations, acceptable risk for B2B SaaS.

**2. Tenant Isolation Strategy**

**Data Level**:
- All queries include `WHERE tenant_id = ?`
- Row-level security in database
- Application-level enforcement (never trust single layer)

**Application Level**:
- Tenant context in request (JWT claim, subdomain, header)
- Middleware validates tenant access
- Separate API keys per tenant

**Infrastructure Level**:
- Separate Redis databases/prefixes per tenant
- File storage buckets with tenant prefixes
- Queue workers tagged by tenant

**3. Customization & White-labeling**

**Theme System**:
- CSS variables for colors, fonts, spacing
- Tenant-specific theme configurations in database
- Runtime theme injection (no recompilation needed)

**Branding Assets**:
- S3 bucket with tenant-specific logos, favicons
- CDN with tenant subdomains for asset delivery
- Cache headers for branding assets

**Configuration System**:
- JSON configuration per tenant (features, limits, defaults)
- Feature flags for gradual rollouts
- Configuration versioning and audit trail

**4. Billing & Usage Tracking**

**Usage Metrics**:
- Dashboard views, widget counts, data points processed
- API calls, storage used, user seats
- Real-time tracking with streaming to data warehouse

**Billing Integration**:
- Stripe/Braintree for payment processing
- Usage-based billing with webhooks
- Invoice generation and delivery

**Rate Limiting**:
- Tier-based limits (free, pro, enterprise)
- Soft limits with warnings before hard limits
- Grace periods for overages

**5. Security Considerations**

**Authentication**:
- OAuth 2.0 / OpenID Connect
- SAML for enterprise SSO
- Multi-factor authentication

**Authorization**:
- Role-based access control (RBAC)
- Resource-level permissions
- Audit logging for all sensitive operations

**Data Protection**:
- Encryption at rest and in transit
- Data retention policies per tenant
- GDPR/CCPA compliance features

**6. Deployment & Operations**

**Environment Strategy**:
- Separate environments per major tenant (for enterprise)
- Shared staging environment for smaller tenants
- Blue-green deployments with tenant-aware routing

**Monitoring**:
- Tenant-specific dashboards
- Usage analytics for product decisions
- Cost allocation per tenant

**Backup & Recovery**:
- Point-in-time recovery per tenant
- Tenant self-service backup/restore
- Disaster recovery procedures

**7. Evolution Path**

**Year 1**: Shared database, basic multi-tenancy
**Year 2**: Separate schemas for large enterprise customers
**Year 3**: Hybrid model based on customer size and needs

---

### Question 3: Design a Scalable Notification System

**Scenario**: "Our dashboard needs to send notifications to users (email, SMS, push). Design a system that can handle 1M notifications per day, supports multiple channels, and allows users to customize preferences."

#### Architecture Approach

**1. Core Components**
```
Event Producers → Event Queue → Notification Service → Delivery Channels
      ↑               ↑               ↑                    ↑
  Dashboard       RabbitMQ/       Worker Pool        Email, SMS,
  User Actions     Kafka         with Retries        Push, Webhook
```

**2. Event Flow**
1. User action triggers event (e.g., alert threshold breached)
2. Event published to queue with metadata (user_id, event_type, data)
3. Notification service consumes events
4. Checks user preferences (opt-outs, channel preferences)
5. Renders templates with user/data context
6. Sends to appropriate delivery channels
7. Tracks delivery status and retries if needed

**3. Scalability Design**

**Queue Design**:
- Priority queues for urgent notifications
- Dead letter queues for failed deliveries
- Partitioning by notification type or user geography

**Worker Pool**:
- Auto-scaling based on queue depth
- Circuit breakers for external services
- Rate limiting per channel/provider

**Delivery Channels**:
- Abstract interface for channel providers
- Pluggable architecture for new channels
- Fallback channels (SMS → email if SMS fails)

**4. User Preferences**
- Centralized preference store
- Granular controls (notification type × channel × time)
- Do-not-disturb hours
- Batch/digest options

**5. Monitoring & Analytics**
- Delivery success rates per channel
- User engagement metrics (open rates, click-through)
- Cost tracking per channel/provider
- A/B testing for notification content

**6. Reliability Features**
- Idempotent delivery (prevent duplicates)
- At-least-once semantics
- Delivery receipts and read receipts
- Scheduled notifications with cancellation

---

## System Design Framework for Series B Startups

### 1. Requirements Clarification (5 minutes)
- Ask clarifying questions about scale, constraints, priorities
- Identify must-have vs nice-to-have features
- Understand user personas and use cases
- Determine success metrics

### 2. High-Level Design (10 minutes)
- Draw boxes and arrows diagram
- Identify major components and their responsibilities
- Show data flow and interactions
- Highlight key technology choices

### 3. Deep Dive on Critical Components (15 minutes)
- Choose 2-3 components to explore in detail
- Discuss data models, APIs, algorithms
- Consider failure scenarios and recovery
- Talk about scaling each component

### 4. Trade-offs and Alternatives (5 minutes)
- Explain why you chose this design over alternatives
- Discuss pros and cons of key decisions
- Mention what you would change with more time/resources
- Identify risks and mitigation strategies

### 5. Implementation Plan (5 minutes)
- Suggest phased rollout approach
- Identify MVP scope and timeline
- Talk about monitoring and observability
- Mention team skills and ramp-up needs

---

## Key Technology Choices for Series B

### Databases
**Primary (Transactional)**: PostgreSQL
- Why: Battle-tested, good JSON support, rich ecosystem
- Alternatives: MySQL (simpler), AWS Aurora (managed)

**Cache**: Redis
- Why: In-memory, rich data structures, pub/sub
- Alternatives: Memcached (simpler), DynamoDB (NoSQL)

**Time-series**: TimescaleDB (PostgreSQL extension)
- Why: SQL interface, good compression, continuous aggregates
- Alternatives: InfluxDB (pure time-series), ClickHouse (analytics)

**Search**: Elasticsearch
- Why: Full-text search, aggregations, scalability
- Alternatives: PostgreSQL full-text search (simpler), Algolia (SaaS)

### Message Queues
**Primary**: RabbitMQ
- Why: Feature-rich, good management UI, widely used
- Alternatives: AWS SQS (managed), Kafka (high throughput)

### API Framework
**Primary**: Express.js
- Why: Minimal, flexible, large ecosystem
- Alternatives: Fastify (faster), NestJS (more structure)

### Frontend Framework
**Primary**: React + TypeScript
- Why: Component model, large ecosystem, type safety
- Alternatives: Vue (simpler learning curve), Svelte (compiler-based)

### Deployment & Infrastructure
**Containers**: Docker
**Orchestration**: Kubernetes (if needed) or simpler PaaS
**CI/CD**: GitHub Actions or GitLab CI
**Monitoring**: Prometheus + Grafana
**Logging**: ELK Stack or managed service

---

## Common Pitfalls to Avoid

### 1. Over-engineering
- Don't design for 10M users when you have 10K
- Start with monolithic, split when needed
- Use managed services to reduce ops burden

### 2. Ignoring Business Context
- Every technical decision should serve business goals
- Consider time-to-market vs perfection
- Understand cost implications of choices

### 3. Underestimating Operations
- Design for observability from day 1
- Plan for backups, monitoring, alerting
- Consider team skills for operations

### 4. Lack of Evolution Path
- Systems will need to change as company grows
- Design for incremental improvement
- Keep options open for future changes

### 5. Not Discussing Trade-offs
- Every choice has pros and cons
- Be explicit about what you're optimizing for
- Acknowledge limitations of your design

---

## Practice Questions

### Easy
1. "Design a URL shortener like bit.ly"
2. "Design a file upload service like Dropbox"
3. "Design a chat application for small teams"

### Medium
1. "Design an e-commerce product recommendation system"
2. "Design a ride-sharing matching algorithm"
3. "Design a real-time collaborative document editor"

### Hard
1. "Design Twitter's news feed"
2. "Design Uber's real-time ride tracking"
3. "Design Netflix's video streaming platform"

### Fullstack Focused
1. "Design a dashboard that shows real-time website analytics"
2. "Design a customer support ticket system with real-time updates"
3. "Design an A/B testing platform for feature rollouts"

---

## Evaluation Criteria for Series B

### Technical Competence (40%)
- Appropriate technology choices for scale
- Understanding of trade-offs and alternatives
- Consideration of failure scenarios and recovery
- Knowledge of scalability patterns

### Pragmatism & Business Sense (30%)
- Alignment with business constraints and goals
- Realistic implementation timeline and phases
- Cost awareness and optimization
- Focus on solving the actual problem

### Communication Skills (20%)
- Clear explanation of complex concepts
- Effective use of diagrams and examples
- Ability to listen and incorporate feedback
- Professional and collaborative demeanor

### Learning Mindset (10%)
- Willingness to acknowledge knowledge gaps
- Curiosity about alternative approaches
- Focus on continuous improvement
- Adaptability to changing requirements

---

## Final Preparation Tips

1. **Practice Out Loud**: Explain designs to a friend or record yourself
2. **Time Yourself**: 30-45 minutes total for a system design question
3. **Use Whiteboard**: Practice drawing diagrams while explaining
4. **Prepare Templates**: Have go-to architectures for common patterns
5. **Know Your Numbers**: Rough estimates for storage, bandwidth, costs
6. **Stay Calm**: It's okay to pause and think, ask clarifying questions
7. **Show Your Work**: Explain your thought process, not just the answer

Remember: Series B startups value engineers who can design systems that balance today's needs with tomorrow's growth. Your Tencent experience gives you perspective on scale, while your dashboard project shows you can build modern fullstack systems.