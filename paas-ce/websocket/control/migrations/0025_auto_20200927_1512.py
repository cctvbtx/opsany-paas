# Generated by Django 2.2.6 on 2020-09-27 15:12

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('control', '0024_auto_20200927_1511'),
    ]

    operations = [
        migrations.AlterField(
            model_name='agentvariablemodel',
            name='agent',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='agent_variable', to='control.AgentAdmin'),
        ),
    ]