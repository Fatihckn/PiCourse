from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle, ScopedRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from rest_framework import generics, filters
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import Subject, User, LessonRequest
from .serializers import (
    UserRegistrationSerializer,
    TutorProfileSerializer,
    StudentProfileSerializer, SubjectSerializer, TutorListSerializer, TutorDetailSerializer, LessonRequestSerializer,
    TokenPairSerializer, LoginRequestSerializer,
)


@extend_schema(
    request=UserRegistrationSerializer,
    responses={201: UserRegistrationSerializer},
)
@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AnonRateThrottle])
def register(request):
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            'message': 'User registered successfully',
            'user': {
                'username': user.username,
                'email': user.email,
                'role': user.role
            }
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(
    request=LoginRequestSerializer,
    responses={200: TokenPairSerializer, 400: OpenApiResponse(description='Invalid payload'),
               401: OpenApiResponse(description='Invalid credentials')}
)
@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([AnonRateThrottle])
def login(request):
    identifier = request.data.get('email') or request.data.get('username')
    password = request.data.get('password')

    if not identifier or not password:
        return Response({'error': 'Email/username and password required'}, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=identifier, password=password)
    if not user:
        try:
            user_obj = User.objects.get(email=identifier)
            user = authenticate(username=user_obj.username, password=password)
        except User.DoesNotExist:
            user = None

    if user:
        refresh = RefreshToken.for_user(user)
        return Response({'access': str(refresh.access_token), 'refresh': str(refresh)})
    return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def me(request):
    user = request.user

    if request.method == 'GET':
        data = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
        }
        if user.role == 'tutor' and hasattr(user, 'tutor_profile'):
            tutor_data = TutorProfileSerializer(user.tutor_profile).data
            data['profile'] = tutor_data
        elif user.role == 'student' and hasattr(user, 'student_profile'):
            student_data = StudentProfileSerializer(user.student_profile).data
            data['profile'] = student_data

        return Response(data)



    elif request.method == 'PATCH':

        if user.role == 'tutor':

            # User bilgilerini güncelle

            if 'first_name' in request.data:
                user.first_name = request.data['first_name']

            if 'last_name' in request.data:
                user.last_name = request.data['last_name']

            user.save()

            # Tutor profil bilgilerini güncelle

            if 'profile' in request.data:

                # Eğer tutor_profile yoksa oluştur
                if not hasattr(user, 'tutor_profile'):
                    from .models import TutorProfile
                    TutorProfile.objects.create(user=user)

                profile_data = request.data['profile'].copy()

                # subjects alanını ayrı işle
                subjects = profile_data.pop('subjects', [])

                profile_serializer = TutorProfileSerializer(
                    user.tutor_profile,
                    data=profile_data,
                    partial=True
                )

                if profile_serializer.is_valid():
                    profile = profile_serializer.save()

                    # subjects alanını manuel olarak güncelle
                    if subjects:
                        profile.subjects.set(subjects)

                    return Response({'message': 'Profile updated'})
                return Response(profile_serializer.errors, status=400)

            return Response({'message': 'Profile updated'})


        elif user.role == 'student':

            # Student profil güncelleme (mevcut kod)
            if hasattr(user, 'student_profile'):

                profile_serializer = StudentProfileSerializer(
                    user.student_profile,
                    data=request.data.get('profile', {}),
                    partial=True
                )

                if profile_serializer.is_valid():
                    profile_serializer.save()

                    return Response({'message': 'Profile updated'})

                return Response(profile_serializer.errors, status=400)

        return Response({'error': 'Profile not found'}, status=400)


class SubjectListView(generics.ListAPIView):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer
    permission_classes = []


class TutorListView(generics.ListAPIView):
    serializer_class = TutorListSerializer
    permission_classes = []
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['tutor_profile__subjects']
    search_fields = ['first_name', 'last_name', 'tutor_profile__bio']
    ordering_fields = ['tutor_profile__rating']
    ordering = ['-tutor_profile__rating']

    def get_queryset(self):
        queryset = User.objects.filter(role='tutor').select_related('tutor_profile').prefetch_related(
            'tutor_profile__subjects')

        subject_id = self.request.query_params.get('subject')
        if subject_id:
            queryset = queryset.filter(tutor_profile__subjects=subject_id)
        return queryset


class TutorDetailView(generics.RetrieveAPIView):
    serializer_class = TutorDetailSerializer
    permission_classes = []

    def get_queryset(self):
        return User.objects.filter(role='tutor').select_related('tutor_profile')


class LessonRequestListCreateView(generics.ListCreateAPIView):
    serializer_class = LessonRequestSerializer
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]  
    throttle_scope = 'lesson_request'

    def get_queryset(self):
        user = self.request.user
        role = self.request.query_params.get('role', user.role)
        status_filter = self.request.query_params.get('status')

        if role == 'student':
            qs = LessonRequest.objects.filter(student=user)
        else:
            qs = LessonRequest.objects.filter(tutor=user)

        if status_filter:
            qs = qs.filter(status=status_filter)

        return qs

    def create(self, request, *args, **kwargs):
        print("=== CREATE METHOD CALLED ===")
        print(f"Request data: {request.data}")
        print(f"User: {request.user}")
        print(f"User role: {request.user.role}")

        if request.user.role != 'student':
            return Response({'error': 'Only students can create requests'},
                            status=status.HTTP_403_FORBIDDEN)

        # Veriyi kopyala ve düzenle
        data = request.data.copy()

        # Öğrenciyi otomatik ata
        data['student'] = request.user.id

        # Frontend'den gelen 'tutor' field'ını kontrol et
        if 'tutor' in data:
            try:
                tutor = User.objects.get(id=data['tutor'], role='tutor')
                data['tutor'] = tutor.id
            except User.DoesNotExist:
                return Response({'error': 'Tutor not found'},
                                status=status.HTTP_400_BAD_REQUEST)

        # Frontend'den gelen 'subject' field'ını kontrol et
        if 'subject' in data:
            try:
                subject = Subject.objects.get(id=data['subject'])
                data['subject'] = subject.id
            except Subject.DoesNotExist:
                return Response({'error': 'Subject not found'},
                                status=status.HTTP_400_BAD_REQUEST)

        print(f"Modified data: {data}")

        serializer = self.get_serializer(data=data)
        print(f"Serializer validation: {serializer.is_valid()}")

        if not serializer.is_valid():
            print(f"Serializer errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            serializer.save()
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            print(f"Exception during save: {e}")
            print(f"Exception type: {type(e)}")
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class LessonRequestUpdateView(generics.UpdateAPIView):
    queryset = LessonRequest.objects.all()
    serializer_class = LessonRequestSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['patch']

    def update(self, request, *args, **kwargs):
        lesson_request = self.get_object()

        if request.user != lesson_request.tutor:
            return Response({'error': 'Only tutor can update'}, status=403)

        if 'status' not in request.data:
            return Response({'error': 'Only status can be updated'}, status=400)

        return super().update(request, *args, **kwargs)
