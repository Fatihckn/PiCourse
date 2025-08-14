from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import StudentProfile, TutorProfile

User = get_user_model()

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """Create user profile when user is created"""
    if created:
        if instance.role == 'student':
            StudentProfile.objects.create(user=instance)
        elif instance.role == 'tutor':
            TutorProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """Save user profile when user is saved"""
    if hasattr(instance, 'student_profile'):
        instance.student_profile.save()
    elif hasattr(instance, 'tutor_profile'):
        instance.tutor_profile.save() 