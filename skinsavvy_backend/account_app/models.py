from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager

# Create your models here.
class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email adresi zorunludur.')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password) 
        user.save(using=self._db)
        return user
    
    # ... create_superuser metodu da eklenmeli ...

# 2. Özel Kullanıcı Modeli
class AccountUser(AbstractBaseUser):
       
    email = models.EmailField(verbose_name='email adresi', unique=True, max_length=60)
    username = models.CharField(max_length=30, unique=True) 
    date_joined = models.DateTimeField(verbose_name='kayıt tarihi', auto_now_add=True)
    is_admin = models.BooleanField(default=False)
    is_active = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    
    objects = UserManager() 
    
    USERNAME_FIELD = 'email' 
    REQUIRED_FIELDS = ['username'] 