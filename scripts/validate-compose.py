#!/usr/bin/env python3
from pathlib import Path
import sys

try:
    import yaml
except ImportError as exc:
    print(f"PyYAML unavailable: {exc}", file=sys.stderr)
    raise SystemExit(2)

infra = Path(__file__).resolve().parents[1]
root = infra.parent
compose_path = infra / 'docker' / 'docker-compose.yml'
compose = yaml.safe_load(compose_path.read_text())
services = compose.get('services', {})
failures = []

for name, service in services.items():
    build = service.get('build')
    if not isinstance(build, dict):
        continue
    context = (compose_path.parent / build['context']).resolve()
    dockerfile = (context / build.get('dockerfile', 'Dockerfile')).resolve()
    if not context.exists():
        failures.append(f'{name}: missing build context {context}')
    if not dockerfile.exists():
        failures.append(f'{name}: missing Dockerfile {dockerfile}')

for name, service in services.items():
    for dependency in service.get('depends_on', {}) or {}:
        if dependency not in services:
            failures.append(f'{name}: missing dependency service {dependency}')

for name, service in services.items():
    env_files = service.get('env_file', []) or []
    if isinstance(env_files, str):
        env_files = [env_files]
    for env_file in env_files:
        path = (compose_path.parent / env_file).resolve()
        if not path.exists() and not path.name.endswith('.example'):
            print(f'NOTICE missing runtime env file: {name}: {path}')

print(f'compose_services={len(services)}')
print(f'compose_volumes={len(compose.get("volumes", {}))}')
print(f'compose_networks={len(compose.get("networks", {}))}')
if failures:
    print('\n'.join(failures), file=sys.stderr)
    raise SystemExit(1)
print('compose_static_validation=PASS')
