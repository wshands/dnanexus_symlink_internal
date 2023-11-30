import boto3
#from botocore.exceptions import ClientError
import dxpy
import json
#import login_and_get_secret
import os

import sys
      
# https://docs.aws.amazon.com/lambda/latest/dg/python-image.html
search_path = sys.path
print(search_path)

os.listdir(path='.')

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
        

def lambda_handler(event, context):
    #project = "project-GVJq6gQ01Z5KjVbXZ4vq2YKg"
    #drive = "drive-yXxkz987GqPVzQPVvQjpbBKJ"
    #out = "/symlink"

    #project = "project-FPkJ6xj00Y3X88FKJ5Y12bgG" # Research Early Development - Dev
    #drive = "drive-jVv8ZQ7K9pYBJKYyzgbkqJGB"
    project = "project-GYgjXK80Yzg361fY4K7ffqb5" # migration dependencies
    drive = "drive-ypGJzKVXvZYkB7Pq98kQxbjg" # drive in migration dependencies
                                         # with Walts private AWS account credentials

    out = "/symlinks"

    token = login_and_get_secret.get_secret()
    
    print(f"event:{event}")
    bucket = event['Records'][0]['s3']['bucket']['name']
    region = event['Records'][0]['awsRegion']
    key = event['Records'][0]['s3']['object']['key']
    name = os.path.basename(key)
    path = os.path.dirname(key)
    eTag = event['Records'][0]['s3']['object']['eTag']
    client = boto3.client('s3')
    response_s3 = client.get_object_tagging(Bucket=bucket, Key=key)
    properties_s3 = response_s3['TagSet']
    length_s3 = len(properties_s3)
    property_md5sum = ""
    for index in range(0, length_s3):
        if properties_s3[index]['Key'] == "md5sum":
            property_md5sum = properties_s3[index]['Value']
    
    if "-" not in eTag:
        md5 = eTag.split("-")[0]
        print("Single-part upload, using eTag for md5sum")
    elif property_md5sum != "":
        md5 = property_md5sum
    else:
        print("Mulit-part uploaded file with no md5sum added as AWS property, cannot symlink... cancelling")
        quit()
    
    
    try:
        login_and_get_secret.login(token)
        
        params = {
            "project": project,
            "name": name,
            "drive": drive,
            "md5sum": md5,
            "symlinkPath": {
                "container": region + ":" + bucket,
                "object": key
            }}
        output = dxpy.api.file_new(input_params=params, always_retry=True)
        fileid = json.loads(json.dumps(output))['id']
        print("File " + name + " symlinked: " + fileid)
        
        dxpy.api.file_add_tags(object_id=fileid, input_params={"project": project, "tags": ["symlink"]}, always_retry=True)
        print("DNAnexus tag 'symlink' added")

        dxpy.api.project_new_folder(object_id=project, input_params={"folder": out + "/" + path, "parents": True}, always_retry=True)

        dxpy.api.project_move(object_id=project, input_params={"objects": [fileid], "destination": out + "/" + path}, always_retry=True)
        print("Symlinked file moved to DNAnexus folder: " + out + "/" + path)
    
        for index in range(0, length_s3):
            if properties_s3[index]['Key'] != "md5sum":
                dxpy.api.file_set_properties(object_id=fileid, input_params={"project": project, "properties": {properties_s3[index]['Key']:properties_s3[index]['Value']}} , always_retry=True)
                print("AWS tag written to DNAnexus property: " + properties_s3[index]['Key'] + ":" + properties_s3[index]['Value'])
    
    except Exception as e:
        print(e)
        raise e
    
    print('SUCCESS')

if __name__ == '__main__':
    lambda_handler()
