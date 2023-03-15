import requests
import time
import json
import sys
import re


def is_semantic_version(version):
    pattern = r'^(\d+)\.(\d+)\.(\d+)$'
    match = re.match(pattern, version)
    return match is not None


def find_latest_semantic_version(versions):
    semantic_versions = [v for v in versions if is_semantic_version(v)]
    if not semantic_versions:
        return None
    max_version = max(semantic_versions, key=lambda v: tuple(map(int, v.split("."))))
    return max_version


def get_ecr_access_token(ecr_url):
    response = requests.get(ecr_url)
    token = json.loads(response.text)['token']
    return token


def get_ecr_image_tags(adapter_name):
    ecr_access_token = get_ecr_access_token("https://public.ecr.aws/token/")
    headers = {'Authorization': 'Bearer ' + ecr_access_token}
    url = f'https://public.ecr.aws/v2/chainlink/adapters/{adapter_name}-adapter/tags/list'
    response = requests.get(url, headers=headers)
    try:
        version_list = json.loads(response.text)['tags']
        return version_list
    except KeyError:
        return None


def retry(func, max_retries, *args, **kwargs):
    for i in range(max_retries + 1):
        result = func(*args, **kwargs)
        if result is not None:
            return result
        time.sleep(5)
    return None


if __name__ == "__main__":
    # parse input from terraform
    input_json = json.loads(sys.stdin.read())
    adapter_name = input_json.get("adapter_name")

    adapter_versions = retry(get_ecr_image_tags, 5, adapter_name)
    if adapter_versions is None:
        sys.exit(f"Failed to fetch adapter versions from AWS ECR")
    adapter_latest_version = find_latest_semantic_version(adapter_versions)

    output = {
        "latest_version": str(adapter_latest_version)
    }

    output_json = json.dumps(output, indent=2)
    print(output_json)
