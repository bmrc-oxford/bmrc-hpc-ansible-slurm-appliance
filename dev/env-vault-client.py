#!/usr/bin/python3

import argparse
import os
import sys

def main():

  parser = argparse.ArgumentParser(description='Get ansible vault password from environment')
  parser.add_argument('--vault-id', required=True, help='name of the vault secret (VAULT_<SECRET>_PASSWORD env var)')

  args = parser.parse_args()

  secret = args.vault_id.upper()

  env_name = f"VAULT_{secret}_PASSWORD"
  secret = os.environ.get(env_name)

  if not secret:
      print(f"E: env variable {env_name} is not set", file=sys.stderr)
      return 1

  sys.stdout.write(f"{secret}\n")


if __name__ == '__main__':
    sys.exit(main())
