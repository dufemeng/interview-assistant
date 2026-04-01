# Interview Quick Reference Guide

## Your Key Selling Points

### 1. Tencent Scale Experience
- **如意云架构**: Performance optimization (30ms → 5ms), complex UI interactions
- **Large System Design**: Experience with systems serving millions of users
- **Cross-team Collaboration**: Worked in large organization with multiple teams
- **Production Excellence**: 9 years of shipping production code at scale

### 2. Modern Fullstack Skills
- **React 18+**: Hooks, concurrent features, performance optimization
- **State Management**: Zustand expertise (chose over Redux for simplicity)
- **Data Fetching**: React Query patterns (caching, optimistic updates)
- **Backend**: Express.js API design, authentication, scalability
- **TypeScript**: Fullstack type safety experience

### 3. AI-Assisted Development
- **Claude Code Experience**: Built dashboard in 2 months with AI assistance
- **Productivity Patterns**: Effective use of AI tools while maintaining code quality
- **Modern Workflow**: Adaptability to new development methodologies

### 4. Startup Mindset
- **Velocity**: Built production dashboard in 2 months
- **Pragmatism**: Technology choices balanced for speed and quality
- **Ownership**: Fullstack responsibility from UI to database
- **Business Alignment**: Technical decisions tied to user needs

---

## Technical Talking Points

### React & Frontend
**When asked about React**:
- Emphasize hooks patterns and custom hooks
- Discuss performance optimization techniques
- Mention React 18 features you've used
- Talk about component architecture decisions

**Key phrases to use**:
- "We used React.memo strategically to prevent unnecessary re-renders"
- "Custom hooks helped us extract complex logic from components"
- "React Query's cache invalidation patterns solved our data freshness issues"
- "Zustand's fine-grained subscriptions improved our dashboard performance"

### State Management (Zustand)
**Why Zustand over Redux**:
- "Simpler API with 90% of the benefits"
- "Fine-grained subscriptions prevent unnecessary re-renders"
- "No provider wrapping needed - cleaner component tree"
- "Middleware support (persist, devtools) met all our needs"

**Implementation highlights**:
- Separate stores for different concerns
- Selector patterns for performance
- Middleware for persistence and debugging
- TypeScript integration for type safety

### Data Fetching (React Query)
**Key advantages demonstrated**:
- Automatic caching and deduplication
- Optimistic updates for better UX
- Background refetching for data freshness
- Error handling and retry logic

**Specific examples to mention**:
- How you configured staleTime for different data types
- Cache invalidation patterns after mutations
- Infinite query implementation for large datasets
- Prefetching strategies for anticipated user actions

### Backend (Express.js)
**Architecture decisions**:
- Middleware-based approach for cross-cutting concerns
- JWT authentication with refresh tokens
- Structured error handling and logging
- API versioning from the start

**Performance optimizations**:
- Redis caching for expensive operations
- Database connection pooling
- Response compression
- Query optimization and indexing

---

## STAR Story Cheat Sheet

### Story 1: Zustand Decision
**S**: Dashboard with 15+ widgets needed state management
**T**: Choose between Redux, Zustand, Context API
**A**: Evaluated each, chose Zustand for simplicity/performance balance
**R**: 40% faster renders, 65% less code, easier maintenance

### Story 2: React Query Implementation
**S**: Data inconsistency and race conditions with useEffect
**T**: Implement robust data fetching solution
**A**: Chose React Query, organized query keys, configured caching
**R**: 70% faster load times, 90% fewer data errors, 80% less code

### Story 3: Express API Design
**S**: Needed backend for dashboard data aggregation
**T**: Design scalable, secure API
**A**: Express with middleware, JWT auth, Redis cache, structured logging
**R**: 50ms average response time, 99.9% uptime, easy to maintain

### Story 4: Performance Optimization
**S**: Users reported sluggish dashboard performance
**T**: Identify and fix performance bottlenecks
**A**: Profiling, memoization, virtualization, code splitting
**R**: 75% faster renders, 60% less memory, steady 60 FPS

### Story 5: Component Library
**S**: Code duplication and inconsistent UI across widgets
**T**: Create reusable component library
**A**: Design system, compound components, custom hooks, documentation
**R**: 70% faster widget development, 85% less code duplication

---

## Common Questions & Answers

### "Why are you leaving Tencent?"
**Answer**: "After 9 years at Tencent, I've built strong foundations in large-scale systems and complex UI challenges. Now I'm looking to apply that experience in a faster-paced environment where I can have more direct impact on product direction and work across the full stack. The Series B stage is particularly appealing because it combines the challenge of scaling with the opportunity to shape technical foundations."

### "What attracts you to our company?"
**Answer**: "I'm impressed by [mention specific product/achievement]. At the Series B stage, companies face interesting technical challenges around scaling while maintaining velocity. My experience at Tencent gives me perspective on scale, while my recent dashboard project shows I can build modern fullstack applications quickly. I'm excited about the opportunity to contribute to both immediate product needs and long-term technical foundations."

### "What's your experience with our tech stack?"
**Answer**: "I see you use [mention their stack]. My dashboard project used React, TypeScript, and Node.js/Express, which aligns well. For state management, I used Zustand which is similar in philosophy to [their state management]. I'm comfortable with modern frontend patterns and have experience making pragmatic technology choices for startup environments."

### "How do you handle technical debt?"
**Answer**: "I believe in strategic technical debt - taking shortcuts when necessary for velocity, but with clear plans to address them. In my dashboard project, we started with polling for real-time updates knowing we'd move to SSE later. The key is tracking debt, prioritizing repayment based on impact, and ensuring it doesn't accumulate uncontrollably."

### "How do you balance speed and quality?"
**Answer**: "By making deliberate trade-offs. We used TypeScript for compile-time safety but didn't aim for 100% test coverage initially. We chose Zustand over Redux for faster development but ensured it met our performance needs. The balance shifts based on context - more quality investment for foundational code, more speed for experimental features."

---

## Red Flags to Avoid

### Technical Discussions
- ❌ "I always use [technology] because it's the best"
- ✅ "I chose [technology] because it solved [specific problem] given [constraints]"

- ❌ "I don't know" (without follow-up)
- ✅ "I haven't worked with that specifically, but based on my experience with [similar technology], I would approach it by..."

- ❌ Overly complex solutions to simple problems
- ✅ Simple solutions that solve the actual problem

### Behavioral Questions
- ❌ Blaming others for problems
- ✅ Taking ownership and focusing on solutions

- ❌ Vague answers without specifics
- ✅ Concrete examples with measurable results

- ❌ Only talking about successes
- ✅ Sharing failures and learnings

### Company/Team Questions
- ❌ "I just want any job"
- ✅ Specific reasons why this company/role appeals to you

- ❌ No questions for the interviewer
- ✅ Thoughtful questions about team, challenges, culture

---

## Interview Day Checklist

### Before the Interview
- [ ] Review your project code and architecture decisions
- [ ] Practice explaining 2-3 key technical decisions
- [ ] Prepare questions for each interviewer
- [ ] Test your video/audio setup
- [ ] Have water and notes nearby

### During Technical Questions
- [ ] Think out loud - explain your thought process
- [ ] Ask clarifying questions before diving in
- [ ] Start with a simple solution, then optimize
- [ ] Consider edge cases and error handling
- [ ] Discuss trade-offs of your approach

### During Behavioral Questions
- [ ] Use STAR format (Situation, Task, Action, Result)
- [ ] Include specific metrics when possible
- [ ] Focus on your role and contributions
- [ ] Share what you learned
- [ ] Connect to the role you're interviewing for

### Questions to Ask Interviewers
**For Engineering Manager**:
- "How do you balance technical debt repayment with feature development?"
- "What does success look like for this role in the first 6 months?"
- "How does the engineering team collaborate with product and design?"

**For Technical Lead/Peer**:
- "What's the most challenging technical problem the team has solved recently?"
- "How do you make technology choices and evaluate new tools?"
- "What does your deployment and monitoring pipeline look like?"

**For Founder/Executive**:
- "What are the biggest technical challenges as you scale from Series B to Series C?"
- "How do you think about technical investment vs product velocity?"
- "What's the company's technical vision for the next 2 years?"

### Closing the Interview
- Reiterate your interest in the role
- Mention specific aspects that excite you
- Ask about next steps and timeline
- Thank them for their time

---

## Mindset for Success

### Series B Startup Expectations
1. **Build quickly but thoughtfully**: Velocity matters, but so does maintainability
2. **Own problems end-to-end**: From user experience to database queries
3. **Make pragmatic choices**: Perfect is the enemy of good at this stage
4. **Think about scale**: Design for 10x growth, not 1000x
5. **Align with business**: Technical decisions should drive business outcomes

### Your Unique Value Proposition
**Tencent Scale + Modern Skills + Startup Mindset**
- You've seen what scale looks like (Tencent)
- You have modern fullstack skills (dashboard project)
- You understand startup constraints (2-month build time)
- You're adaptable (AI-assisted development experience)

### Final Reminder
You're not just interviewing for a job - you're evaluating whether this is the right place for you to grow and contribute. The interview goes both ways. Be confident in your skills, curious about their challenges, and authentic in your interactions.

Good luck! 🚀