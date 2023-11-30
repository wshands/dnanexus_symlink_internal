import boto3
from botocore.exceptions import ClientError
import dxpy
import json

def get_secret():

    secret_name = "migration_dependencies_contributor_token"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    # Decrypts secret using the associated KMS key.
    secret = json.loads(get_secret_value_response['SecretString'])['DNANexus_migration_dependencies_Contribute_token']
    return secret

def login(token):
    try:
        dxpy.set_api_server_info(host='api.dnanexus.com', protocol='https')
        dxpy.set_security_context({"auth_token_type": "Bearer", "auth_token": token})
        dxpy.set_workspace_id(None)
        print('Logged as', dxpy.whoami())
    except dxpy.exceptions.InvalidAuthentication as e:
        print('Login failed!')
        print(e)
        exit(1)
        
