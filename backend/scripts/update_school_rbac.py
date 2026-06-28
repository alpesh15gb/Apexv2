"""Update school endpoints with RBAC enforcement."""

import os
import re

ENDPOINTS_DIR = 'app/api/v1/endpoints/school'

SCHOOL_PERMS = {
    'admission': ('admission.read', 'admission.manage'),
    'certificate': ('certificate.read', 'certificate.issue'),
    'communication': ('circular.read', 'circular.publish'),
    'library': ('library.read', 'library.manage'),
    'medical': ('medical.read', 'medical.manage'),
    'timetable': ('timetable.read', 'timetable.manage'),
}

def main():
    for module, (read_perm, write_perm) in SCHOOL_PERMS.items():
        filepath = os.path.join(ENDPOINTS_DIR, f'{module}.py')
        if not os.path.exists(filepath):
            continue
        
        with open(filepath, 'r') as f:
            content = f.read()
        
        if 'require_permissions' in content:
            print(f'  OK {module}.py (already has RBAC)')
            continue
        
        # Add require_permissions import
        content = content.replace(
            'from app.core.deps import get_db, get_current_active_user, require_feature',
            'from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions'
        )
        
        # Update router definitions
        pattern = r'router = APIRouter\(dependencies=\[Depends\(require_feature\("([^"]+)"\)\)\]\)'
        match = re.search(pattern, content)
        if match:
            feature = match.group(1)
            content = re.sub(
                pattern,
                f'router = APIRouter(dependencies=[Depends(require_feature("{feature}")), Depends(require_permissions("{read_perm}"))])',
                content
            )
        
        with open(filepath, 'w') as f:
            f.write(content)
        
        print(f'UPDATED {module}.py -> {read_perm}')

if __name__ == '__main__':
    main()
