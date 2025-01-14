#! /usr/bin/python3
# -*- coding: utf8 -*-
"""
执行前请执行
/bin/cp -r ../paas-ce/saas/saas-logo/* /opt/opsany/uploads/workbench/icon/
/bin/cp -r ../paas-ce/saas/saas-logo/* /opt/opsany-paas/paas-ce/paas/paas/media/applogo/
"""


import time

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
import argparse


class InitData:
    # 导航分组
    NAV_GROUP = {
        "group_name": "应用管理",
        "nav_list": [
            {
                "nav_name": "应用平台",
                "nav_url": "/o/devops/",
                "describe": "应用DevOps平台",
                "group_name": "应用管理",
                "icon_name": "devops.png"
            },
            {
                "nav_name": "流水线",
                "nav_url": "/o/pipeline/",
                "describe": "流水线编排",
                "group_name": "应用管理",
                "icon_name": "pipeline.png"
            },
            {
                "nav_name": "持续部署",
                "nav_url": "/o/deploy/",
                "describe": "部署编排灵活",
                "group_name": "应用管理",
                "icon_name": "deploy.png"
            },
        ]
    }

class StackStormApi:
    def __init__(self, st2_url, st2_username, st2_password, timeout=8):
        self.url = st2_url
        self.username = st2_username
        self.password = st2_password
        self.timeout = timeout
        self.AUTH_TOKENS = "auth/tokens/"  # 登录 POST
        self.API_KEYS = "api/v1/apikeys/"  # api key list GET POST
        self.GET_PACK = "/api/v1/packs/{ref_or_id}"
        self.EXECUTION_LOG = "/api/v1/executions/{execution_id}/"
        self.INSTALL_PACK = "/api/v1/packs/install"
        self.CONFIG_PACK = "/api/v1/configs/{ref_or_id}"

        self.headers = {
            'accept': 'application/json'
        }

    def get_token(self):
        """Login and get token"""
        try:
            req = requests.session()
            req.auth = (self.username, self.password)
            url = self.url + self.AUTH_TOKENS
            headers = {
                'accept': 'application/json'
            }
            res = req.post(url, headers=headers, timeout=self.timeout, verify=False)
            if res.status_code == 200 or res.status_code == 201:
                return True, res.json().get("token")

            else:
                return False, res.json()
        except Exception as e:
            return False, e

    def update_headers(self):
        """update headers token"""
        status, message = self.get_token()
        if not status:
            return self.headers
        return self.headers.update({"x-auth-token": message})

    def get_api_keys_list(self, kwargs=None):
        """get api key list"""
        try:
            url = self.url + self.API_KEYS
            params = {
                "offset": 0,
                "limit": 10
            }
            if kwargs:
                params.update(kwargs)
            self.update_headers()
            res = requests.get(url, headers=self.headers, timeout=self.timeout, params=params, verify=False)
            res.encoding = 'utf-8'
            if res.status_code == 200 or res.status_code == 204:
                return True, res.json()
            else:
                return False, res.json()
        except Exception as e:
            return False, e

    def get_pack(self, name):
        """get pack"""
        try:
            url = self.url + self.GET_PACK.format(ref_or_id=name)
            self.update_headers()
            res = requests.get(url, headers=self.headers, timeout=self.timeout, verify=False)
            res.encoding = 'utf-8'
            if res.status_code == 200:
                return True, res.json()
            else:
                return False, res.json()
        except Exception as e:
            return False, e

    def get_workflow_execution_log(self, execution_id):
        """get execution log"""
        try:
            url = self.url + self.EXECUTION_LOG.format(execution_id=execution_id)
            self.update_headers()
            res = requests.get(url, headers=self.headers, timeout=5, verify=False)
            res.encoding = 'utf-8'
            if res.status_code == 200:
                return True, res.json()
            else:
                return False, res.json()
        except Exception as e:
            return False, str(e)

    def create_api_key(self, metadata=None, enabled=True, user="st2admin"):
        """create api key"""
        try:
            url = self.url + self.API_KEYS
            # {"name": "OpsAny-Devops", "used_by": "OpsAny-Devops", "why": "OpsAny Devops StackStorm Service Login header (st2-api-key) Can Not Delete."}
            # api_key = res_dict.get("key", "")
            data_dic = {
                "metadata": metadata if metadata else {},
                "enabled": enabled if enabled else True,
                "user": user
            }
            data_dic = json.dumps(data_dic)
            self.update_headers()
            res = requests.post(url, headers=self.headers, timeout=self.timeout, data=data_dic, verify=False)
            res.encoding = 'utf-8'
            if res.status_code == 201:
                return True, res.json()
            else:
                return False, res.json()

        except Exception as e:
            return False, e

    def install_pack(self, packs):
        """install pack"""
        try:
            url = self.url + self.INSTALL_PACK
            data_dic = {
                "packs": packs
            }
            data_dic = json.dumps(data_dic)
            status, message = self.get_token()
            if not status:
                return False, message
            self.headers.update({"x-auth-token": message})
            res = requests.post(url, headers=self.headers, timeout=self.timeout, data=data_dic, verify=False)
            res.encoding = 'utf-8'

            if res.status_code == 202:
                return True, res.json()
            else:
                return False, res.json()
        except Exception as e:
            return 0, e

    def config_pack(self, pack, api_url, app_code, app_secret, access_token):
        """config pack"""
        try:
            url = self.url + self.CONFIG_PACK.format(ref_or_id=pack)
            data_dic = {
                "api_url": api_url,
                "app_code": app_code,
                "app_secret": app_secret,
                "access_token": access_token
            }
            data_dic = json.dumps(data_dic)
            status, message = self.get_token()
            if not status:
                return False, message
            self.headers.update({"x-auth-token": message})
            res = requests.put(url, headers=self.headers, timeout=self.timeout, data=data_dic, verify=False)
            res.encoding = 'utf-8'

            if res.status_code == 200:
                return True, res.json()
            else:
                return False, res.json()
        except Exception as e:
            return False, e


class OpsAnyApi:
    def __init__(self, paas_domain, username, password, st2_url, st2_username, st2_password):
        self.paas_domain = paas_domain
        self.session = requests.Session()
        self.session.headers.update({'referer': paas_domain})
        self.session.verify = False
        self.login_url = self.paas_domain + "/login/"
        self.csrfmiddlewaretoken = self.get_csrftoken()
        self.username = username
        self.password = password
        self.st2_url = st2_url
        self.st2_api = StackStormApi(st2_url, st2_username, st2_password)
        self.token = self.login()

    def get_csrftoken(self):
        try:
            resp = self.session.get(self.login_url, verify=False)
            if resp.status_code == 200:
                return resp.cookies["bklogin_csrftoken"]
            else:
                return ""
        except:
            return ""

    def login(self):
        try:
            login_form = {
                'csrfmiddlewaretoken': self.csrfmiddlewaretoken,
                'username': self.username,
                'password': self.password
            }
            resp = self.session.post(self.login_url, data=login_form, verify=False)
            if resp.status_code == 200:
                return self.session.cookies.get("bk_token")
            return ""
        except:
            return False

    def init_devops_st2(self):
        """init devops st2 server"""
        try:
            API = "/o/devops//api/devops/v0_1/config-stackstorm/"
            URL = self.paas_domain + API
            metadata = {"name": "OpsAny-Devops", "used_by": "OpsAny-Devops",
                        "why": "OpsAny Devops StackStorm Service Login header (st2-api-key) Can Not Delete."}
            status, api_token = self.st2_api.create_api_key(metadata=metadata, enabled=True)
            if not status:
                return False, api_token
            data = {
                "api_addr": self.st2_url,
                "api_token": api_token.get("key", ""),
            }
            response = self.session.post(url=URL, data=json.dumps(data), verify=False)
            if response.status_code == 200:
                return True, response.json()
            else:
                res = {"code": 500, "message": "error", "data": response.status_code}
            if res.get("code") == 200:
                return True, res.get("data") or res.get("message")
            else:
                return False, res.get("data") or res.get("errors") or res.get("message")
        except Exception as e:
            return False, str(e)

    def init_st2_pack(self, opsany_core_pack_path, opsany_workflow_pack_path):
        """install opsany_core and opsany_workflow"""
        pack_url = [opsany_core_pack_path, opsany_workflow_pack_path]
        print("Downloading the OpsAny core package is expected to take 60 seconds...")
        status, message = self.st2_api.install_pack(pack_url)
        # status, message = True, {}
        if not status:
            return False, message
        start_time = time.time()
        while True:
            status, res_dic = self.st2_api.get_workflow_execution_log(message.get("execution_id", ""))
            if not status:
                if status == 0:
                    return False, res_dic
                continue
            if res_dic.get("status") == "succeeded":

                return True, ""
            if res_dic.get("status") in ["failed", "timeout"]:
                try:
                    errors = res_dic.get("result", {}).get("errors", [])[0].get("result").get("stderr", "")
                except:
                    errors = "Install error please contact the developer"
                return False, errors
        end_time = time.time()
        if (end_time - start_time) > 120:
            return False, "The installation time exceeds 120 seconds"
        return True, message

    def config_pack(self, pack, api_url, app_code, app_secret, access_token):
        status, message = self.st2_api.config_pack(pack, api_url, app_code, app_secret, access_token)
        if not status:
            return False, message
        return True, message

    def workbench_add_nav(self):
        """工作台初始化导航菜单"""
        try:
            NAV_API = "/o/workbench//api/workbench/v0_1/update-nav/"
            NAV_GROUP_URL = self.paas_domain + NAV_API

            data = InitData()
            nav_data = data.NAV_GROUP
            nav_data.update({"username": self.username})

            response = self.session.post(url=NAV_GROUP_URL, data=json.dumps(nav_data), verify=False)
            if response.status_code == 200:
                res = response.json()
            else:
                res = {"code": 500, "message": "error", "data": response.status_code}
            if res.get("code") == 200:
                return 1, res.get("data") or res.get("message")
            else:
                return 0, res.get("data") or res.get("errors") or res.get("message")
        except Exception as e:
            return 0, str(e)


def start(paas_domain, username, password, st2_url, st2_username, st2_password):
    run_obj = OpsAnyApi(paas_domain=paas_domain, username=username, password=password, st2_url=st2_url,
                        st2_username=st2_username, st2_password=st2_password)

    # 初始化StackStorm核心包路径
    opsany_core_pack_path = "/opt/stackstorm-packs/opsany_core/"
    opsany_workflow_pack_path = "/opt/stackstorm-packs/opsany_workflow/"
    # 配置核心包参数
    pack = "opsany_core"
    api_url = paas_domain
    app_code = "devops"
    app_secret = "f64f3fae-b335-11eb-a88b-00163e105ceb"
    access_token = "opsany-esb-auth-token-9e8083137204"

    # 1. 初始化应用平台初始化StackStorm服务
    st2_status, st2_message = run_obj.init_devops_st2()
    print("[SUCCESS] init devops st2 success.") if st2_status else print(
        "[ERROR] init devops st2 error, error info: {}".format(str(st2_message)))

    # 2. 初始化StackStorm包 opsany_core, opsany_workflow（需要提前将该两个包放入st2服务器指定路径）
    st2_status, st2_data = run_obj.init_st2_pack(opsany_core_pack_path, opsany_workflow_pack_path)
    print("[SUCCESS] init st2 pack success.") if st2_status else print(
        "[ERROR] init st2 pack error info, error info: {}".format(str(st2_data)))

    # 3. 配置 opsany_core包参数
    st2_status, st2_data = run_obj.config_pack(pack, api_url, app_code, app_secret, access_token)
    print("[SUCCESS] config core pack success.") if st2_status else print(
        "[ERROR] config core pack error info, error info: {}".format(str(st2_data)))

    # 初始化工作台导航目录
    add_nav_status, add_nav_data = run_obj.workbench_add_nav()
    print("[SUCCESS] add nav success") if add_nav_status else print(
        "[ERROR] add nav error, error info: {}".format(add_nav_data))


def add_parameter():
    parameter = argparse.ArgumentParser()
    parameter.add_argument("--domain", help="domain parameters.", required=True)
    parameter.add_argument("--username", help="opsany admin username.", required=True)
    parameter.add_argument("--password", help="opsany admin password.", required=True)
    parameter.add_argument("--st2_url", help="StackStorm service url.", required=True)
    parameter.add_argument("--st2_username", help="StackStorm service username.", required=True)
    parameter.add_argument("--st2_password", help="StackStorm service password.", required=True)
    parameter.parse_args()
    return parameter


if __name__ == '__main__':
    parameter = add_parameter()
    options = parameter.parse_args()
    domain = options.domain
    username = options.username
    password = options.password
    st2_url = options.st2_url
    st2_username = options.st2_username
    st2_password = options.st2_password
    start(domain, username, password, st2_url=st2_url, st2_username=st2_username, st2_password=st2_password)


# python init-ce-devops.py --domain https://www.opsany_url.cn --username opsany_username  --password opsany_password --st2_url https://st2_url/  --st2_username st2admin --st2_password st2_password
