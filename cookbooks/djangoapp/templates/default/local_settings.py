DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': '<%= node[:dbname] %>',
        'USER': 'postgres',
        'PASSWORD': '<%= node[:postgresql][:password][:postgres] %>',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'autocommit': True,
        }
    }
}