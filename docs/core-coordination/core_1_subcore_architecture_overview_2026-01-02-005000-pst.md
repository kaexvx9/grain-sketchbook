# Core 1 Subcore: Architecture Overview

**Date**: 2026-01-02-005000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **DOCUMENTATION IN PROGRESS** — Core system services architecture overview

---

## Executive Summary

This document provides an architectural overview of Core 1 Subcore system services, including L2 sub-agents (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell), their responsibilities, boundaries, and integration patterns.

**Purpose**: Provide comprehensive architecture documentation for Core 1 Subcore coordination and integration planning.

---

## Core 1 Subcore Architecture

### L1 Subcore Coordinator

**Core 1 Subcore** serves as the L1 Subcore Coordinator for Core system services:
- Coordinates L2 sub-agents (1a-1e)
- Designs cross-sub-agent API contracts
- Manages integration testing
- Documents architecture and best practices
- Coordinates with Grain Core Agent (parent) on system-wide integration

### L2 Sub-Agents

**1a. Grain Auth Agent**:
- **Responsibilities**: Authentication and authorization services
- **Key Features**: JWT tokens, OAuth, 2FA, RBAC, API keys, security hardening
- **Integration Points**: Network (middleware), Storage (credential storage)

**1b. Grain Network Agent**:
- **Responsibilities**: Network services (HTTP, WebSocket, DNS, TCP/UDP)
- **Key Features**: HTTP/WebSocket server, DNS resolution, connection management, TLS/SSL
- **Integration Points**: Auth (middleware), Storage (file transfer)

**1c. Grain Storage Agent**:
- **Responsibilities**: File system and storage services
- **Key Features**: File I/O, database format, WAL, backup/restore, encryption, secure storage
- **Integration Points**: Network (file transfer), Auth (credential storage), Compositor (workspace state)

**1d. Grain Compositor Agent**:
- **Responsibilities**: Window management and compositing
- **Key Features**: Window management, compositing, input handling, workspace management, desktop shell
- **Integration Points**: Storage (workspace state persistence)

**1e. Grain Grainscript Shell Agent**:
- **Responsibilities**: Shell for Grain OS sevenos
- **Key Features**: Command parsing, command execution, built-in commands, Grainscript script execution
- **Integration Points**: Core services (1a-1d), sevenos Init System (3d)

---

## System Architecture Layers

### Layer 1: Kernel Interface (Vantage 3 Subcore)

**Components**:
- Basin Kernel (3a): RISC-V kernel with syscall interface
- VM Runtime (3b): JIT compilation (RISC-V → x86_64)
- System Integration (3c): Multi-architecture testing
- sevenos Init System (3d): Service supervision

**Integration**: Core 1 Subcore services use kernel syscalls via Vantage 3 Subcore

### Layer 2: Core System Services (Core 1 Subcore)

**Components**:
- Auth (1a): Authentication and authorization
- Network (1b): Network services
- Storage (1c): File system and storage
- Compositor (1d): Window management
- Grainscript Shell (1e): Shell interface

**Integration**: Cross-sub-agent integration within Core 1 Subcore

### Layer 3: Application Services (Grain Core Agent)

**Components**:
- API Server: HTTP/REST API server
- Auth Service: JWT, OAuth, 2FA services
- Network Stack: TCP/UDP, WebSocket, DNS
- File Storage: Database files, WAL, indexes

**Integration**: Core 1 Subcore services use Grain Core Agent infrastructure

### Layer 4: Applications (Other L1 Agents)

**Components**:
- Silo Agent: Database services
- Carry Agent: Mobile app backend
- Workspace Agent: Desktop applications
- Aurora Agent: IDE/browser
- Skate Agent: Knowledge graph editor

**Integration**: Applications use Core 1 Subcore services via Grain Core Agent

---

## Integration Patterns

### Pattern 1: Service-to-Service Integration

**Description**: Direct integration between Core 1 Subcore services.

**Examples**:
- Auth → Network: Authentication middleware
- Network → Storage: File transfer
- Storage → Auth: Credential storage
- Compositor → Storage: Workspace state

**Characteristics**:
- Bounded API contracts
- Explicit error handling
- Resource cleanup guaranteed
- Grain Style compliant

### Pattern 2: Infrastructure Integration

**Description**: Core 1 Subcore services use Grain Core Agent infrastructure.

**Examples**:
- Network Agent → API Server: Route registration
- Auth Agent → Auth Service: Token management
- Network Agent → Network Stack: Socket operations
- Storage Agent → File Storage: File operations

**Characteristics**:
- Well-defined API contracts
- Backward compatibility maintained
- Versioning strategy
- Breaking changes protocol

### Pattern 3: Kernel Integration

**Description**: Core 1 Subcore services use kernel syscalls via Vantage 3 Subcore.

**Examples**:
- Storage Agent → Kernel: File I/O syscalls
- Network Agent → Kernel: Network syscalls
- Compositor Agent → Kernel: Process management
- Shell Agent → Kernel: Process execution

**Characteristics**:
- Syscall interface documented
- RISC-V compliance verified
- Performance optimized
- Resource limits enforced

### Pattern 4: Cross-Subcore Integration

**Description**: Integration between Core 1 Subcore and Vantage 3 Subcore.

**Examples**:
- Shell (1e) → Init System (3d): Service management commands
- Init System (3d) → Core Services (1a-1d): Service startup sequence

**Characteristics**:
- Cross-subcore coordination
- Well-defined API contracts
- Dependency management
- Lifecycle coordination

---

## Resource Management

### Shared Resources

**Memory**:
- Bounded allocations (MAX_ constants)
- Stack-allocated buffers where possible
- Arena allocators for temporary data
- Resource pools for reusable objects

**File Handles**:
- Bounded file handle pool
- Automatic cleanup on error
- Resource limits enforced

**Network Connections**:
- Bounded connection pool
- Connection timeout management
- Automatic cleanup on disconnect

### Resource Limits

**Per-Service Limits**:
- Max memory per service
- Max file handles per service
- Max network connections per service
- Max CPU time per service

**System-Wide Limits**:
- Total memory across all services
- Total file handles across all services
- Total network connections across all services

---

## Security Architecture

### Authentication Flow

1. **User Authentication**: Auth Agent validates user credentials
2. **Token Generation**: Auth Agent generates JWT token
3. **Token Validation**: Network Agent validates token via Auth middleware
4. **Authorization**: Auth Agent checks permissions (RBAC)
5. **Resource Access**: Authorized access to resources

### Credential Storage

1. **Encryption**: Credentials encrypted before storage
2. **Secure Storage**: Storage Agent stores encrypted credentials
3. **Retrieval**: Auth Agent retrieves and decrypts credentials
4. **Key Management**: Encryption keys managed securely

### Network Security

1. **TLS/SSL**: All network connections use TLS/SSL
2. **Certificate Validation**: Certificate validation enforced
3. **Rate Limiting**: Rate limiting to prevent abuse
4. **Input Validation**: All input validated and sanitized

---

## Performance Architecture

### Optimization Strategies

1. **Zero-Copy**: Minimize data copying
2. **Bounded Buffers**: Use stack-allocated buffers
3. **Connection Pooling**: Reuse network connections
4. **Caching**: Cache frequently accessed data
5. **Async Operations**: Use async I/O where possible

### Performance Monitoring

1. **Metrics Collection**: Collect performance metrics
2. **Profiling**: Profile integration points
3. **Bottleneck Identification**: Identify performance bottlenecks
4. **Optimization**: Optimize based on profiling data

---

## Error Handling Architecture

### Error Types

1. **Immediate Errors**: Return error immediately
2. **Retryable Errors**: Use retry logic with exponential backoff
3. **Fatal Errors**: Log and propagate to caller
4. **Recoverable Errors**: Return default/fallback value

### Error Propagation

1. **Explicit Error Types**: Define explicit error types
2. **Error Context**: Include error context information
3. **Error Logging**: Log errors with context
4. **Error Recovery**: Implement error recovery strategies

---

## Testing Architecture

### Test Levels

1. **Unit Tests**: Test individual components
2. **Integration Tests**: Test cross-sub-agent integration
3. **End-to-End Tests**: Test complete flows
4. **Performance Tests**: Test performance characteristics

### Test Framework

1. **Test Runner**: Integration test runner (`tests/integration/core_1_subcore/runner.zig`)
2. **Test Isolation**: Setup/teardown for test isolation
3. **Test Reporting**: Test result reporting and summary
4. **Test Patterns**: Standardized test patterns

---

## Deployment Architecture

### Framework Ubuntu x86_64

**Environment**:
- Host OS: Ubuntu 24.04 LTS
- Architecture: x86_64 AMD (Framework 16)
- Kernel: RISC-V (Basin Kernel in VM)
- JIT: x86_64 (VM Runtime compilation)

**Deployment**:
- Core services run as userspace processes
- Init System (3d) manages service lifecycle
- Shell (1e) provides command-line interface
- All services use kernel syscalls via Vantage 3 Subcore

---

## Future Architecture Considerations

### Scalability

1. **Horizontal Scaling**: Design for horizontal scaling
2. **Load Balancing**: Implement load balancing
3. **Service Discovery**: Implement service discovery
4. **Distributed Systems**: Design for distributed deployment

### Extensibility

1. **Plugin Architecture**: Design for plugin extensions
2. **API Versioning**: Implement API versioning
3. **Backward Compatibility**: Maintain backward compatibility
4. **Migration Paths**: Provide migration paths

---

## Notes

- All architecture follows Grain Style strictly
- All components use explicit `u32`/`u64` types
- All components use bounded allocations
- All components include error handling
- All components include resource cleanup
- Architecture supports both Core services and sevenos integration

---

**Date**: 2026-01-02-005000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Documentation In Progress — Architecture Overview Complete

