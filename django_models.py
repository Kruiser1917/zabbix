# models.py
from django.db import models
from django.core.validators import EmailValidator

class Author(models.Model):
    name = models.CharField(max_length=100, db_index=True)
    email = models.EmailField(unique=True, validators=[EmailValidator()])
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'authors'
        ordering = ['name']
        
    def __str__(self):
        return self.name

class Book(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    author = models.ForeignKey(
        Author, 
        on_delete=models.CASCADE, 
        related_name='books'
    )
    published_date = models.DateField(db_index=True)  # Добавлен индекс для фильтрации
    is_available = models.BooleanField(default=True, db_index=True)  # Индекс для фильтрации
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'books'
        ordering = ['-published_date']
        indexes = [
            models.Index(fields=['published_date']),
            models.Index(fields=['is_available']),
            models.Index(fields=['author', 'published_date']),  # Составной индекс
        ]
        
    def __str__(self):
        return f"{self.title} by {self.author.name}" 