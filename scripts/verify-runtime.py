#!/usr/bin/env python3
"""Read a local Docker container and verify the article's runtime contract."""
import argparse
import datetime
import hashlib
import json
import subprocess
import urllib.request
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container', required=True)
    parser.add_argument('--port', required=True, type=int)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--docker-context', default='desktop-linux')
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error('--port must be between 1 and 65535')

    expected = args.source.read_bytes()
    with urllib.request.urlopen(f'http://127.0.0.1:{args.port}/', timeout=5) as response:
        status, actual = response.status, response.read()
    result = subprocess.run(
        ['docker', '--context', args.docker_context, 'container', 'inspect', args.container],
        check=True, capture_output=True, text=True, timeout=10,
    )
    container = json.loads(result.stdout)[0]
    config, host = container['Config'], container['HostConfig']
    process = (config.get('Entrypoint') or []) + (config.get('Cmd') or [])
    ports = container['NetworkSettings']['Ports']
    checks = {
        'http_200': status == 200,
        'response_matches_source': actual == expected,
        'running': container['State']['Running'],
        'non_root_user': config['User'] == '10001:10001',
        'expected_process': process == [
            'python', '-m', 'http.server', '8080', '--bind', '0.0.0.0', '--directory', '/site'
        ],
        'read_only_root': host['ReadonlyRootfs'],
        'all_capabilities_dropped': host['CapDrop'] == ['ALL'],
        'no_new_privileges': 'no-new-privileges:true' in (host['SecurityOpt'] or []),
        'no_mounts': container['Mounts'] == [],
        'only_loopback_port': ports == {
            '8080/tcp': [{'HostIp': '127.0.0.1', 'HostPort': str(args.port)}]
        },
    }
    report = {
        'observed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'checks': checks,
        'source_sha256': hashlib.sha256(expected).hexdigest(),
        'image_config_id': container['Image'],
        'all_passed': all(checks.values()),
    }
    print(json.dumps(report, indent=2))
    return 0 if report['all_passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
