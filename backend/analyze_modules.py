"""Analyze all modules in the codebase."""
import os
from collections import defaultdict

def count_routes(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    methods = ['@router.get', '@router.post', '@router.put', '@router.delete', '@router.patch', '@router.websocket']
    return sum(content.count(m) for m in methods)

def count_models(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    return content.count('__tablename__')

# Endpoint modules
endpoints = defaultdict(lambda: {'routes': 0, 'files': []})
for d in ['app/api/v1/endpoints', 'app/api/v1/endpoints/school', 'app/api/v1/endpoints/admin']:
    if not os.path.exists(d):
        continue
    for f in sorted(os.listdir(d)):
        if not f.endswith('.py') or f == '__init__.py':
            continue
        filepath = os.path.join(d, f)
        prefix = d.split('/')[-1] if d.count('/') > 2 else ''
        module = prefix + '/' + f if prefix in ('school', 'admin') else f
        routes = count_routes(filepath)
        endpoints[module]['routes'] += routes
        endpoints[module]['files'].append(filepath)

# Model modules
models = defaultdict(lambda: {'tables': 0, 'files': []})
for d in ['app/models', 'app/models/school']:
    if not os.path.exists(d):
        continue
    for f in sorted(os.listdir(d)):
        if not f.endswith('.py') or f == '__init__.py':
            continue
        filepath = os.path.join(d, f)
        tables = count_models(filepath)
        if tables > 0:
            prefix = 'school' if 'school' in d else 'core'
            models[prefix + '/' + f]['tables'] += tables
            models[prefix + '/' + f]['files'].append(filepath)

# Service modules
services = []
for f in sorted(os.listdir('app/services')):
    if f.endswith('.py') and f != '__init__.py':
        services.append(f)

total_routes = sum(m['routes'] for m in endpoints.values())
total_tables = sum(m['tables'] for m in models.values())

print("=" * 60)
print("APEX HRMS + SCHOOL ERP - MODULE ANALYSIS")
print("=" * 60)

print("\n## API ENDPOINTS (" + str(total_routes) + " total routes)")
header = "  " + "Module".ljust(38) + "Routes".rjust(6)
print(header)
print("  " + "-" * 46)
for mod in sorted(endpoints.keys()):
    line = "  " + mod.ljust(38) + str(endpoints[mod]['routes']).rjust(6)
    print(line)

print("\n## DATABASE MODELS (" + str(total_tables) + " total tables)")
header = "  " + "Module".ljust(38) + "Tables".rjust(6)
print(header)
print("  " + "-" * 46)
for mod in sorted(models.keys()):
    line = "  " + mod.ljust(38) + str(models[mod]['tables']).rjust(6)
    print(line)

print("\n## SERVICES (" + str(len(services)) + " total)")
for s in services:
    print("  " + s)

# Count screens
screen_count = 0
screen_dirs = defaultdict(int)
for root, dirs, files in os.walk('frontend/lib/screens'):
    for f in files:
        if f.endswith('.dart'):
            screen_count += 1
            rel = os.path.relpath(root, 'frontend/lib/screens')
            screen_dirs[rel.split(os.sep)[0] if os.sep in rel else 'root'] += 1

model_count = len([f for f in os.listdir("frontend/lib/models") if f.endswith(".dart")])
service_count = len([f for f in os.listdir("frontend/lib/services") if f.endswith(".dart")])
provider_count = len([f for f in os.listdir("frontend/lib/providers") if f.endswith(".dart")])
widget_count = len([f for f in os.listdir("frontend/lib/widgets") if f.endswith(".dart")])

print("\n## FRONTEND")
print("  Total Screens: " + str(screen_count))
print("  Models: " + str(model_count))
print("  Services: " + str(service_count))
print("  Providers: " + str(provider_count))
print("  Widgets: " + str(widget_count))

print("\n## SCREENS BY MODULE")
for mod in sorted(screen_dirs.keys()):
    print("  " + mod.ljust(30) + str(screen_dirs[mod]).rjust(4))
