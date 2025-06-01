# queries.py - Оптимизированные запросы для Django
from datetime import date
from django.db import models
from django.db.models import Count, Q
from .models import Author, Book

class BookQuerySet(models.QuerySet):
    """Кастомный QuerySet для оптимизации запросов к книгам"""
    
    def with_authors(self):
        """Предварительная загрузка авторов для избежания N+1 проблемы"""
        return self.select_related('author')
    
    def available(self):
        """Только доступные книги"""
        return self.filter(is_available=True)
    
    def by_author(self, author_id):
        """Фильтрация по автору"""
        return self.filter(author_id=author_id)

class BookManager(models.Manager):
    """Кастомный менеджер для модели Book"""
    
    def get_queryset(self):
        return BookQuerySet(self.model, using=self._db)
    
    def with_authors(self):
        return self.get_queryset().with_authors()
    
    def available(self):
        return self.get_queryset().available()

# Добавляем менеджер к модели Book (в реальном проекте это в models.py)
# Book.objects = BookManager()

# =============================================================================
# РЕШЕНИЯ ЗАДАНИЙ
# =============================================================================

def get_books_after_2020():
    """
    Задача 1: Возвращает все книги, опубликованные после 2020 года
    """
    return Book.objects.filter(
        published_date__gt=date(2020, 12, 31)
    ).select_related('author')  # Оптимизация: предзагрузка авторов


def get_authors_with_many_books():
    """
    Задача 2: Возвращает авторов, у которых больше 3 книг
    """
    return Author.objects.annotate(
        books_count=Count('books')
    ).filter(
        books_count__gt=3
    ).prefetch_related('books')  # Оптимизация: предзагрузка книг


def get_books_with_authors_optimized():
    """
    Задача 3: Оптимизированный запрос для избежания N+1 проблемы
    При получении списка книг с их авторами
    """
    return Book.objects.select_related('author').all()


# =============================================================================
# ДОПОЛНИТЕЛЬНЫЕ ОПТИМИЗИРОВАННЫЕ ЗАПРОСЫ
# =============================================================================

def get_books_with_filters(author_id=None, is_available=None):
    """
    Универсальная функция для фильтрации книг
    Используется в API endpoint
    """
    queryset = Book.objects.select_related('author')
    
    if author_id is not None:
        queryset = queryset.filter(author_id=author_id)
    
    if is_available is not None:
        queryset = queryset.filter(is_available=is_available)
    
    return queryset


def get_books_statistics():
    """
    Статистика по книгам (для дашбордов)
    """
    from django.db.models import Count, Avg
    
    stats = Book.objects.aggregate(
        total_books=Count('id'),
        available_books=Count('id', filter=Q(is_available=True)),
        unavailable_books=Count('id', filter=Q(is_available=False)),
        authors_count=Count('author_id', distinct=True),
        avg_books_per_author=Avg('author__books_count')
    )
    
    return stats


def get_recent_books(days=30):
    """
    Книги, добавленные за последние N дней
    """
    from datetime import datetime, timedelta
    
    cutoff_date = datetime.now() - timedelta(days=days)
    
    return Book.objects.filter(
        created_at__gte=cutoff_date
    ).select_related('author').order_by('-created_at')


def get_popular_authors():
    """
    Авторы с наибольшим количеством доступных книг
    """
    return Author.objects.annotate(
        available_books_count=Count(
            'books', 
            filter=Q(books__is_available=True)
        )
    ).filter(
        available_books_count__gt=0
    ).order_by('-available_books_count')


# =============================================================================
# ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
# =============================================================================

def examples():
    """Примеры использования оптимизированных запросов"""
    
    # ❌ ПЛОХО - N+1 проблема
    # for book in Book.objects.all():
    #     print(f"{book.title} by {book.author.name}")  # Запрос к БД на каждой итерации!
    
    # ✅ ХОРОШО - один запрос с JOIN
    for book in get_books_with_authors_optimized():
        print(f"{book.title} by {book.author.name}")  # Данные уже загружены
    
    # Книги после 2020 года
    recent_books = get_books_after_2020()
    print(f"Книг после 2020: {recent_books.count()}")
    
    # Продуктивные авторы
    productive_authors = get_authors_with_many_books()
    for author in productive_authors:
        print(f"{author.name}: {author.books_count} книг")
    
    # Фильтрация для API
    filtered_books = get_books_with_filters(
        author_id=1, 
        is_available=True
    )
    
    return {
        'recent_books': recent_books,
        'productive_authors': productive_authors,
        'filtered_books': filtered_books
    } 