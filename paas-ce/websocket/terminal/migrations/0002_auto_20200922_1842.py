# Generated by Django 2.2.6 on 2020-09-22 18:42

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('terminal', '0001_initial'),
    ]

    operations = [
        migrations.AlterModelTable(
            name='SessionLog',
            table='control_terminal_log',
        ),
        migrations.CreateModel(
            name='CommandLog',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('datetime', models.DateTimeField(auto_now=True, verbose_name='date time')),
                ('command', models.CharField(max_length=255, verbose_name='command')),
                ('log', models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, to='terminal.SessionLog', verbose_name='Terminal Log')),
            ],
            options={
                'db_table': 'control_command_log',
                'ordering': ['-datetime'],
            },
        ),
    ]
