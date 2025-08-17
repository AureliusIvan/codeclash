from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('problem', '0014_problem_share_submission'),
        ('contest', '0010_auto_20190326_0201'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.CreateModel(
                    name='AntiCheatViolation',
                    fields=[
                        ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                        ('violation_type', models.CharField(max_length=50)),
                        ('violation_details', models.TextField(blank=True)),
                        ('timestamp', models.DateTimeField(auto_now_add=True)),
                        ('ip_address', models.GenericIPAddressField(blank=True, null=True)),
                        ('user_agent', models.TextField(blank=True)),
                        ('contest', models.ForeignKey(on_delete=models.deletion.CASCADE, to='contest.Contest')),
                        ('problem', models.ForeignKey(blank=True, null=True, on_delete=models.deletion.CASCADE, to='problem.Problem')),
                        ('user', models.ForeignKey(on_delete=models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
                    ],
                    options={
                        'db_table': 'anti_cheat_violation',
                        'ordering': ['-timestamp'],
                    },
                ),
            ],
            database_operations=[],
        ),
    ]


