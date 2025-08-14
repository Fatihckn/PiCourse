from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from core.models import Subject, TutorProfile, StudentProfile, LessonRequest
from decimal import Decimal
from datetime import datetime, timedelta
import pytz

User = get_user_model()

class Command(BaseCommand):
    help = 'Seed database with sample data for development'

    def handle(self, *args, **options):
        self.stdout.write('Seeding database...')
        
        # Create Subjects
        subjects_data = [
            'Mathematics',
            'Physics',
            'Chemistry',
            'English',
            'History'
        ]
        
        subjects = []
        for subject_name in subjects_data:
            subject, created = Subject.objects.get_or_create(name=subject_name)
            subjects.append(subject)
            if created:
                self.stdout.write(f'Created subject: {subject_name}')
        
        # Create Students
        students_data = [
            {
                'username': 'student1',
                'email': 'student1@example.com',
                'password': 'testpass123',
                'first_name': 'John',
                'last_name': 'Doe',
                'grade_level': '10th Grade'
            },
            {
                'username': 'student2',
                'email': 'student2@example.com',
                'password': 'testpass123',
                'first_name': 'Jane',
                'last_name': 'Smith',
                'grade_level': '11th Grade'
            }
        ]
        
        students = []
        for student_data in students_data:
            user, created = User.objects.get_or_create(
                username=student_data['username'],
                defaults={
                    'email': student_data['email'],
                    'first_name': student_data['first_name'],
                    'last_name': student_data['last_name'],
                    'role': 'student'
                }
            )
            if created:
                user.set_password(student_data['password'])
                user.save()
                StudentProfile.objects.create(
                    user=user,
                    grade_level=student_data['grade_level']
                )
                self.stdout.write(f'Created student: {user.username}')
            students.append(user)
        
        # Create Tutors
        tutors_data = [
            {
                'username': 'tutor1',
                'email': 'tutor1@example.com',
                'password': 'testpass123',
                'first_name': 'Dr. Alice',
                'last_name': 'Johnson',
                'bio': 'Experienced mathematics teacher with 10+ years of experience',
                'hourly_rate': Decimal('50.00'),
                'rating': 4.8,
                'subjects': ['Mathematics', 'Physics']
            },
            {
                'username': 'tutor2',
                'email': 'tutor2@example.com',
                'password': 'testpass123',
                'first_name': 'Prof. Bob',
                'last_name': 'Wilson',
                'bio': 'Chemistry professor specializing in organic chemistry',
                'hourly_rate': Decimal('45.00'),
                'rating': 4.6,
                'subjects': ['Chemistry']
            },
            {
                'username': 'tutor3',
                'email': 'tutor3@example.com',
                'password': 'testpass123',
                'first_name': 'Ms. Carol',
                'last_name': 'Brown',
                'bio': 'English literature teacher with passion for classic novels',
                'hourly_rate': Decimal('40.00'),
                'rating': 4.9,
                'subjects': ['English', 'History']
            }
        ]
        
        tutors = []
        for tutor_data in tutors_data:
            user, created = User.objects.get_or_create(
                username=tutor_data['username'],
                defaults={
                    'email': tutor_data['email'],
                    'first_name': tutor_data['first_name'],
                    'last_name': tutor_data['last_name'],
                    'role': 'tutor'
                }
            )
            if created:
                user.set_password(tutor_data['password'])
                user.save()
                
                profile = TutorProfile.objects.create(
                    user=user,
                    bio=tutor_data['bio'],
                    hourly_rate=tutor_data['hourly_rate'],
                    rating=tutor_data['rating']
                )
                
                # Add subjects
                for subject_name in tutor_data['subjects']:
                    subject = Subject.objects.get(name=subject_name)
                    profile.subjects.add(subject)
                
                self.stdout.write(f'Created tutor: {user.username}')
            tutors.append(user)
        
        # Create Lesson Requests
        lesson_requests_data = [
            {
                'student': students[0],
                'tutor': tutors[0],
                'subject': subjects[0],  # Mathematics
                'start_time': datetime.now(pytz.UTC) + timedelta(days=1, hours=10),
                'duration_minutes': 60,
                'status': 'pending'
            },
            {
                'student': students[1],
                'tutor': tutors[1],
                'subject': subjects[2],  # Chemistry
                'start_time': datetime.now(pytz.UTC) + timedelta(days=2, hours=14),
                'duration_minutes': 90,
                'status': 'approved'
            },
            {
                'student': students[0],
                'tutor': tutors[2],
                'subject': subjects[3],  # English
                'start_time': datetime.now(pytz.UTC) + timedelta(days=3, hours=16),
                'duration_minutes': 60,
                'status': 'rejected'
            }
        ]
        
        for lr_data in lesson_requests_data:
            lesson_request, created = LessonRequest.objects.get_or_create(
                student=lr_data['student'],
                tutor=lr_data['tutor'],
                subject=lr_data['subject'],
                start_time=lr_data['start_time'],
                defaults={
                    'duration_minutes': lr_data['duration_minutes'],
                    'status': lr_data['status']
                }
            )
            if created:
                self.stdout.write(f'Created lesson request: {lesson_request}')
        
        self.stdout.write(
            self.style.SUCCESS('Successfully seeded database!')
        )
        self.stdout.write(f'Created {len(subjects)} subjects')
        self.stdout.write(f'Created {len(students)} students')
        self.stdout.write(f'Created {len(tutors)} tutors')
        self.stdout.write(f'Created {len(lesson_requests_data)} lesson requests') 