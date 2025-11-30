# Claude Rules for SysOps Projects

## Context Awareness
- Always review relevant files in `ai-context/memory-bank/` before starting work
- Check `ai-context/personas/` to understand the required expertise level
- Consult `ai-context/cot-templates/` for structured thinking approaches
- Reference `ai-context/few-shot-examples/` for code patterns and standards

## Systems Engineering Principles
1. **Infrastructure as Code First**: All infrastructure should be defined as code
2. **Immutable Infrastructure**: Favor rebuilding over modifying in place
3. **Security by Default**: Apply security best practices from the start
4. **Observability**: Include logging, metrics, and tracing
5. **High Availability**: Design for failure and redundancy
6. **Cost Optimization**: Consider cost implications of all decisions

## Code Standards
- Follow language-specific style guides in `ai-context/memory-bank/preferences.md`
- Implement proper error handling and logging
- Include comprehensive comments for complex logic
- Write idempotent code where possible
- Use meaningful variable and function names

## Documentation Requirements
- Update architectural decisions in `ai-context/memory-bank/architectural-decisions.md`
- Document new patterns in `ai-context/memory-bank/best-practices.md`
- Add troubleshooting steps to `ai-context/memory-bank/common-issues.md`
- Keep project context current in `ai-context/memory-bank/project-context.md`
- Create README files for all new modules and projects

## Security Requirements
- Never commit secrets, credentials, or sensitive data
- Use secret management tools (Vault, AWS Secrets Manager, etc.)
- Implement least privilege access control
- Enable encryption at rest and in transit
- Regular security scanning and updates
- Document security decisions and considerations

## Testing and Validation
- Test infrastructure code before applying to production
- Implement CI/CD pipelines for automation
- Use staging environments for validation
- Implement rollback procedures
- Monitor deployments for issues

## Git Workflow
- Use descriptive commit messages following conventional commits
- Create feature branches for new work
- Require code review for infrastructure changes
- Tag releases appropriately
- Keep commit history clean and logical

## Operational Excellence
- Implement comprehensive monitoring and alerting
- Create runbooks for common operations
- Plan for disaster recovery
- Document on-call procedures
- Conduct post-mortems for incidents
- Continuously improve processes

## When Working on Projects
1. Review existing context in memory bank
2. Select appropriate persona for the task
3. Use Chain of Thought templates for complex decisions
4. Follow few-shot examples for consistency
5. Update documentation as you work
6. Test thoroughly before committing
7. Update memory bank with lessons learned
