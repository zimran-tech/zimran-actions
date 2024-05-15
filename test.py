import os

env_1 = os.getenv('SECRETS')

if __name__ == '__main__':
    print(f'env_1: {env_1}')
