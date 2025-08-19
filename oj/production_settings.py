from utils.shortcuts import get_env

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'HOST': get_env("POSTGRES_HOST", "oj-postgres"),
        'PORT': get_env("POSTGRES_PORT", "5432"),
        'NAME': get_env("POSTGRES_DB", "onlinejudge"),
        'USER': get_env("POSTGRES_USER", "onlinejudge"),
        'PASSWORD': get_env("POSTGRES_PASSWORD", "onlinejudge")
    }
}

REDIS_CONF = {
    "host": get_env("REDIS_HOST", "oj-redis"),
    "port": get_env("REDIS_PORT", "6379")
}

DEBUG = False

ALLOWED_HOSTS = ["www.codeclash.page", "codeclash.page", "backend.codeclash.page"]
CSRF_TRUSTED_ORIGINS = ["https://www.codeclash.page", "https://codeclash.page", "https://backend.codeclash.page"]

DATA_DIR = "/data"

SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_DOMAIN = None
SESSION_COOKIE_DOMAIN = None

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

#Cors Settings
CORS_ALLOWED_ORIGINS = [
    "https://www.codeclash.page",
    "https://codeclash.page",
]

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = False

CORS_ALLOWED_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',  
    'x-requested-with',
]
