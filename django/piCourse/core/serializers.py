from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import TutorProfile, StudentProfile, Subject, LessonRequest

User = get_user_model()

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    class Meta:
        model = User
        # sadece email, password, role alıyoruz
        fields = ['email', 'password', 'role']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Bu email zaten kayıtlı.")
        return value

    def create(self, validated_data):
        password = validated_data.pop('password')
        role = validated_data.pop('role')
        email = validated_data.get('email')

        # username zorunluysa email'den otomatik username oluştur
        username = email.split('@')[0]

        user = User(
            username=username,
            email=email,
            role=role,
        )
        user.set_password(password)
        user.save()
        return user

class LoginRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

class TokenPairSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()

class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ['id', 'name']

class TutorProfileSerializer(serializers.ModelSerializer):
    subjects = SubjectSerializer(many=True, read_only=False)
    hourly_rate = serializers.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0.00,
        allow_null=False
    )
    rating = serializers.FloatField(default=0.0, allow_null=False)
    bio = serializers.CharField(default='', allow_blank=True, allow_null=False)

    class Meta:
        model = TutorProfile
        fields = ['bio', 'hourly_rate', 'rating', 'subjects']

class StudentProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentProfile
        fields = ['grade_level']

class TutorListSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    subjects = SubjectSerializer(source='tutor_profile.subjects', many=True, read_only=True)
    hourly_rate = serializers.DecimalField(source='tutor_profile.hourly_rate', max_digits=8, decimal_places=2)
    rating = serializers.FloatField(source='tutor_profile.rating')
    bio = serializers.CharField(source='tutor_profile.bio')

    class Meta:
        model = User
        fields = ['id', 'name', 'subjects', 'hourly_rate', 'rating', 'bio']

    def get_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username

class TutorDetailSerializer(TutorListSerializer):
    pass


class LessonRequestSerializer(serializers.ModelSerializer):
    tutor_name = serializers.SerializerMethodField()
    student_name = serializers.SerializerMethodField()
    subject_name = serializers.SerializerMethodField()

    # Açıkça subject alanını tanımlayın
    subject = serializers.PrimaryKeyRelatedField(
        queryset=Subject.objects.all(),
        required=True,
        error_messages={
            'required': 'Konu seçimi zorunludur.',
            'does_not_exist': 'Geçersiz konu seçildi.'
        }
    )

    # Açıkça tutor alanını tanımlayın
    tutor = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role='tutor'),
        required=True,
        error_messages={
            'required': 'Eğitmen seçimi zorunludur.',
            'does_not_exist': 'Geçersiz eğitmen seçildi.'
        }
    )

    class Meta:
        model = LessonRequest
        fields = [
            'id', 'tutor', 'student', 'subject', 'start_time',
            'duration_minutes', 'status', 'note', 'created_at',
            'tutor_name', 'student_name', 'subject_name'
        ]
        read_only_fields = ['id', 'created_at', 'tutor_name', 'student_name', 'subject_name']

    def get_tutor_name(self, obj):
        return f"{obj.tutor.first_name} {obj.tutor.last_name}" if obj.tutor else ""

    def get_student_name(self, obj):
        return f"{obj.student.first_name} {obj.student.last_name}" if obj.student else ""

    def get_subject_name(self, obj):
        return obj.subject.name if obj.subject else ""

    def validate_tutor(self, value):
        if value.role != 'tutor':
            raise serializers.ValidationError("Selected user is not a tutor")
        return value

    def validate_subject(self, value):
        # Tutor bu konuyu öğretiyor mu kontrol et
        tutor_id = self.initial_data.get('tutor')
        if tutor_id:
            try:
                tutor = User.objects.get(id=tutor_id, role='tutor')
                if hasattr(tutor, 'tutor_profile') and value not in tutor.tutor_profile.subjects.all():
                    raise serializers.ValidationError("Tutor does not teach this subject")
            except User.DoesNotExist:
                pass
        return value