# Generated by Django 2.2.6 on 2020-11-19 22:26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('terminal', '0011_auto_20201113_0014'),
    ]

    operations = [
        migrations.AddField(
            model_name='sessionlog',
            name='height',
            field=models.PositiveIntegerField(default=768, verbose_name='Height'),
        ),
        migrations.AddField(
            model_name='sessionlog',
            name='width',
            field=models.PositiveIntegerField(default=1024, verbose_name='Width'),
        ),
    ]
