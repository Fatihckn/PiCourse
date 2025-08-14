from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Subject, TutorProfile, StudentProfile, LessonRequest

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'role', 'is_active', 'date_joined')
    list_filter = ('role', 'is_active', 'date_joined')
    search_fields = ('username', 'email', 'first_name', 'last_name')
    ordering = ('-date_joined',)
    
    fieldsets = UserAdmin.fieldsets + (
        ('Role', {'fields': ('role',)}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Role', {'fields': ('role',)}),
    )

@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name',)
    ordering = ('name',)

@admin.register(TutorProfile)
class TutorProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'hourly_rate', 'rating', 'get_subjects')
    list_filter = ('rating', 'hourly_rate')
    search_fields = ('user__username', 'user__email', 'bio')
    ordering = ('-rating',)
    
    def get_subjects(self, obj):
        return ", ".join([subject.name for subject in obj.subjects.all()])
    get_subjects.short_description = 'Subjects'

@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'grade_level')
    list_filter = ('grade_level',)
    search_fields = ('user__username', 'user__email', 'grade_level')
    ordering = ('user__username',)

@admin.register(LessonRequest)
class LessonRequestAdmin(admin.ModelAdmin):
    list_display = ('student', 'tutor', 'subject', 'start_time', 'duration_minutes', 'status', 'created_at')
    list_filter = ('status', 'subject', 'created_at')
    search_fields = ('student__username', 'tutor__username', 'subject__name')
    ordering = ('-created_at',)
    readonly_fields = ('created_at',)
    
    fieldsets = (
        ('Request Details', {
            'fields': ('student', 'tutor', 'subject', 'start_time', 'duration_minutes')
        }),
        ('Status', {
            'fields': ('status', 'created_at')
        }),
    )


