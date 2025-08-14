from django.urls import path
from . import views

urlpatterns = [
    path('auth/register/', views.register, name='register'),
    path('auth/login/', views.login, name='login'),
    path('me/', views.me, name='me'),
    path('subjects/', views.SubjectListView.as_view(), name='subjects'),
    path('tutors/', views.TutorListView.as_view(), name='tutors'),
    path('tutors/<int:pk>/', views.TutorDetailView.as_view(), name='tutor-detail'),
    path('lesson-requests/', views.LessonRequestListCreateView.as_view(), name='lesson-requests'),
    path('lesson-requests/<int:pk>/', views.LessonRequestUpdateView.as_view(), name='lesson-request-update'),
]
