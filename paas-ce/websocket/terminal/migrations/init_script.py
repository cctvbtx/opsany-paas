# Generated by Django 2.2.6 on 2020-10-09 10:25

from django.db import migrations

import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(
    __file__)))
path = os.path.join(os.path.join(BASE_DIR, "utils"), "init_script.py")
path_2 = os.path.join(os.path.join(BASE_DIR, "utils"), "init_script.pyc")


def run_init(apps, schema_editor):
    if os.path.isfile(path):
        command = "python {}".format(path)
    else:
        command = "python {}".format(path_2)
    os.system(command)


class Migration(migrations.Migration):

    dependencies = [
        ('terminal', '0014_commandblockhistory_opt_user'),
    ]

    operations = [
        migrations.RunPython(run_init)
    ]