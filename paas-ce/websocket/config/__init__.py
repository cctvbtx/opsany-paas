# -*- coding: utf-8 -*-
from __future__ import absolute_import

__all__ = ['celery_app', 'RUN_VER', 'APP_CODE', 'SECRET_KEY', 'BK_URL', 'BASE_DIR', 'ESB_BASE_URL']

import os

# This will make sure the app is always imported when
# Django starts so that shared_task will use this app.
from blueapps.core.celery import celery_app

# app 基本信息

# SaaS运行版本，如非必要请勿修改
RUN_VER = 'open'
# SaaS应用ID
APP_CODE = 'control'
# SaaS安全密钥，注意请勿泄露该密钥
SECRET_KEY = '9f9f7d93-990a-4719-a7aa-ea219e647d33'
# 运维平台URL

BK_URL = "https://dev.opsany.cn"
# ESB基础URL
ESB_BASE_URL = "https://dev.opsany.cn"

# RosterFileUrl  default="/etc/salt/roster"
ROSTER_FILE_URL = '/etc/salt/roster'
# Salt-Ssh秘钥存放路径
SALT_SSH_FILE_URL = '/etc/salt/pki/master/ssh'

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(
    __file__)))
TMP_DIR = os.path.join(BASE_DIR, 'tmp')

