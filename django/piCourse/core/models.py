from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (
        ('student', 'Student'),
        ('tutor', 'Tutor'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    def __str__(self):
        return f"{self.username} ({self.role})"

class Subject(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name

class TutorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="tutor_profile")
    bio = models.TextField(blank=True)
    hourly_rate = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    rating = models.FloatField(default=0)
    subjects = models.ManyToManyField(Subject, related_name="tutors", blank=True)

    def __str__(self):
        return f"Tutor: {self.user.username}"

class StudentProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="student_profile")
    grade_level = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return f"Student: {self.user.username}"


class LessonRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]

    tutor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lesson_requests_as_tutor')
    student = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lesson_requests_as_student')
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    start_time = models.DateTimeField()
    duration_minutes = models.IntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    note = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'lesson_requests'

    def __str__(self):
        return f"{self.student} - {self.tutor} - {self.subject} - {self.start_time}"