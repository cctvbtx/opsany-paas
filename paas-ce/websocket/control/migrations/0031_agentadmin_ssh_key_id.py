# Generated by Django 2.2.6 on 2020-11-10 17:27

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('control', '0030_auto_20201105_1444'),
    ]

    operations = [
        migrations.AddField(
            model_name='agentadmin',
            name='ssh_key_id',
            field=models.CharField(default='', max_length=20),
        ),
    ]
