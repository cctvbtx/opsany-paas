# Generated by Django 2.2.6 on 2020-11-13 15:36

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('control', '0032_agentadmin_ssh_type'),
    ]

    operations = [
        migrations.CreateModel(
            name='UserAgentModel',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('create_time', models.DateTimeField(auto_now_add=True)),
                ('update_time', models.DateTimeField(auto_now_add=True)),
                ('agent', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='agent_user', to='control.AgentAdmin')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='user_agent', to='control.UserInfo')),
            ],
            options={
                'db_table': 'user_agent',
            },
        ),
    ]