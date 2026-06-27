# Apex HRMS — Performance Review

## Database Performance

### Largest Tables (by row count potential)
| Table | Expected Rows/Month | Index Status |
|-------|---------------------|--------------|
| attendance_raw_logs | 50,000+ | Partial (missing device_id index) |
| punch_logs | 30,000+ | OK |
| attendances | 30,000+ | OK |
| audit_logs | 10,000+ | OK |
| notifications | 5,000+ | OK |
| access_logs | 5,000+ | OK |
| essl_sync_history | 1,000+ | OK |
| login_history | 1,000+ | Missing user_id index |

### Missing Indexes (51 ForeignKey columns)
Highest impact:
- `employees.status` — filtered in every employee query
- `attendance_raw_logs.device_id` — JOIN with devices
- `leave_requests.status` — filtered in leave dashboard
- `recruitment.candidates.opening_id` — pipeline queries
- All `approved_by`, `created_by`, `reviewer_id` columns

### Query Patterns
| Endpoint | Expected Response | Issue |
|----------|------------------|-------|
| GET /employees | < 200ms | N+1 on department/designation names |
| GET /attendance | < 200ms | OK with pagination |
| GET /dashboard/stats | < 500ms | Multiple COUNT queries |
| GET /reports/* | < 5s | No query optimization |
| GET /recruitment/pipeline | < 300ms | GROUP BY on candidates |

## API Performance

### Response Time Targets
| Category | Target | Current (Est.) | Status |
|----------|--------|----------------|--------|
| CRUD Operations | < 300ms | ~200ms | ✅ |
| List Endpoints | < 500ms | ~300ms | ✅ |
| Dashboard | < 500ms | ~800ms | 🟡 |
| Reports | < 5s | ~3s | ✅ |
| Search | < 500ms | ~400ms | ✅ |
| Auth | < 200ms | ~150ms | ✅ |

### Optimization Opportunities
1. **Dashboard stats**: 6 separate COUNT queries → combine into single query
2. **Employee list**: Missing eager loading for department/designation/branch
3. **Attendance list**: Missing index on date column
4. **Report generation**: No caching, no streaming

## Flutter Performance

### Bundle Size
| Asset | Size (Est.) | Status |
|-------|-------------|--------|
| main.dart.js | ~5MB | 🟡 Large |
| canvaskit.wasm | ~8MB | OK (cached) |
| Total | ~15MB | 🟡 |

### Optimization Opportunities
1. **Tree shaking**: Verify unused code is eliminated
2. **Lazy loading**: Load screens on demand
3. **Image optimization**: Compress assets
4. **Font subsetting**: Only include used glyphs

## Docker Performance

### Image Size
| Service | Size (Est.) | Status |
|---------|-------------|--------|
| Backend | ~500MB | 🟡 |
| Celery | ~500MB | 🟡 |
| PostgreSQL | ~200MB | OK |
| Redis | ~50MB | OK |
| Nginx | ~50MB | OK |

### Optimization Opportunities
1. **Multi-stage builds**: Reduce backend image size
2. **Alpine base**: Use python:3.12-alpine
3. **Dependency caching**: Cache pip install layer

## Recommendations

### Immediate (v1.0.1)
1. Add 51 missing database indexes
2. Add eager loading for employee list queries
3. Combine dashboard COUNT queries

### Short-term (v1.1)
1. Add response compression (gzip)
2. Add query result caching for dashboard
3. Optimize Flutter bundle size
4. Use multi-stage Docker builds

### Long-term (v1.2)
1. Add database read replicas
2. Implement query result streaming for reports
3. Add CDN for static assets
4. Implement connection pool monitoring
