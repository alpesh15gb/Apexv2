# Apex HRMS v1.0.0 — User Guide

**Date**: 2026-06-28
**Version**: 1.0.0

---

## Getting Started

### First Login

1. Open your browser and navigate to your Apex HRMS URL (e.g., `https://your-domain.com`)
2. Enter the email and password provided by your administrator
3. Click **Sign In**
4. On first login, you will be prompted to change your password
5. Complete your profile (name, phone, department)

### Dashboard

After login, you see the **Dashboard** with:
- **Attendance summary** — Today's check-in/out status
- **Leave balance** — Available leave days by type
- **Announcements** — Recent company circulars
- **Quick actions** — Common tasks (request leave, view payslip, mark attendance)

### Navigation

- **Sidebar**: Access all modules you have permission for
- **Top bar**: Notifications, profile menu, search
- **Command palette**: Press `Ctrl+K` to quickly search and navigate

---

## Common Workflows

### Marking Attendance

1. Navigate to **Attendance > My Attendance**
2. If biometric devices are configured, attendance is automatic
3. For manual attendance:
   - Click **Punch In** when arriving
   - Click **Punch Out** when leaving
4. View your attendance history in the **History** tab

### Requesting Leave

1. Navigate to **Leave > Request Leave**
2. Select **Leave Type** (casual, sick, earned, etc.)
3. Choose **From Date** and **To Date**
4. Enter **Reason** for leave
5. Click **Submit**
6. Your manager receives a notification and can approve/reject
7. Track status in **Leave > My Requests**

### Viewing Payslips

1. Navigate to **Payroll > My Payslips**
2. Select the month/year
3. Click **View** to see the payslip breakdown
4. Click **Download** to get a PDF copy

### Updating Profile

1. Click your name in the top-right corner
2. Select **Profile**
3. Update personal details (phone, address, emergency contact)
4. Upload profile picture
5. Click **Save**

### Viewing Schedule/Shifts

1. Navigate to **Attendance > My Shifts**
2. View your current shift assignment
3. View the roster calendar for upcoming shifts

### Submitting Expenses

1. Navigate to **Payroll > Expenses**
2. Click **New Expense**
3. Fill in: category, amount, date, description
4. Attach receipt (image or PDF)
5. Click **Submit**

---

## School ERP Workflows (if enabled)

### For Teachers

**Taking Student Attendance**:
1. Navigate to **Academics > Student Attendance**
2. Select class and section
3. Mark present/absent for each student
4. Click **Submit**

**Creating Homework**:
1. Navigate to **Academics > Homework**
2. Click **Create Assignment**
3. Fill in: subject, title, description, due date
4. Attach files if needed
5. Click **Publish**

**Entering Exam Marks**:
1. Navigate to **Examinations > Marks Entry**
2. Select exam and class
3. Enter marks for each student
4. Click **Save** then **Submit**

### For Parents (Student Portal)

- View attendance records
- Download report cards
- Check fee status and pay online
- View homework and circulars
- Message teachers

---

## FAQ

### General

**Q: I forgot my password. How do I reset it?**
A: Click **Forgot Password** on the login page. Enter your email. A reset link will be sent to your registered email address.

**Q: How do I change my password?**
A: Go to **Profile > Change Password**. Enter your current password and new password.

**Q: Why can't I see certain modules?**
A: Modules are controlled by feature flags and your role permissions. Contact your administrator if you need access to additional modules.

**Q: How do I switch between dark and light mode?**
A: Go to **Profile > Preferences** and select your theme.

### Attendance

**Q: My biometric punch is not showing. What do I do?**
A: Biometric sync runs periodically. Wait 15 minutes. If still missing, contact your HR team. They can verify via the sync diagnostic tool.

**Q: Can I edit my attendance?**
A: Attendance corrections require manager approval. Submit a correction request via **Attendance > Correction Request**.

**Q: What happens if I forget to punch out?**
A: The system will flag the day as incomplete. Contact your manager or HR for manual correction.

### Leave

**Q: How is my leave balance calculated?**
A: Leave balance is based on your company's leave policy, prorated from your joining date. Check **Leave > Balance** for details.

**Q: Can I cancel an approved leave?**
A: Yes, if the leave dates are in the future. Go to **Leave > My Requests**, find the request, and click **Cancel**.

**Q: What types of leave are available?**
A: Common types include Casual Leave, Sick Leave, Earned Leave, Maternity/Paternity Leave, and Compensatory Off. Your administrator configures which types are available.

### Payroll

**Q: When are payslips available?**
A: Payslips are generated after payroll processing is complete, typically by the 5th of the following month.

**Q: How do I declare tax-saving investments?**
A: Navigate to **Payroll > Investment Declaration** and submit your proof before the deadline set by your HR.

**Q: My payslip shows incorrect deductions. What do I do?**
A: Contact your HR/payroll team. They can review and correct the payslip before finalization.

### Technical

**Q: The page is loading slowly. What can I do?**
A: Clear your browser cache. Try a different browser. If the issue persists, contact IT support — it may be a server-side issue.

**Q: I'm getting "Session Expired" frequently.**
A: Access tokens expire after 30 minutes of inactivity. The system automatically refreshes using your refresh token. If you're logged out, simply log in again.

**Q: Can I use Apex HRMS on my phone?**
A: Yes, the web interface is responsive and works on mobile browsers. A dedicated mobile app is planned for v2.0.

**Q: How do I report a bug or request a feature?**
A: Contact your administrator or IT support team. They can escalate issues to the development team.

---

**Guide prepared by**: MiMo Code Agent
**Date**: 2026-06-28
