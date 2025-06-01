# api/views.py - Django REST API для книг
from rest_framework import generics, filters
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import api_view
from django_filters.rest_framework import DjangoFilterBackend
from django_filters import rest_framework as django_filters
from django.db.models import Q
from .models import Book, Author
from .serializers import BookSerializer, AuthorSerializer

# =============================================================================
# СЕРИАЛИЗАТОРЫ
# =============================================================================

class AuthorSerializer(serializers.ModelSerializer):
    """Сериализатор для авторов"""
    books_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Author
        fields = ['id', 'name', 'email', 'books_count', 'created_at']
    
    def get_books_count(self, obj):
        """Подсчет количества книг автора"""
        return obj.books.count() if hasattr(obj, 'books') else 0


class BookSerializer(serializers.ModelSerializer):
    """Сериализатор для книг"""
    author_name = serializers.CharField(source='author.name', read_only=True)
    author_email = serializers.CharField(source='author.email', read_only=True)
    
    class Meta:
        model = Book
        fields = [
            'id', 'title', 'author', 'author_name', 'author_email',
            'published_date', 'is_available', 'created_at', 'updated_at'
        ]


class BookDetailSerializer(BookSerializer):
    """Детальный сериализатор для книг"""
    author = AuthorSerializer(read_only=True)
    
    class Meta(BookSerializer.Meta):
        fields = BookSerializer.Meta.fields + ['author']


# =============================================================================
# ФИЛЬТРЫ
# =============================================================================

class BookFilter(django_filters.FilterSet):
    """Кастомные фильтры для книг"""
    
    author_id = django_filters.NumberFilter(field_name='author__id')
    author_name = django_filters.CharFilter(
        field_name='author__name', 
        lookup_expr='icontains'
    )
    is_available = django_filters.BooleanFilter(field_name='is_available')
    published_after = django_filters.DateFilter(
        field_name='published_date', 
        lookup_expr='gte'
    )
    published_before = django_filters.DateFilter(
        field_name='published_date', 
        lookup_expr='lte'
    )
    title_contains = django_filters.CharFilter(
        field_name='title', 
        lookup_expr='icontains'
    )
    
    class Meta:
        model = Book
        fields = ['author_id', 'is_available']


# =============================================================================
# ПАГИНАЦИЯ
# =============================================================================

class BookPagination(PageNumberPagination):
    """Кастомная пагинация для книг"""
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        return Response({
            'links': {
                'next': self.get_next_link(),
                'previous': self.get_previous_link()
            },
            'count': self.page.paginator.count,
            'total_pages': self.page.paginator.num_pages,
            'current_page': self.page.number,
            'page_size': self.page_size,
            'results': data
        })


# =============================================================================
# API VIEWS
# =============================================================================

class BookListAPIView(generics.ListAPIView):
    """
    API endpoint для списка книг
    
    GET /api/books/
    
    Поддерживает:
    - Фильтрацию по author_id и is_available
    - Пагинацию (10 книг на страницу)
    - Поиск по названию и автору
    - Сортировку
    """
    serializer_class = BookSerializer
    pagination_class = BookPagination
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter
    ]
    filterset_class = BookFilter
    search_fields = ['title', 'author__name']
    ordering_fields = ['published_date', 'created_at', 'title']
    ordering = ['-published_date']
    
    def get_queryset(self):
        """
        Оптимизированный QuerySet с предзагрузкой связанных данных
        Решает N+1 проблему
        """
        return Book.objects.select_related('author').all()
    
    def list(self, request, *args, **kwargs):
        """Переопределяем list для добавления метаданных"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Добавляем статистику
        total_count = queryset.count()
        available_count = queryset.filter(is_available=True).count()
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            
            # Добавляем метаданные
            response.data['meta'] = {
                'total_books': total_count,
                'available_books': available_count,
                'unavailable_books': total_count - available_count,
            }
            return response
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class BookDetailAPIView(generics.RetrieveAPIView):
    """
    API endpoint для детальной информации о книге
    
    GET /api/books/{id}/
    """
    queryset = Book.objects.select_related('author')
    serializer_class = BookDetailSerializer


# =============================================================================
# FUNCTION-BASED VIEWS (альтернативная реализация)
# =============================================================================

@api_view(['GET'])
def book_list_view(request):
    """
    Альтернативная реализация через function-based view
    
    GET /api/books/
    
    Параметры:
    - author_id: фильтрация по ID автора
    - is_available: фильтрация по доступности (true/false)
    - page: номер страницы
    - page_size: размер страницы (по умолчанию 10)
    """
    
    # Получаем параметры фильтрации
    author_id = request.GET.get('author_id')
    is_available = request.GET.get('is_available')
    page = int(request.GET.get('page', 1))
    page_size = min(int(request.GET.get('page_size', 10)), 100)
    
    # Строим QuerySet с оптимизацией
    queryset = Book.objects.select_related('author')
    
    # Применяем фильтры
    if author_id:
        try:
            author_id = int(author_id)
            queryset = queryset.filter(author_id=author_id)
        except ValueError:
            return Response({'error': 'Invalid author_id'}, status=400)
    
    if is_available is not None:
        if is_available.lower() in ['true', '1', 'yes']:
            queryset = queryset.filter(is_available=True)
        elif is_available.lower() in ['false', '0', 'no']:
            queryset = queryset.filter(is_available=False)
    
    # Подсчитываем общее количество
    total_count = queryset.count()
    
    # Применяем пагинацию
    start = (page - 1) * page_size
    end = start + page_size
    books = queryset[start:end]
    
    # Сериализуем данные
    serializer = BookSerializer(books, many=True)
    
    # Формируем ответ
    total_pages = (total_count + page_size - 1) // page_size
    
    return Response({
        'count': total_count,
        'total_pages': total_pages,
        'current_page': page,
        'page_size': page_size,
        'next': f"/api/books/?page={page + 1}" if page < total_pages else None,
        'previous': f"/api/books/?page={page - 1}" if page > 1 else None,
        'results': serializer.data
    })


# =============================================================================
# ДОПОЛНИТЕЛЬНЫЕ API ENDPOINTS
# =============================================================================

@api_view(['GET'])
def books_statistics(request):
    """
    Статистика по книгам
    
    GET /api/books/stats/
    """
    from django.db.models import Count, Avg
    
    stats = Book.objects.aggregate(
        total_books=Count('id'),
        available_books=Count('id', filter=Q(is_available=True)),
        total_authors=Count('author_id', distinct=True),
    )
    
    # Топ авторов
    top_authors = Author.objects.annotate(
        books_count=Count('books')
    ).order_by('-books_count')[:5]
    
    stats['top_authors'] = AuthorSerializer(top_authors, many=True).data
    
    return Response(stats)


@api_view(['GET'])
def books_by_year(request):
    """
    Распределение книг по годам
    
    GET /api/books/by-year/
    """
    from django.db.models import Count
    from django.db.models.functions import Extract
    
    books_by_year = Book.objects.annotate(
        year=Extract('published_date', 'year')
    ).values('year').annotate(
        count=Count('id')
    ).order_by('-year')
    
    return Response(list(books_by_year))


# =============================================================================
# URL PATTERNS
# =============================================================================

"""
# urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Class-based views
    path('api/books/', views.BookListAPIView.as_view(), name='book-list'),
    path('api/books/<int:pk>/', views.BookDetailAPIView.as_view(), name='book-detail'),
    
    # Function-based views
    path('api/books/alt/', views.book_list_view, name='book-list-alt'),
    
    # Дополнительные endpoints
    path('api/books/stats/', views.books_statistics, name='books-stats'),
    path('api/books/by-year/', views.books_by_year, name='books-by-year'),
]
"""

# =============================================================================
# ПРИМЕРЫ ЗАПРОСОВ
# =============================================================================

"""
Примеры API запросов:

1. Все книги (первая страница):
GET /api/books/

2. Фильтрация по автору:
GET /api/books/?author_id=1

3. Только доступные книги:
GET /api/books/?is_available=true

4. Комбинированная фильтрация:
GET /api/books/?author_id=1&is_available=true

5. Пагинация:
GET /api/books/?page=2&page_size=5

6. Поиск:
GET /api/books/?search=Python

7. Сортировка:
GET /api/books/?ordering=-published_date

8. Детальная информация:
GET /api/books/1/

9. Статистика:
GET /api/books/stats/

Ответ будет в формате:
{
    "count": 150,
    "total_pages": 15,
    "current_page": 1,
    "page_size": 10,
    "next": "/api/books/?page=2",
    "previous": null,
    "meta": {
        "total_books": 150,
        "available_books": 140,
        "unavailable_books": 10
    },
    "results": [
        {
            "id": 1,
            "title": "Django for Beginners",
            "author": 2,
            "author_name": "William S. Vincent",
            "author_email": "william@example.com",
            "published_date": "2021-03-15",
            "is_available": true,
            "created_at": "2025-05-28T10:00:00Z",
            "updated_at": "2025-05-28T10:00:00Z"
        }
    ]
}
""" 