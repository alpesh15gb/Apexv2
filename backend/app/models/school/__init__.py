"""School ERP models."""

from app.models.school.academic_year import AcademicYear, AcademicTerm, SchoolHoliday
from app.models.school.campus import Campus, Building, Room
from app.models.school.grade import Grade, Section, House
from app.models.school.student import Student, Guardian, StudentGuardian, StudentSibling
from app.models.school.subject import Subject, GradeSubject, TeacherAllocation
from app.models.school.timetable import PeriodDefinition, TimetableEntry, Substitution
from app.models.school.student_attendance import StudentAttendance, StudentAttendanceSummary
from app.models.school.homework import Homework, HomeworkSubmission, Assignment, AssignmentSubmission
from app.models.school.examination import ExamType, Exam, ExamSchedule, ExamMark, GradingScale, GradingScaleDetail
from app.models.school.fee import FeeCategory, FeeStructure, StudentFee, FeePayment, FeeFineRule, Scholarship, StudentScholarship
from app.models.school.transport import TransportRoute, TransportStop, StudentTransport
from app.models.school.hostel import Hostel, HostelRoom, HostelAllocation
from app.models.school.library import LibraryBook, LibraryTransaction
from app.models.school.lesson_plan import LessonPlan
from app.models.school.communication import SchoolEvent, Circular
from app.models.school.medical import HealthRecord, DisciplineIncident
from app.models.school.certificate import CertificateTemplate, IssuedCertificate
from app.models.school.admission import AdmissionInquiry, AdmissionApplication
