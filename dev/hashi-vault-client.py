#!/usr/bin/env python3

import argparse
import os
import sys

import hvac

SECRETS_ROOT_PATH = 'secret/stackhpc'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-c', '--ca-cert', type=str, required=False,
        default=os.environ.get('VAULT_CACERT'),
        help=('Path to a CA bundle to use for verification. Enables certificate verification.'))
    parser.add_argument(
        '-s', '--secrets-root-path', type=str,
        default=SECRETS_ROOT_PATH,
        help=('Vault root path under which to store secrets'))
    parser.add_argument(
        '-v', '--verbose', action='store_true',
        help=('Display more details'))
    parser.add_argument(
        '--vault-id', required=True,
        help=('secret name'))

    args = parser.parse_args()

    token = os.environ.get('VAULT_TOKEN', None)
    if token is None and os.environ.get('HOME'):
        token_filename = os.path.join(
            os.environ.get('HOME'),
            '.vault-token'
        )
        if os.path.exists(token_filename):
            with open(token_filename) as token_file:
                token = token_file.read().strip()

    if token is None:
        raise Exception("No Vault Token specified")

    kwargs = {
        'url': os.environ.get('VAULT_ADDR', 'http://127.0.0.1:8200'),
        'token': token,
    }
    if args.ca_cert is not None:
        kwargs['verify'] = args.ca_cert

    client = hvac.Client(**kwargs)

    path = "%s/%s" % (args.secrets_root_path, args.vault_id)
    current = client.read(path)
    if current is None:
        print(f"E: {path} not found in vault")
        return 1

    data = current.get('data', {}).get('value')
    if not data:
        print(f"E: empty value in {path} in vault")
        return 1

    print(f"{data}\n")


if __name__ == '__main__':
    sys.exit(main())

