# -*- coding: utf-8 -*-

from esb.utils import SmartHost


# 系统名的小写形式要与系统包名保持一致
SYSTEM_NAME = 'rbac'

host = SmartHost(
    # 需要填入系统正式环境的域名地址
    host_prod='dev.opsany.cn',
)
# -*- coding: utf-8 -*-

base_api_url = "/t/rbac/api/rbac/v0_1/"
