from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from decimal import Decimal
from datetime import datetime, timedelta
import pytz

from .models import User, Subject, TutorProfile, StudentProfile, LessonRequest

class UserModelTest(TestCase):
    def setUp(self):
        self.student = User.objects.create_user(
            username='teststudent',
            email='student@test.com',
            password='testpass123',
            role='student'
        )
        self.tutor = User.objects.create_user(
            username='testtutor',
            email='tutor@test.com',
            password='testpass123',
            role='tutor'
        )

    def test_user_creation(self):
        self.assertEqual(self.student.role, 'student')
        self.assertEqual(self.tutor.role, 'tutor')
        self.assertTrue(self.student.check_password('testpass123'))
        self.assertTrue(self.tutor.check_password('testpass123'))

    def test_profile_creation(self):
        # Profiles should be created automatically via signals or in serializer
        self.assertTrue(hasattr(self.student, 'student_profile'))
        self.assertTrue(hasattr(self.tutor, 'tutor_profile'))

class AuthenticationAPITest(APITestCase):
    def setUp(self):
        self.register_url = reverse('register')
        self.login_url = reverse('login')
        self.me_url = reverse('me')

    def test_user_registration(self):
        data = {
            'username': 'newuser',
            'email': 'newuser@test.com',
            'password': 'testpass123',
            'role': 'student'
        }
        response = self.client.post(self.register_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['role'], 'student')

    def test_user_login(self):
        # Create user first
        user = User.objects.create_user(
            username='loginuser',
            email='loginuser@test.com',
            password='testpass123',
            role='student'
        )
        
        data = {
            'username': 'loginuser',
            'password': 'testpass123'
        }
        response = self.client.post(self.login_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_me_endpoint_authenticated(self):
        user = User.objects.create_user(
            username='meuser',
            email='meuser@test.com',
            password='testpass123',
            role='tutor'
        )
        token = RefreshToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'meuser')
        self.assertEqual(response.data['role'], 'tutor')

    def test_me_endpoint_unauthenticated(self):
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

class RoleBasedPermissionsTest(APITestCase):
    def setUp(self):
        self.student = User.objects.create_user(
            username='student',
            email='student@test.com',
            password='testpass123',
            role='student'
        )
        self.tutor = User.objects.create_user(
            username='tutor',
            email='tutor@test.com',
            password='testpass123',
            role='tutor'
        )
        self.subject = Subject.objects.create(name='Mathematics')
        
        # Profiles are automatically created by signals, no need to create manually
        
        self.lesson_request_url = reverse('lesson-requests')
        self.lesson_request_update_url = reverse('lesson-request-update', kwargs={'pk': 1})

    def test_student_can_create_lesson_request(self):
        token = RefreshToken.for_user(self.student)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        
        data = {
            'tutor': self.tutor.id,
            'subject': self.subject.id,
            'start_time': (datetime.now(pytz.UTC) + timedelta(days=1)).isoformat(),
            'duration_minutes': 60
        }
        response = self.client.post(self.lesson_request_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_tutor_cannot_create_lesson_request(self):
        token = RefreshToken.for_user(self.tutor)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        
        data = {
            'tutor': self.tutor.id,
            'subject': self.subject.id,
            'start_time': (datetime.now(pytz.UTC) + timedelta(days=1)).isoformat(),
            'duration_minutes': 60
        }
        response = self.client.post(self.lesson_request_url, data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_tutor_can_update_lesson_request_status(self):
        # Create a lesson request first
        lesson_request = LessonRequest.objects.create(
            student=self.student,
            tutor=self.tutor,
            subject=self.subject,
            start_time=datetime.now(pytz.UTC) + timedelta(days=1),
            duration_minutes=60,
            status='pending'
        )
        
        token = RefreshToken.for_user(self.tutor)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        
        data = {'status': 'approved'}
        response = self.client.patch(
            reverse('lesson-request-update', kwargs={'pk': lesson_request.id}),
            data
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check if status was updated
        lesson_request.refresh_from_db()
        self.assertEqual(lesson_request.status, 'approved')

    def test_student_cannot_update_lesson_request(self):
        # Create a lesson request first
        lesson_request = LessonRequest.objects.create(
            student=self.student,
            tutor=self.tutor,
            subject=self.subject,
            start_time=datetime.now(pytz.UTC) + timedelta(days=1),
            duration_minutes=60,
            status='pending'
        )
        
        token = RefreshToken.for_user(self.student)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        
        data = {'status': 'approved'}
        response = self.client.patch(
            reverse('lesson-request-update', kwargs={'pk': lesson_request.id}),
            data
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

class SubjectAPITest(APITestCase):
    def setUp(self):
        self.subject_url = reverse('subjects')
        self.subject = Subject.objects.create(name='Physics')

    def test_subjects_list_public(self):
        response = self.client.get(self.subject_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Physics')

class TutorAPITest(APITestCase):
    def setUp(self):
        self.tutor_list_url = reverse('tutors')
        self.tutor = User.objects.create_user(
            username='testtutor',
            email='tutor@test.com',
            password='testpass123',
            role='tutor'
        )
        self.subject = Subject.objects.create(name='Chemistry')
        
        # Profile is automatically created by signals, just update it
        self.tutor_profile = self.tutor.tutor_profile
        self.tutor_profile.bio = 'Chemistry expert'
        self.tutor_profile.hourly_rate = Decimal('45.00')
        self.tutor_profile.rating = 4.7
        self.tutor_profile.save()
        self.tutor_profile.subjects.add(self.subject)

    def test_tutors_list_public(self):
        response = self.client.get(self.tutor_list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_tutors_filter_by_subject(self):
        response = self.client.get(f'{self.tutor_list_url}?subject={self.subject.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_tutors_ordering_by_rating(self):
        # Create another tutor with lower rating
        tutor2 = User.objects.create_user(
            username='tutor2',
            email='tutor2@test.com',
            password='testpass123',
            role='tutor'
        )
        
        # Update the automatically created profile
        tutor2_profile = tutor2.tutor_profile
        tutor2_profile.bio = 'Math expert'
        tutor2_profile.hourly_rate = Decimal('40.00')
        tutor2_profile.rating = 4.2
        tutor2_profile.save()
        
        response = self.client.get(f'{self.tutor_list_url}?ordering=-rating')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['results'][0]['rating'], 4.7)
        self.assertEqual(response.data['results'][1]['rating'], 4.2)
