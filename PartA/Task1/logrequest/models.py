from django.db import models

# Create your models here.
class Score(models.Model):
    User_ID = models.CharField(max_length=20, verbose_name='User Id')
    Score = models.CharField(max_length=20, verbose_name='Score')

