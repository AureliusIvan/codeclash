from utils.shortcuts import get_env

INSTALLED_APPS = [
    'corsheaders',
]


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

# Allow additional hosts from environment variable for development
EXTRA_ALLOWED_HOSTS = get_env("EXTRA_ALLOWED_HOSTS", "").split(",") if get_env("EXTRA_ALLOWED_HOSTS") else []
EXTRA_CSRF_ORIGINS = get_env("EXTRA_CSRF_ORIGINS", "").split(",") if get_env("EXTRA_CSRF_ORIGINS") else []

ALLOWED_HOSTS = ["www.codeclash.page", "codeclash.page", "backend.codeclash.page", "localhost", "127.0.0.1"] + [h.strip() for h in EXTRA_ALLOWED_HOSTS if h.strip()]
CSRF_TRUSTED_ORIGINS = ["https://www.codeclash.page", "https://codeclash.page", "https://backend.codeclash.page", "http://localhost:8000", "http://127.0.0.1:8000"] + [o.strip() for o in EXTRA_CSRF_ORIGINS if o.strip()]

DATA_DIR = "/data"

SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_DOMAIN = None
SESSION_COOKIE_DOMAIN = None

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

#Cors Settings
EXTRA_CORS_ORIGINS = get_env("EXTRA_CORS_ORIGINS", "").split(",") if get_env("EXTRA_CORS_ORIGINS") else []

CORS_ALLOWED_ORIGINS = [
    "https://www.codeclash.page",
    "https://codeclash.page",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "https://backend.codeclash.page",
] + [o.strip() for o in EXTRA_CORS_ORIGINS if o.strip()]

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = False

SESSION_COOKIE_SAMESITE = 'None'
CSRF_COOKIE_SAMESITE = 'None'

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
