"""Apply RBAC enforcement to all endpoint files."""

import os
import re

ENDPOINTS_DIR = 'app/api/v1/endpoints'

# Permission mapping: filename -> (read_perm, write_perm)
PERMISSIONS = {
    'access_control': ('access_control.read', 'access_control.manage'),
    'analytics': ('analytics.read', 'analytics.read'),
    'assets': ('asset.read', 'asset.manage'),
    'auth': None,  # Public endpoints
    'billing': ('billing.read', 'billing.manage'),
    'categories': ('category.read', 'category.manage'),
    'commands': ('device.read', 'device.manage'),
    'dashboard': ('dashboard.read', 'dashboard.read'),
    'department_shifts': ('shift.read', 'shift.manage'),
    'documents': ('document.read', 'document.manage'),
    'ess': ('ess.read', 'ess.manage'),
    'essl_connector': ('biometric.read', 'biometric.manage'),
    'essl_locations': ('biometric.read', 'biometric.manage'),
    'exit_requests': ('exit.read', 'exit.manage'),
    'expense_benefits': ('expense.read', 'expense.manage'),
    'holidays': ('holiday.read', 'holiday.manage'),
    'hr_ops': ('hr.read', 'hr.manage'),
    'lifecycle': ('employee.read', 'employee.manage'),
    'notification_center': ('notification.read', 'notification.manage'),
    'notifications': ('notification.read', 'notification.manage'),
    'onboarding': ('onboarding.read', 'onboarding.manage'),
    'operations': ('operations.read', 'operations.manage'),
    'ot_register': ('attendance.read', 'attendance.manage'),
    'outdoor_duties': ('attendance.read', 'attendance.manage'),
    'performance': ('performance.read', 'performance.manage'),
    'recruitment': ('recruitment.read', 'recruitment.manage'),
    'settings_api': ('settings.read', 'settings.manage'),
    'setup': ('setup.read', 'setup.manage'),
    'shift_groups': ('shift.read', 'shift.manage'),
    'shift_rosters': ('shift.read', 'shift.manage'),
    'system': ('system.read', 'system.read'),
    'tenant_settings': ('settings.read', 'settings.manage'),
    'tenants': ('tenant.read', 'tenant.manage'),
    'timeline': ('employee.read', 'employee.manage'),
    'websocket': ('dashboard.read', 'dashboard.read'),
    'work_codes': ('attendance.read', 'attendance.manage'),
}

def update_file(filepath, read_perm, write_perm):
    """Update an endpoint file with RBAC enforcement."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # 1. Add require_permissions to import if not present
    if 'require_permissions' not in content:
        # Add to existing deps import
        content = content.replace(
            'from app.core.deps import get_db, get_current_active_user',
            'from app.core.deps import get_db, get_current_active_user, require_permissions'
        )
        # Also add require_feature if not present
        if 'require_feature' not in content:
            content = content.replace(
                'from app.core.deps import get_db, get_current_active_user, require_permissions',
                'from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions'
            )
    
    # 2. Update router definition to include permissions
    # Pattern: router = APIRouter()
    # or: router = APIRouter(dependencies=[...])
    
    if 'router = APIRouter()' in content:
        content = content.replace(
            'router = APIRouter()',
            f'router = APIRouter(dependencies=[Depends(require_permissions("{read_perm}"))])'
        )
    elif 'router = APIRouter(dependencies=[Depends(require_feature(' in content:
        # Already has require_feature, add require_permissions
        pattern = r'router = APIRouter\(dependencies=\[Depends\(require_feature\("([^"]+)"\)\)\]\)'
        match = re.search(pattern, content)
        if match:
            feature = match.group(1)
            content = re.sub(
                pattern,
                f'router = APIRouter(dependencies=[Depends(require_feature("{feature}")), Depends(require_permissions("{read_perm}"))])',
                content
            )
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False


def main():
    files = [f for f in os.listdir(ENDPOINTS_DIR) if f.endswith('.py') and f != '__init__.py']
    
    updated = 0
    skipped = 0
    
    for f in sorted(files):
        module_name = f.replace('.py', '')
        filepath = os.path.join(ENDPOINTS_DIR, f)
        
        if module_name in PERMISSIONS:
            perms = PERMISSIONS[module_name]
            if perms is None:
                print(f'SKIP {f} (public endpoints)')
                skipped += 1
                continue
            
            read_perm, write_perm = perms
            if update_file(filepath, read_perm, write_perm):
                print(f'UPDATED {f} -> {read_perm}')
                updated += 1
            else:
                print(f'  OK {f} (already has RBAC)')
                skipped += 1
        else:
            print(f'  ? {f} (no permission mapping)')
    
    print(f'\nTotal: {updated} updated, {skipped} skipped')


if __name__ == '__main__':
    main()
